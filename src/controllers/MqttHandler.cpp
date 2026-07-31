#include "MqttHandler.h"
#include <QDebug>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonValue>
#include <QJsonParseError>

MqttHandler::MqttHandler(QObject *parent) : QObject(parent) {
    m_client = new QMqttClient(this);

    connect(m_client, &QMqttClient::connected, this, &MqttHandler::handleConnected);
    connect(m_client, &QMqttClient::messageReceived, this, &MqttHandler::handleMessage);

    connect(m_client, &QMqttClient::errorChanged, this, [this](QMqttClient::ClientError error) {
        qDebug() << "MQTT 发生错误，错误码:" << error;
        emit connectionError("连接异常，错误码: " + QString::number(error));
    });
}

void MqttHandler::connectToBroker(const QString &host, quint16 port) {
    if (m_client->state() == QMqttClient::Connected) {
        m_client->disconnectFromHost();
    }
    m_client->setHostname(host);
    m_client->setPort(port);
    m_client->connectToHost();
}

void MqttHandler::subscribeToTopic(const QString &topic) {
    if (m_client->state() == QMqttClient::Connected) {
        m_client->subscribe(QMqttTopicFilter(topic));
        qDebug() << "请求订阅主题:" << topic;
    }
}

void MqttHandler::handleConnected() {
    qDebug() << "MQTT 服务器连接成功！";
    emit connectionSuccess();

    // 你也可以选择在这里硬编码自动订阅，不需要前端触发
    // subscribeToTopic("sensor/data/#");
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

    // 针对设备通信中常见的不同数据类型进行分类输出
    if (valueField.isDouble()) {
        // 注：在 Qt JSON 中，所有数字类型（int, float, double）均被视为 Double
        double val = valueField.toDouble();
        qDebug() << "[提取成功] value (数字类型):" << val;

        // TODO: 在此处补充针对数字类型的判断逻辑
        // if (val > 10.0) { ... }

    } else if (valueField.isString()) {
        QString val = valueField.toString();
        qDebug() << "[提取成功] value (字符串类型):" << val;

        // TODO: 在此处补充针对字符串类型的判断逻辑
        // if (val == "ON") { ... }

    } else if (valueField.isBool()) {
        bool val = valueField.toBool();
        qDebug() << "[提取成功] value (布尔类型):" << (val ? "true" : "false");

        // TODO: 在此处补充针对布尔类型的判断逻辑

    } else {
        qDebug() << "[提取成功] value (未知或复杂结构)";
    }
    qDebug() << "--------------------------------------";
}
