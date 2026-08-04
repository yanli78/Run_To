#ifndef SOFTWARESCANNER_H
#define SOFTWARESCANNER_H

#include <QObject>
#include <QVariantList>

class SoftwareScanner : public QObject {
    Q_OBJECT
public:
    explicit SoftwareScanner(QObject *parent = nullptr);

    // 供 QML 调用的方法，返回包含软件名和路径的列表
    Q_INVOKABLE QVariantList scanDefaultApps();
};

#endif // SOFTWARESCANNER_H
