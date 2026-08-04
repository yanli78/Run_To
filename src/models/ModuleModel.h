#ifndef MODULEMODEL_H
#define MODULEMODEL_H

#include <QAbstractListModel>
#include <QList>

// 定义单个小方块的数据结构
struct ModuleItem
{
    QString name;      // 名字
    QString path;      // 路径
    QString color;     // 颜色
    QString character; // 字符
};

class ModuleModel : public QAbstractListModel
{
    Q_OBJECT

public:
    // 定义 QML 中使用的角色名称 (Role)
    enum ModuleRoles
    {
        NameRole = Qt::UserRole + 1,
        PathRole,
        ColorRole,
        CharacterRole
    };

    explicit ModuleModel(QObject *parent = nullptr);

    // 必须重写的三个虚函数，QML 引擎会调用它们来获取数据
    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // 提供一个给外部调用的方法，用于加载/更新数据
    Q_INVOKABLE void loadDataFromSource();

    // 提供一个给外部调用的方法，用于添加新的方块数据
    Q_INVOKABLE void addModule(const QString &name, const QString &path, const QString &color, const QString &character);

private:
    QList<ModuleItem> m_items; // 存放所有方块数据的列表
};

#endif // MODULEMODEL_H
