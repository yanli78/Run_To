#include "AppIconProvider.h"
#include <QFileInfo>
#include <QFileIconProvider>
#include <QIcon>
#include <QPixmap>

AppIconProvider::AppIconProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
}

QImage AppIconProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    QFileInfo fileInfo(id);

    // 如果是快捷方式（.lnk），解析其真实指向的目标文件
    if (fileInfo.isSymLink())
    {
        QString targetPath = fileInfo.symLinkTarget();
        if (!targetPath.isEmpty() && QFileInfo::exists(targetPath))
        {
            fileInfo.setFile(targetPath);
        }
    }

    QFileIconProvider iconProvider;
    QIcon icon = iconProvider.icon(fileInfo);

    if (icon.isNull())
    {
        return QImage();
    }

    QSize actualSize = requestedSize.isValid() ? requestedSize : QSize(32, 32);

    if (size)
    {
        *size = actualSize;
    }

    return icon.pixmap(actualSize).toImage();
}