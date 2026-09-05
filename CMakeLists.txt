cmake_minimum_required(VERSION 3.16)

project(Run_To VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Mqtt Widgets)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appRun_To
    src/main.cpp
    src/models/ModuleModel.cpp
    src/controllers/MqttHandler.cpp
    src/controllers/AppIconProvider.cpp
    src/controllers/SoftwareScanner.cpp
    src/controllers/ShareManager.cpp
    src/controllers/AppLauncher.cpp
)

qt_add_qml_module(appRun_To
    URI Run_To
    QML_FILES
        qml/Main.qml
        qml/views/SettingWindow.qml
        qml/views/DetailPopup.qml
        qml/components/ActionCard.qml
        qml/views/SelectAppPage.qml
        qml/views/DetailAppPage.qml

    SOURCES
        src/models/ModuleModel.h    
        src/controllers/MqttHandler.h
        src/controllers/SoftwareScanner.h
        src/controllers/AppIconProvider.h
        src/controllers/ShareManager.h
        src/controllers/AppLauncher.h


)

target_include_directories(appRun_To
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/controllers
        ${CMAKE_CURRENT_SOURCE_DIR}/src/models
)

set_target_properties(appRun_To PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE FALSE
)

target_link_libraries(appRun_To
    PRIVATE
        Qt6::Quick
        Qt6::Mqtt
        Qt6::Widgets
)

include(GNUInstallDirs)
install(TARGETS appRun_To
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
