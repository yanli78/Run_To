#include <QGuiApplication>
#include <QQmlApplicationEngine>

#include <QQmlContext>
#include "ModuleModel.h"
#include "SoftwareScanner.h"
#include "AppIconProvider.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    QQmlApplicationEngine engine;

    ModuleModel myModel;
    myModel.loadDataFromSource();
    engine.rootContext()->setContextProperty("moduleModel", &myModel);

    SoftwareScanner scannerpath;
    engine.rootContext()->setContextProperty("softwareScanner", &scannerpath);

    AppIconProvider scannerico;
    engine.rootContext()->setContextProperty("appIconProvider", &scannerico);

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
