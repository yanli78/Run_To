#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQuickStyle>
#include <QQmlContext>
#include <cstdio>
#include <windows.h>

#include "ModuleModel.h"
#include "SoftwareScanner.h"
#include "AppIconProvider.h"
#include "MqttHandler.h"
#include "ShareManager.h"

static void messageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    QByteArray utf8Msg = msg.toUtf8();
    const char *file = context.file ? context.file : "";
    const char *function = context.function ? context.function : "";
    switch (type)
    {
    case QtDebugMsg:
    case QtInfoMsg:
        fprintf(stderr, "%s\n", utf8Msg.constData());
        break;
    case QtWarningMsg:
        fprintf(stderr, "[Warning] %s (%s:%u)\n", utf8Msg.constData(), file, context.line);
        break;
    case QtCriticalMsg:
        fprintf(stderr, "[Critical] %s (%s:%u, %s)\n", utf8Msg.constData(), file, context.line, function);
        break;
    case QtFatalMsg:
        fprintf(stderr, "[Fatal] %s (%s:%u, %s)\n", utf8Msg.constData(), file, context.line, function);
        fflush(stderr);
        abort();
    }
    fflush(stderr);
}

int main(int argc, char *argv[])
{
    SetConsoleOutputCP(CP_UTF8);
    SetConsoleCP(CP_UTF8);

    qInstallMessageHandler(messageHandler);

    QGuiApplication app(argc, argv);
    
    app.setQuitOnLastWindowClosed(false);

    // 启用纯 GPU 绘制且支持高度定制的基础控件样式
    QQuickStyle::setStyle("Basic");

    app.setOrganizationName("MyHomeAutomation");
    app.setApplicationName("DesktopMqttLauncher");

    QQmlApplicationEngine engine;

    // 1. 数据模型
    ModuleModel myModel;
    myModel.loadDataFromSource();
    engine.rootContext()->setContextProperty("moduleModel", &myModel);

    // 2. 控制器与服务
    SoftwareScanner scannerpath;
    engine.rootContext()->setContextProperty("softwareScanner", &scannerpath);

    ShareManager shareManager;
    engine.rootContext()->setContextProperty("shareManager", &shareManager);

    MqttHandler mqttHandler;
    engine.rootContext()->setContextProperty("mqttHandler", &mqttHandler);

    // 3. 图标 Provider 注册
    engine.addImageProvider("appicon", new AppIconProvider());

    // 4. 加载界面
    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []()
        { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);

    engine.loadFromModule("Run_To", "Main");

    // 5. 触发 MQTT 自连（此时 QML Connections 已完成绑定，可正常接收信号）
    mqttHandler.tryAutoConnect();

    return app.exec();
}