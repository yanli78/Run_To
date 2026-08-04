#include "ModuleModel.h"
#include <QDebug>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>

ModuleModel::ModuleModel(QObject *parent) : QAbstractListModel(parent)
{
    // 在构造时可以先不加载，或者加载默认数据
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

    // 根据 QML 请求的 role，返回对应的数据
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
    // 将 C++ 的枚举映射为 QML 中可以直接使用的字符串变量名
    roles[NameRole] = "name";
    roles[PathRole] = "path";
    roles[ColorRole] = "color";
    roles[CharacterRole] = "character";
    return roles;
}

// 模拟读取信息（比如从文件或 MQTT 读取）并生成数据
void ModuleModel::loadDataFromSource()
{
    // 定义配置文件路径。请根据实际存放位置修改。
    // 如果配置文件与可执行文件在同一目录，可使用：
    // QString configPath = QCoreApplication::applicationDirPath() + "/config.json";
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
    if (parseError.error != QJsonParseError::NoError)
    {
        qWarning() << "JSON 解析失败，格式错误:" << parseError.errorString();
        return;
    }

    if (!jsonDoc.isObject())
    {
        qWarning() << "JSON 根节点格式不正确，期望为 Object";
        return;
    }

    QJsonObject rootObj = jsonDoc.object();
    if (!rootObj.contains("modules") || !rootObj["modules"].isArray())
    {
        qWarning() << "JSON 中未找到有效的 'modules' 数组节点";
        return;
    }

    QJsonArray modulesArray = rootObj["modules"].toArray();

    // 开始更新模型数据
    beginResetModel();
    m_items.clear();

    for (int i = 0; i < modulesArray.size(); ++i)
    {
        QJsonObject itemObj = modulesArray[i].toObject();

        // 提取字段。toString 的参数为读取失败或字段不存在时的默认后备值
        QString name = itemObj.value("name").toString("未命名");
        QString path = itemObj.value("path").toString("");
        QString color = itemObj.value("color").toString("#FFFFFF");
        QString character = itemObj.value("character").toString("-");

        m_items.append({name, path, color, character});
    }

    endResetModel();

    qDebug() << "本地配置加载完成，共读取" << m_items.count() << "个模块";
}

void ModuleModel::addModule(const QString &name, const QString &path, const QString &color, const QString &character)
{
    QString configPath = "config.json"; // 必须与 loadDataFromSource 的路径保持完全一致
    QFile file(configPath);

    QJsonObject rootObj;
    QJsonArray modulesArray;

    // 1. 如果文件存在，先读取原有数据
    if (file.open(QIODevice::ReadOnly | QIODevice::Text))
    {
        QByteArray jsonData = file.readAll();
        file.close();

        QJsonDocument doc = QJsonDocument::fromJson(jsonData);
        if (doc.isObject())
        {
            rootObj = doc.object();
            if (rootObj.contains("modules") && rootObj["modules"].isArray())
            {
                modulesArray = rootObj["modules"].toArray();
            }
        }
    }

    // 2. 构造新的模块对象并追加到数组
    QJsonObject newModule;
    newModule["name"] = name;
    newModule["path"] = path;
    newModule["color"] = color;
    newModule["character"] = character;

    modulesArray.append(newModule);

    // 3. 更新根节点数据
    rootObj["version"] = "1.1";
    rootObj["modules"] = modulesArray;

    // 4. 将更新后的数据写回 JSON 文件
    if (file.open(QIODevice::WriteOnly | QIODevice::Text))
    {
        QJsonDocument newDoc(rootObj);
        file.write(newDoc.toJson());
        file.close();
        qDebug() << "数据追加成功，已保存至:" << configPath;

        // 5. 重新加载数据，自动触发界面刷新
        loadDataFromSource();
    }
    else
    {
        qWarning() << "无法打开文件以写入:" << configPath;
    }
}
