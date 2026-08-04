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
    // id 就是从 QML 传过来的 appPath
    QFileInfo fileInfo(id);
    QFileIconProvider iconProvider;
    QIcon icon = iconProvider.icon(fileInfo);

    // 如果获取不到图标，返回一个空的 QImage 防止崩溃
    if (icon.isNull())
    {
        return QImage();
    }

    // 确定 QML 需要的大小（如果没有显式请求，默认给 32x32）
    QSize actualSize = requestedSize.isValid() ? requestedSize : QSize(32, 32);

    if (size)
    {
        *size = actualSize;
    }

    // 提取图标并转换为 QImage 传回 QML
    return icon.pixmap(actualSize).toImage();
}