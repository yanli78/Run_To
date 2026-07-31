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

    // 仍然保留这两个方法给前台调用（如需自动连接，也可移出 Q_INVOKABLE）
    Q_INVOKABLE void connectToBroker(const QString &host, quint16 port);
    Q_INVOKABLE void subscribeToTopic(const QString &topic);

signals:
    // 只保留连接状态信号，用于让前端知道服务器通没通
    void connectionSuccess();
    void connectionError(const QString &errorMsg);

private slots:
    void handleMessage(const QByteArray &message, const QMqttTopicName &topic);
    void handleConnected();

private:
    QMqttClient *m_client;

    // 纯后台业务逻辑函数（示例）
    void processDeviceData(const QString &topicName, const QByteArray &payload);
};




#endif // MQTTHANDLER_H
