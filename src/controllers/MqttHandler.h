#ifndef MQTTHANDLER_H
#define MQTTHANDLER_H

#include <QObject>
#include <QMqttClient>
#include <QSettings>
#include <QtQml/qqmlregistration.h>

class MqttHandler : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    // 暴露配置属性给 QML 用于回显历史值
    Q_PROPERTY(QString host READ host NOTIFY configChanged)
    Q_PROPERTY(quint16 port READ port NOTIFY configChanged)
    Q_PROPERTY(QString user READ user NOTIFY configChanged)
    Q_PROPERTY(QString password READ password NOTIFY configChanged)

public:
    explicit MqttHandler(QObject *parent = nullptr);

    // 属性读取函数
    QString host() const { return m_host; }
    quint16 port() const { return m_port; }
    QString user() const { return m_user; }
    QString password() const { return m_password; }

    Q_INVOKABLE void tryAutoConnect();

    // 供 QML 设置窗口调用：保存到本地并立即发起连接
    Q_INVOKABLE void saveAndConnect(const QString &host, quint16 port,
                                    const QString &user, const QString &password);

    // 供程序启动时静默自动连接（若已有保存的历史配置）
    Q_INVOKABLE void autoConnect();

    // 底层连接与订阅方法
    Q_INVOKABLE void connectToBroker(const QString &host, quint16 port = 1883,
                                     const QString &user = QString(),
                                     const QString &password = QString());
    Q_INVOKABLE void subscribeToTopic(const QString &topic);

signals:
    void connectionSuccess();
    void connectionError(const QString &errorMsg);
    void messageReceived(const QString &topic, const QString &value);
    void configChanged();

private slots:
    void handleMessage(const QByteArray &message, const QMqttTopicName &topic);
    void handleConnected();
    void handleDisconnected();

private:
    void loadSettings();
    void saveSettings(const QString &host, quint16 port, const QString &user, const QString &password);
    void processDeviceData(const QString &topicName, const QByteArray &payload);

    QMqttClient *m_client;

    // 持久化字段缓存
    QString m_host;
    quint16 m_port = 1883;
    QString m_user;
    QString m_password;
};

#endif // MQTTHANDLER_H