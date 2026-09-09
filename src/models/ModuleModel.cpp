#include "ModuleModel.h"
#include <QDebug>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

ModuleModel::ModuleModel(QObject *parent) : QAbstractListModel(parent)
{
}

int ModuleModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_items.count();
}

QVariant ModuleModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_items.count())
        return QVariant();

    const ModuleItem &item = m_items[index.row()];

    switch (role)
    {
    case NameRole:
        return item.name;
    case PathRole:
        return item.path;
    case ColorRole:
        return item.color;
    case CharacterRole:
        return item.character;
    }
    return QVariant();
}

QHash<int, QByteArray> ModuleModel::roleNames() const
{
    QHash<int, QByteArray> roles;
    roles[NameRole] = "name";
    roles[PathRole] = "path";
    roles[ColorRole] = "color";
    roles[CharacterRole] = "character";
    return roles;
}

void ModuleModel::loadDataFromSource()
{
    QString configPath = "config.json";
    QFile file(configPath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        qWarning() << "无法打开配置文件，请检查路径及权限:" << configPath;
        return;
    }

    QByteArray jsonData = file.readAll();
    file.close();

    QJsonParseError parseError;
    QJsonDocument jsonDoc = QJsonDocument::fromJson(jsonData, &parseError);
    if (parseError.error != QJsonParseError::NoError || !jsonDoc.isObject())
    {
        qWarning() << "JSON 解析失败或格式不正确";
        return;
    }

    QJsonObject rootObj = jsonDoc.object();
    if (!rootObj.contains("modules") || !rootObj["modules"].isArray())
    {
        qWarning() << "JSON 中未找到有效的 'modules' 数组节点";
        return;
    }

    QJsonArray modulesArray = rootObj["modules"].toArray();

    beginResetModel();
    m_items.clear();

    for (int i = 0; i < modulesArray.size(); ++i)
    {
        QJsonObject itemObj = modulesArray[i].toObject();
        QString name = itemObj.value("name").toString("未命名");
        QString path = itemObj.value("path").toString("");
        QString color = itemObj.value("color").toString("#FFFFFF");
        QString character = itemObj.value("character").toString("-");

        m_items.append({name, path, color, character});
    }
    endResetModel();

    qDebug() << "本地配置加载完成，共读取" << m_items.count() << "个模块";
}

// 统一保存内存中的 m_items 到 config.json
bool ModuleModel::saveToFile()
{
    QString configPath = "config.json";
    QFile file(configPath);
    QJsonObject rootObj;

    // 若原文件存在，读取保留可能存在的其他配置项（如 version）
    if (file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
        if (doc.isObject())
        {
            rootObj = doc.object();
        }
        file.close();
    }

    QJsonArray modulesArray;
    for (const auto &item : m_items)
    {
        QJsonObject obj;
        obj["name"] = item.name;
        obj["path"] = item.path;
        obj["color"] = item.color;
        obj["character"] = item.character;
        modulesArray.append(obj);
    }

    rootObj["version"] = "1.1";
    rootObj["modules"] = modulesArray;

    if (!file.open(QIODevice::WriteOnly | QIODevice::Text))
    {
        qWarning() << "无法打开文件以写入:" << configPath;
        return false;
    }

    file.write(QJsonDocument(rootObj).toJson());
    file.close();
    return true;
}

// 【核心修改接口】更新指定项并通知 QML
bool ModuleModel::updateModule(int index, const QString &name, const QString &path, const QString &color, const QString &character)
{
    if (index < 0 || index >= m_items.count())
    {
        qWarning() << "[ModuleModel] 修改失败：索引越界" << index;
        return false;
    }

    // 1. 更新内存数据
    m_items[index] = {name, path, color, character};

    // 2. 发射 dataChanged 信号，精确刷新 4 个 Role
    QModelIndex modelIdx = createIndex(index, 0);
    emit dataChanged(modelIdx, modelIdx, {NameRole, PathRole, ColorRole, CharacterRole});

    // 3. 持久化到 JSON 文件
    bool ok = saveToFile();
    if (ok)
    {
        qDebug() << "[ModuleModel] 模块更新成功并写入文件，索引:" << index;
    }
    return ok;
}

// 【新增删除接口】
bool ModuleModel::removeModule(int index)
{
    if (index < 0 || index >= m_items.count())
    {
        qWarning() << "[ModuleModel] 删除失败：索引越界" << index;
        return false;
    }

    beginRemoveRows(QModelIndex(), index, index);
    m_items.removeAt(index);
    endRemoveRows();

    return saveToFile();
}

void ModuleModel::addModule(const QString &name, const QString &path, const QString &color, const QString &character)
{
    beginInsertRows(QModelIndex(), m_items.count(), m_items.count());
    m_items.append({name, path, color, character});
    endInsertRows();

    saveToFile();
}