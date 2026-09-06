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

#ifdef Q_OS_WIN
#include <windows.h>
#include <shobjidl.h>
#include <shlguid.h>

// 将 Windows 原生 HICON 转换为带 Alpha 通道的 32 位 QImage
static QImage hIconToQImage(HICON hIcon)
{
    if (!hIcon)
        return QImage();

    ICONINFO iconInfo;
    if (!GetIconInfo(hIcon, &iconInfo))
        return QImage();

    BITMAP bmp;
    GetObject(iconInfo.hbmColor, sizeof(BITMAP), &bmp);

    int width = bmp.bmWidth;
    int height = bmp.bmHeight;

    BITMAPINFO bi = {0};
    bi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bi.bmiHeader.biWidth = width;
    bi.bmiHeader.biHeight = -height;
    bi.bmiHeader.biPlanes = 1;
    bi.bmiHeader.biBitCount = 32;
    bi.bmiHeader.biCompression = BI_RGB;

    QImage image(width, height, QImage::Format_ARGB32_Premultiplied);
    HDC hdc = GetDC(nullptr);
    GetDIBits(hdc, iconInfo.hbmColor, 0, height, image.bits(), &bi, DIB_RGB_COLORS);

    bool hasAlpha = false;
    const QRgb *pixels = reinterpret_cast<const QRgb *>(image.constBits());
    int pixelCount = width * height;
    for (int i = 0; i < pixelCount; ++i)
    {
        if (qAlpha(pixels[i]) != 0)
        {
            hasAlpha = true;
            break;
        }
    }

    if (!hasAlpha && iconInfo.hbmMask)
    {
        QImage mask(width, height, QImage::Format_Mono);
        GetDIBits(hdc, iconInfo.hbmMask, 0, height, mask.bits(), &bi, DIB_RGB_COLORS);
        QRgb *scanLine = reinterpret_cast<QRgb *>(image.bits());
        for (int y = 0; y < height; ++y)
        {
            for (int x = 0; x < width; ++x)
            {
                if (mask.pixelIndex(x, y) != 0)
                {
                    scanLine[y * width + x] = 0;
                }
                else
                {
                    scanLine[y * width + x] |= 0xFF000000;
                }
            }
        }
    }

    ReleaseDC(nullptr, hdc);
    DeleteObject(iconInfo.hbmColor);
    DeleteObject(iconInfo.hbmMask);

    return image;
}

// 从文件（支持 .lnk 解析）直接提取无小箭头的高清图标
static QPixmap extractCleanAppPixmap(const QString &filePath, int targetSize = 256)
{
    QString cleanPath = QDir::toNativeSeparators(filePath);
    QString targetFile = cleanPath;
    int iconIndex = 0;

    CoInitialize(nullptr);

    // 若是快捷方式，解析出实际指向或绑定的图标文件
    if (cleanPath.endsWith(".lnk", Qt::CaseInsensitive))
    {
        IShellLinkW *psl = nullptr;
        if (SUCCEEDED(CoCreateInstance(CLSID_ShellLink, nullptr, CLSCTX_INPROC_SERVER, IID_IShellLinkW, (void **)&psl)))
        {
            IPersistFile *ppf = nullptr;
            if (SUCCEEDED(psl->QueryInterface(IID_IPersistFile, (void **)&ppf)))
            {
                if (SUCCEEDED(ppf->Load(reinterpret_cast<const wchar_t *>(cleanPath.utf16()), STGM_READ)))
                {
                    wchar_t iconPath[MAX_PATH] = {0};
                    int idx = 0;
                    psl->GetIconLocation(iconPath, MAX_PATH, &idx);
                    if (wcslen(iconPath) > 0)
                    {
                        wchar_t expanded[MAX_PATH] = {0};
                        ExpandEnvironmentStringsW(iconPath, expanded, MAX_PATH);
                        targetFile = QString::fromWCharArray(expanded);
                        iconIndex = idx;
                    }
                    else
                    {
                        wchar_t target[MAX_PATH] = {0};
                        WIN32_FIND_DATAW wfd;
                        if (SUCCEEDED(psl->GetPath(target, MAX_PATH, &wfd, SLGP_UNCPRIORITY)))
                        {
                            targetFile = QString::fromWCharArray(target);
                            iconIndex = 0;
                        }
                    }
                }
                ppf->Release();
            }
            psl->Release();
        }
    }

    // 直接提取 PE 裸图标（绝无小箭头，且支持 256x256 高清原图）
    HICON hIcon = nullptr;
    UINT iconId = 0;
    UINT count = PrivateExtractIconsW(
        reinterpret_cast<const wchar_t *>(targetFile.utf16()),
        iconIndex,
        targetSize,
        targetSize,
        &hIcon,
        &iconId,
        1,
        LR_LOADFROMFILE);

    CoUninitialize();

    if (count > 0 && hIcon)
    {
        QImage img = hIconToQImage(hIcon);
        DestroyIcon(hIcon);
        if (!img.isNull())
        {
            return QPixmap::fromImage(img);
        }
    }

    return QPixmap();
}
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

        QPixmap pixmap;

#ifdef Q_OS_WIN
        // 优先使用原生 API 提取无箭头的 256x256 高清原图
        if (fileInfo.exists())
        {
            pixmap = extractCleanAppPixmap(resolvedPath, 256);
        }
#endif

        // 回退兜底：如果不是 Windows 或原生提取失败，再走 QFileIconProvider
        if (pixmap.isNull() && fileInfo.exists())
        {
            QIcon icon = iconProvider.icon(fileInfo);
            if (!icon.isNull())
            {
                pixmap = icon.pixmap(256, 256);
            }
        }

        // 最终兜底：使用颜色填充占位图
        if (pixmap.isNull())
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