#ifndef MQTTHANDLER_H
#define MQTTHANDLER_H

#include <QObject>
#include <QMqttClient>
#include <QtQml/qqmlregistration.h>

class MqttHandler : public QObject {
    Q_OBJECT
    QML_ELEMENT

public:
    explicit MqttHandler(QObject *parent = nullptr);

    // port 默认 1883（MQTT 标准端口）；user/password 用于 HA Mosquitto 等需要认证的 Broker
    Q_INVOKABLE void connectToBroker(const QString &host, quint16 port = 1883,
                                     const QString &user = QString(),
                                     const QString &password = QString());
    Q_INVOKABLE void subscribeToTopic(const QString &topic);

signals:
    // 连接状态信号，用于让前端知道服务器通没通
    void connectionSuccess();
    void connectionError(const QString &errorMsg);

    // 新增：把解析后的消息抛给 QML 界面
    // topic: 消息主题；value: payload JSON 中 "value" 字段的字符串内容
    void messageReceived(const QString &topic, const QString &value);

private slots:
    void handleMessage(const QByteArray &message, const QMqttTopicName &topic);
    void handleConnected();
    void handleDisconnected();

private:
    QMqttClient *m_client;

    // 纯后台业务逻辑函数（示例）
    void processDeviceData(const QString &topicName, const QByteArray &payload);
};




#endif // MQTTHANDLER_H
