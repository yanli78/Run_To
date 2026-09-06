#include "ConfigLauncher.h"
#include "AppLauncher.h"

#include <QCoreApplication>
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

ConfigLauncher::ConfigLauncher(QObject *parent) : QObject(parent) {}

// 单参数版本：传入空路径走默认逻辑
bool ConfigLauncher::launchByCharacter(const QString &character)
{
    return launchByCharacter(character, QString());
}

// 实际的执行逻辑
bool ConfigLauncher::launchByCharacter(const QString &character, const QString &customJsonPath)
{
    QString targetChar = character.trimmed();
    if (targetChar.isEmpty())
    {
        qWarning() << "[ConfigLauncher] 匹配失败：传入的 character 为空";
        return false;
    }

    // 1. 确定 config.json 路径
    QString jsonPath = customJsonPath;
    if (jsonPath.isEmpty())
    {
        jsonPath = QDir(QCoreApplication::applicationDirPath()).filePath("config.json");
    }

    QFile file(jsonPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        qWarning() << "[ConfigLauncher] 打开配置文件失败 ->" << jsonPath;
        return false;
    }

    // 2. 解析 JSON
    QJsonParseError parseError;
    QJsonDocument doc = QJsonDocument::fromJson(file.readAll(), &parseError);
    file.close();

    if (parseError.error != QJsonParseError::NoError || !doc.isObject())
    {
        qWarning() << "[ConfigLauncher] JSON 格式解析失败：" << parseError.errorString();
        return false;
    }

    QJsonObject rootObj = doc.object();
    if (!rootObj.contains("modules") || !rootObj["modules"].isArray())
    {
        qWarning() << "[ConfigLauncher] JSON 缺少 'modules' 数组字段";
        return false;
    }

    QJsonArray modules = rootObj["modules"].toArray();
    bool found = false;
    QString targetPath;
    QString moduleName;

    // 3. 匹配 character
    for (const QJsonValue &val : modules)
    {
        if (!val.isObject())
            continue;
        QJsonObject modObj = val.toObject();

        if (modObj.value("character").toString() == targetChar)
        {
            targetPath = modObj.value("path").toString();
            moduleName = modObj.value("name").toString();
            found = true;
            break;
        }
    }

    if (!found)
    {
        qWarning() << "[ConfigLauncher] 未在 modules 中找到 character 为" << targetChar << "的配置项";
        return false;
    }

    if (targetPath.trimmed().isEmpty())
    {
        qWarning() << "[ConfigLauncher] 找到目标项" << moduleName << "，但 path 字段为空";
        return false;
    }

    // 4. 处理相对路径
    QFileInfo pathInfo(targetPath);
    QString finalPath = targetPath;
    if (pathInfo.isRelative())
    {
        finalPath = QDir(QCoreApplication::applicationDirPath()).filePath(targetPath);
    }

    qInfo() << QString("[ConfigLauncher] 匹配到 [%1 (%2)]，准备拉起: %3")
                   .arg(moduleName, targetChar, finalPath);

    // 5. 调用 AppLauncher 启动
    return AppLauncher::launch(finalPath);
}