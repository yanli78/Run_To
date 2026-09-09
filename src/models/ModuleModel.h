#ifndef MODULEMODEL_H
#define MODULEMODEL_H

#include <QAbstractListModel>
#include <QList>

struct ModuleItem
{
    QString name;
    QString path;
    QString color;
    QString character;
};

class ModuleModel : public QAbstractListModel
{
    Q_OBJECT

public:
    enum ModuleRoles
    {
        NameRole = Qt::UserRole + 1,
        PathRole,
        ColorRole,
        CharacterRole
    };

    explicit ModuleModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    // 数据加载与持久化
    Q_INVOKABLE void loadDataFromSource();
    Q_INVOKABLE void addModule(const QString &name, const QString &path, const QString &color, const QString &character);

    // 【新增】修改指定索引的 4 个角色属性
    Q_INVOKABLE bool updateModule(int index, const QString &name, const QString &path, const QString &color, const QString &character);

    // 【新增】删除指定索引的项（配套 Main.qml 中的 onDeleted）
    Q_INVOKABLE bool removeModule(int index);

private:
    QList<ModuleItem> m_items;
    bool saveToFile(); // 统一写入 config.json
};

#endif // MODULEMODEL_H