#include "AppIconProvider.h"
#include <QFileInfo>
#include <QFileIconProvider>
#include <QIcon>
#include <QUrl>
#include <QDir>
#include <QDebug>

#ifdef Q_OS_WIN
#include <windows.h>
#include <shobjidl.h>
#include <shlguid.h>
#include <shellapi.h>

// 将 Windows 原生 HICON 转换为带透明通道的 QImage
static QImage hIconToQImage(HICON hIcon, const QSize &size)
{
    if (!hIcon)
        return QImage();

    int width = size.width() > 0 ? size.width() : 48;
    int height = size.height() > 0 ? size.height() : 48;

    HDC hdcScreen = GetDC(nullptr);
    HDC hdcMem = CreateCompatibleDC(hdcScreen);

    BITMAPINFO bi = {0};
    bi.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
    bi.bmiHeader.biWidth = width;
    bi.bmiHeader.biHeight = -height; // 负值表示 Top-Down DIB
    bi.bmiHeader.biPlanes = 1;
    bi.bmiHeader.biBitCount = 32;
    bi.bmiHeader.biCompression = BI_RGB;

    void *pBits = nullptr;
    HBITMAP hBitmap = CreateDIBSection(hdcMem, &bi, DIB_RGB_COLORS, &pBits, nullptr, 0);
    if (!hBitmap)
    {
        DeleteDC(hdcMem);
        ReleaseDC(nullptr, hdcScreen);
        DestroyIcon(hIcon);
        return QImage();
    }

    HGDIOBJ hOldBitmap = SelectObject(hdcMem, hBitmap);
    DrawIconEx(hdcMem, 0, 0, hIcon, width, height, 0, nullptr, DI_NORMAL);

    QImage img(reinterpret_cast<const uchar *>(pBits), width, height, QImage::Format_ARGB32_Premultiplied);
    QImage result = img.copy(); // 深拷贝像素数据

    SelectObject(hdcMem, hOldBitmap);
    DeleteObject(hBitmap);
    DeleteDC(hdcMem);
    ReleaseDC(nullptr, hdcScreen);
    DestroyIcon(hIcon);

    return result;
}
#endif

AppIconProvider::AppIconProvider()
    : QQuickImageProvider(QQuickImageProvider::Image)
{
}

QImage AppIconProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    QString cleanPath = QUrl::fromPercentEncoding(id.toUtf8());
    if (cleanPath.startsWith('/') && cleanPath.length() > 2 && cleanPath.at(2) == ':')
    {
        cleanPath.remove(0, 1);
    }
    cleanPath = QDir::toNativeSeparators(cleanPath);

    QFileInfo fileInfo(cleanPath);
    if (!fileInfo.exists())
    {
        return QImage();
    }

    QSize actualSize = requestedSize.isValid() ? requestedSize : QSize(48, 48);
    if (size)
        *size = actualSize;

#ifdef Q_OS_WIN
    if (fileInfo.suffix().compare("lnk", Qt::CaseInsensitive) == 0)
    {
        HRESULT hrCom = CoInitialize(NULL);

        IShellLinkW *pShellLink = nullptr;
        if (SUCCEEDED(CoCreateInstance(CLSID_ShellLink, NULL, CLSCTX_INPROC_SERVER, IID_IShellLinkW, (void **)&pShellLink)))
        {
            IPersistFile *pPersistFile = nullptr;
            if (SUCCEEDED(pShellLink->QueryInterface(IID_IPersistFile, (void **)&pPersistFile)))
            {
                if (SUCCEEDED(pPersistFile->Load(reinterpret_cast<LPCWSTR>(cleanPath.utf16()), STGM_READ)))
                {

                    // 1. 优先提取自定义图标位置（IconLocation）
                    wchar_t szIconPath[MAX_PATH] = {0};
                    int iconIndex = 0;
                    if (SUCCEEDED(pShellLink->GetIconLocation(szIconPath, MAX_PATH, &iconIndex)) && wcslen(szIconPath) > 0)
                    {

                        QString rawPath = QString::fromWCharArray(szIconPath).trimmed();
                        // 去除 Windows 路径外层可能包裹的双引号
                        if (rawPath.startsWith('\"') && rawPath.endsWith('\"') && rawPath.length() >= 2)
                        {
                            rawPath = rawPath.mid(1, rawPath.length() - 2);
                        }

                        wchar_t expandedPath[MAX_PATH] = {0};
                        ExpandEnvironmentStringsW(reinterpret_cast<LPCWSTR>(rawPath.utf16()), expandedPath, MAX_PATH);
                        QString finalIconPath = QString::fromWCharArray(expandedPath);

                        // 相对路径转换为绝对路径
                        QFileInfo iconFi(finalIconPath);
                        if (iconFi.isRelative())
                        {
                            finalIconPath = fileInfo.dir().absoluteFilePath(finalIconPath);
                        }

                        // 使用 Windows 原生 API 提取 ICO/EXE/DLL 中的指定序号图标
                        HICON hCustomIcon = nullptr;
                        UINT count = PrivateExtractIconsW(
                            reinterpret_cast<LPCWSTR>(finalIconPath.utf16()),
                            iconIndex,
                            actualSize.width(),
                            actualSize.height(),
                            &hCustomIcon,
                            nullptr,
                            1,
                            LR_LOADFROMFILE);

                        if (count > 0 && hCustomIcon)
                        {
                            pPersistFile->Release();
                            pShellLink->Release();
                            if (SUCCEEDED(hrCom))
                                CoUninitialize();
                            return hIconToQImage(hCustomIcon, actualSize);
                        }
                    }
                }
                pPersistFile->Release();
            }
            pShellLink->Release();
        }

        // 2. 兜底策略 A：通过 Shell 直接请求快捷方式在系统里呈现的图标
        SHFILEINFOW sfi = {0};
        if (SHGetFileInfoW(reinterpret_cast<LPCWSTR>(cleanPath.utf16()), 0, &sfi, sizeof(sfi), SHGFI_ICON | SHGFI_LARGEICON))
        {
            if (sfi.hIcon)
            {
                if (SUCCEEDED(hrCom))
                    CoUninitialize();
                return hIconToQImage(sfi.hIcon, actualSize);
            }
        }

        if (SUCCEEDED(hrCom))
            CoUninitialize();
    }
#endif

    // 3. 兜底策略 B：常规文件图标提取
    QFileIconProvider iconProvider;
    QIcon fallbackIcon = iconProvider.icon(fileInfo);
    if (!fallbackIcon.isNull())
    {
        return fallbackIcon.pixmap(actualSize).toImage();
    }

    return QImage();
}