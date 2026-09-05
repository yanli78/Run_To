#pragma once

#include <QObject>
#include <QString>

class ShareManager : public QObject
{
    Q_OBJECT
public:
    explicit ShareManager(QObject *parent = nullptr);

    // 暴露给 QML 调用的打包接口
    Q_INVOKABLE bool exportSharePackage(const QString &outputZipPath = QString());

signals:
    void exportFinished(bool success, const QString &message);
};