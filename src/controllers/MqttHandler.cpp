#include "MqttHandler.h"
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonParseError>

MqttHandler::MqttHandler(QObject *parent) : QObject(parent) {
    m_client = new QMqttClient(this);

    connect(m_client, &QMqttClient::connected, this, &MqttHandler::handleConnected);
    connect(m_client, &QMqttClient::disconnected, this, &MqttHandler::handleDisconnected);
    connect(m_client, &QMqttClient::messageReceived, this, &MqttHandler::handleMessage);

    connect(m_client, &QMqttClient::errorChanged, this, [this](QMqttClient::ClientError error) {
        // 将错误码翻译成可读信息，方便在设置窗口里直接定位问题
        QString desc;
        switch (error) {
        case QMqttClient::NoError:
            return; // 无错误不处理
        case QMqttClient::InvalidProtocolVersion:
            desc = "协议版本不支持"; break;
        case QMqttClient::IdRejected:
            desc = "Client ID 被拒绝"; break;
        case QMqttClient::ServerUnavailable:
            desc = "服务器不可用（Broker 拒绝连接）"; break;
        case QMqttClient::BadUsernameOrPassword:
            desc = "用户名或密码错误"; break;
        case QMqttClient::NotAuthorized:
            desc = "未授权（HA Mosquitto 必须填写正确的用户名密码）"; break;
        case QMqttClient::TransportInvalid:
            desc = "传输层连接失败(256)：IP 不通/端口不对/防火墙拦截，请用 Test-NetConnection <IP> -Port 1883 验证"; break;
        case QMqttClient::ProtocolViolation:
            desc = "协议违规"; break;
        case QMqttClient::Mqtt5SpecificError:
            desc = "MQTT5 协议错误"; break;
        default:
            desc = "未知错误"; break;
        }
        qDebug() << "MQTT 发生错误，错误码:" << error << "=>" << desc;
        emit connectionError(desc);
    });
}

void MqttHandler::connectToBroker(const QString &host, quint16 port,
                                  const QString &user, const QString &password) {
    if (m_client->state() == QMqttClient::Connected || m_client->state() == QMqttClient::Connecting) {
        m_client->disconnectFromHost();
    }
    m_client->setHostname(host);
    m_client->setPort(port);
    m_client->setUsername(user);
    m_client->setPassword(password);
    qDebug() << "正在连接 MQTT Broker:" << host << ":" << port
             << (user.isEmpty() ? "(匿名)" : "(用户: " + user + ")");
    m_client->connectToHost();
}

void MqttHandler::subscribeToTopic(const QString &topic) {
    if (m_client->state() == QMqttClient::Connected) {
        m_client->subscribe(QMqttTopicFilter(topic),1);
        qDebug() << "请求订阅主题:" << topic;
    }
}

void MqttHandler::handleConnected() {
    qDebug() << "MQTT 服务器连接成功！";
    emit connectionSuccess();

    // 连接成功后自动订阅 HA 发布 NFC 指令的主题
    // HA 自动化中 mqtt.publish 的 topic 是 home/desktop/nfc_command
    subscribeToTopic("home/desktop/nfc_command");
    // 如需接收该前缀下的所有子主题，可改为 subscribeToTopic("home/desktop/#");
}

void MqttHandler::handleDisconnected() {
    qDebug() << "MQTT 已断开连接";
}

// 核心：接收到消息后的纯后台处理入口
void MqttHandler::handleMessage(const QByteArray &message, const QMqttTopicName &topic) {
    // 打印日志，验证后台确实收到了数据
    qDebug() << "[后台接收] 主题:" << topic.name() << "长度:" << message.size() << "bytes";

    // 将数据转交给后台的具体业务逻辑去处理
    processDeviceData(topic.name(), message);
}

// 具体的后台业务逻辑实现
void MqttHandler::processDeviceData(const QString &topicName, const QByteArray &payload) {
    // 可选：过滤非目标主题。目前先注释掉，方便调试接收到的所有信息
    // if (topicName != "your/target/topic") {
    //     return;
    // }

    QJsonParseError jsonError;
    QJsonDocument doc = QJsonDocument::fromJson(payload, &jsonError);

    // 1. 校验 JSON 格式是否合法
    if (jsonError.error != QJsonParseError::NoError) {
        qDebug() << "[JSON 错误] 解析失败:" << jsonError.errorString()
            << "| 原始数据:" << payload;
        return;
    }

    // 2. 校验是否为 JSON 对象 (例如 {...} 结构)
    if (!doc.isObject()) {
        qDebug() << "[格式错误] 期望 JSON 对象，实际收到非对象格式";
        return;
    }

    QJsonObject jsonObj = doc.object();

    // 3. 校验是否包含目标字段 "value"
    if (!jsonObj.contains("value")) {
        qDebug() << "[字段缺失] JSON 中不包含 'value' 字段 | 原始数据:" << payload;
        return;
    }

    // 4. 提取 "value" 字段并进行调试输出
    QJsonValue valueField = jsonObj.value("value");

    qDebug() << "---------- 接收到 MQTT 消息 ----------";
    qDebug() << "来源主题:" << topicName;

    // 统一转成字符串，通过信号抛给 QML 界面处理
    QString valueStr;

    // 针对设备通信中常见的不同数据类型进行分类输出
    if (valueField.isDouble()) {
        // 注：在 Qt JSON 中，所有数字类型（int, float, double）均被视为 Double
        double val = valueField.toDouble();
        qDebug() << "[提取成功] value (数字类型):" << val;
        valueStr = QString::number(val);

    } else if (valueField.isString()) {
        QString val = valueField.toString();
        qDebug() << "[提取成功] value (字符串类型):" << val;
        valueStr = val;

    } else if (valueField.isBool()) {
        bool val = valueField.toBool();
        qDebug() << "[提取成功] value (布尔类型):" << (val ? "true" : "false");
        valueStr = val ? "true" : "false";

    } else {
        qDebug() << "[提取成功] value (未知或复杂结构)";
        valueStr = QString::fromUtf8(payload);
    }
    qDebug() << "--------------------------------------";

    // 通知 QML 界面：HA 发来的 K/R 指令（如 "K1"、"R2"）会走到这里
    emit messageReceived(topicName, valueStr);
}
