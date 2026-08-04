#include "SoftwareScanner.h"
#include <QStandardPaths>
#include <QDir>
#include <QDirIterator>
#include <QFileInfo>
#include <QVariantMap>

SoftwareScanner::SoftwareScanner(QObject *parent) : QObject(parent) {}

QVariantList SoftwareScanner::scanDefaultApps() {
    QVariantList appList;

    // 定义需要扫描的目录：当前用户的桌面、公共桌面和系统应用目录（开始菜单等）
    QStringList searchPaths;
    searchPaths << QStandardPaths::standardLocations(QStandardPaths::ApplicationsLocation)
                << QStandardPaths::writableLocation(QStandardPaths::DesktopLocation);

    QStringList filters;
    filters << "*.lnk" << "*.exe";

    for (const QString &path : searchPaths) {
        QDir dir(path);
        if (!dir.exists()) continue;

        QDirIterator it(path, filters,
                        QDir::Files | QDir::NoDotAndDotDot,
                        QDirIterator::Subdirectories);

        while (it.hasNext())
        {
            it.next();
            QFileInfo fileInfo = it.fileInfo();
            QVariantMap app;
            app["appName"] = fileInfo.baseName();
            app["appPath"] = fileInfo.absoluteFilePath();

            appList.append(app);

        }
    }
    

    return appList;
}