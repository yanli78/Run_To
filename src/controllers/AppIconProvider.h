#ifndef APPICONPROVIDER_H
#define APPICONPROVIDER_H

#include <QQuickImageProvider>

class AppIconProvider : public QQuickImageProvider
{
public:
    AppIconProvider();
    // 核心重写方法：QML 请求图片时会调用此函数
    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;
};

#endif // APPICONPROVIDER_H