#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include <QQmlContext>
#include <cstdio>
#include "ModuleModel.h"
#include "SoftwareScanner.h"
#include "AppIconProvider.h"
#include "MqttHandler.h"

// 解决 Windows 中文环境下调试输出乱码：
// VS Code cpptools 调试器通过 GDB MI 协议捕获程序输出，MI 流按 UTF-8 解码，
// 因此这里统一把消息转成 UTF-8 字节再输出（Qt Creator/终端同样兼容 UTF-8）。
static void messageHandler(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    QByteArray utf8Msg = msg.toUtf8();
    const char *file = context.file ? context.file : "";
    const char *function = context.function ? context.function : "";
    switch (type) {
    case QtDebugMsg:
    case QtInfoMsg:
        fprintf(stderr, "%s\n", utf8Msg.constData());
        break;
    case QtWarningMsg:
        fprintf(stderr, "[Warning] %s (%s:%u)\n", utf8Msg.constData(), file, context.line);
        break;
    case QtCriticalMsg:
        fprintf(stderr, "[Critical] %s (%s:%u, %s)\n",
                utf8Msg.constData(), file, context.line, function);
        break;
    case QtFatalMsg:
        fprintf(stderr, "[Fatal] %s (%s:%u, %s)\n",
                utf8Msg.constData(), file, context.line, function);
        fflush(stderr);
        abort();
    }
    fflush(stderr);
}

int main(int argc, char *argv[])
{
    // 必须在任何 qDebug/console.log 输出之前安装
    qInstallMessageHandler(messageHandler);

    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    ModuleModel myModel;
    myModel.loadDataFromSource();
    engine.rootContext()->setContextProperty("moduleModel", &myModel);

    SoftwareScanner scannerpath;
    engine.rootContext()->setContextProperty("softwareScanner", &scannerpath);

    AppIconProvider scannerico;
    engine.rootContext()->setContextProperty("appIconProvider", &scannerico);

    // 全局唯一的 MQTT 客户端，QML 中通过 mqttHandler 访问
    MqttHandler mqttHandler;
    engine.rootContext()->setContextProperty("mqttHandler", &mqttHandler);

    engine.addImageProvider("appicon", new AppIconProvider);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []()
        { QCoreApplication::exit(-1); },
        Qt::QueuedConnection);
    engine.loadFromModule("Run_To", "Main");

    return app.exec();
}
