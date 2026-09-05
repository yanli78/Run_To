#pragma once

#include <QObject>
#include <QString>
#include <QStringList>

class AppLauncher : public QObject
{
    Q_OBJECT
public:
    explicit AppLauncher(QObject *parent = nullptr);

    /**
     * @brief 静态调用接口：启动指定路径的应用程序
     * @param targetPath 软件绝对路径/快捷方式路径（支持 .exe, .lnk 等）
     * @param arguments  启动参数（可选）
     * @param workingDir 工作目录（可选，留空则默认使用可执行文件所在目录）
     * @return 启动是否成功发起
     */
    static bool launch(const QString &targetPath,
                       const QStringList &arguments = QStringList(),
                       const QString &workingDir = QString());

    /**
     * @brief 暴露给 QML 的调用方法
     */
    Q_INVOKABLE bool launchApp(const QString &targetPath,
                               const QStringList &arguments = QStringList())
    {
        return launch(targetPath, arguments);
    }
};