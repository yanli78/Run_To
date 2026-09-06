#pragma once

#include <QObject>
#include <QString>

class ConfigLauncher : public QObject
{
    Q_OBJECT
public:
    explicit ConfigLauncher(QObject *parent = nullptr);

    /**
     * @brief 单参数启动：默认读取运行目录下的 config.json
     * 标记为 Q_INVOKABLE 且为 static，C++ 和 QML 均可直接调用
     */
    Q_INVOKABLE static bool launchByCharacter(const QString &character);

    /**
     * @brief 双参数启动（显式重载，去掉了默认参数，彻底消除二义性）
     * @param character      待匹配的标识（如 "R5"）
     * @param customJsonPath 自定义配置文件路径
     */
    static bool launchByCharacter(const QString &character, const QString &customJsonPath);
};