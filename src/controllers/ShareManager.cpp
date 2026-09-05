#include "ShareManager.h"

#include <QCoreApplication>
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QFileIconProvider>
#include <QIcon>
#include <QPixmap>
#include <QBuffer>

// 区分 Qt5 与 Qt6 的 QZipWriter 路径
#if QT_VERSION >= QT_VERSION_CHECK(6, 0, 0)
#include <QtCore/private/qzipwriter_p.h>
#else
#include <QtGui/private/qzipwriter_p.h>
#endif

ShareManager::ShareManager(QObject *parent) : QObject(parent) {}

bool ShareManager::exportSharePackage(const QString &outputZipPath)
{
    QString appDir = QCoreApplication::applicationDirPath();
    QString configPath = appDir + "/config.json";

    // 1. 读取 config.json
    QFile configFile(configPath);
    if (!configFile.open(QIODevice::ReadOnly))
    {
        emit exportFinished(false, QString("未找到配置文件：%1").arg(configPath));
        return false;
    }

    QByteArray configBytes = configFile.readAll();
    configFile.close();

    QJsonParseError err;
    QJsonDocument doc = QJsonDocument::fromJson(configBytes, &err);
    if (err.error != QJsonParseError::NoError || !doc.isObject())
    {
        emit exportFinished(false, QString("JSON 解析错误：%1").arg(err.errorString()));
        return false;
    }

    // 2. 准备输出 ZIP 路径
    QString targetZip = outputZipPath;
    if (targetZip.isEmpty())
    {
        targetZip = appDir + "/share_bundle.zip";
    }

    QZipWriter zip(targetZip);
    if (zip.status() != QZipWriter::NoError)
    {
        emit exportFinished(false, QString("创建 ZIP 失败，请检查写入权限：%1").arg(targetZip));
        return false;
    }

    // 3. 将原始 config.json 写入 ZIP 根目录
    zip.addFile("config.json", configBytes);

    // 4. 解析 modules 并提取各子项的图标
    QJsonObject rootObj = doc.object();
    QJsonArray modules = rootObj.value("modules").toArray();
    QFileIconProvider iconProvider;

    for (const QJsonValue &item : modules)
    {
        QJsonObject mod = item.toObject();
        QString character = mod.value("character").toString();
        QString rawPath = mod.value("path").toString();

        if (character.isEmpty())
        {
            continue;
        }

        // 解析目标文件路径（兼容相对路径与绝对路径）
        QString resolvedPath = rawPath;
        QFileInfo fileInfo(resolvedPath);
        if (fileInfo.isRelative())
        {
            resolvedPath = QDir(appDir).filePath(rawPath);
            fileInfo.setFile(resolvedPath);
        }

        // 提取快捷方式或文件的图标
        QIcon icon;
        if (fileInfo.exists())
        {
            icon = iconProvider.icon(fileInfo);
        }

        // 获取高分辨率 Pixmap，不存在则使用兜底背景色渲染占位图
        QPixmap pixmap;
        if (!icon.isNull())
        {
            pixmap = icon.pixmap(256, 256);
        }
        else
        {
            pixmap = QPixmap(256, 256);
            pixmap.fill(QColor(mod.value("color").toString("#215694")));
        }

        // 转成 PNG 数据流并写入 resources/<character>.png
        QByteArray imgBytes;
        QBuffer buffer(&imgBytes);
        buffer.open(QIODevice::WriteOnly);
        pixmap.save(&buffer, "PNG");

        QString zipEntryPath = QString("resources/%1.png").arg(character);
        zip.addFile(zipEntryPath, imgBytes);
    }

    zip.close();
    emit exportFinished(true, QString("打包成功，已生成：%1").arg(targetZip));
    return true;
}