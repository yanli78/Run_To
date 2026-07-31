cmake_minimum_required(VERSION 3.16)

project(Run_To VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Mqtt)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appRun_To
    src/main.cpp
)

qt_add_qml_module(appRun_To
    URI Run_To
    QML_FILES
        qml/Main.qml
    # 修复 1：合并 SOURCES 关键字，不要重复写
    SOURCES
        src/controllers/MqttHandler.h
        src/controllers/MqttHandler.cpp
)

# 修复 2：添加头文件搜索路径，确保构建目录中的自动生成文件能找到头文件
target_include_directories(appRun_To
    PRIVATE
        ${CMAKE_CURRENT_SOURCE_DIR}/src/controllers
)

# Qt for iOS sets MACOSX_BUNDLE_GUI_IDENTIFIER automatically since Qt 6.1.
set_target_properties(appRun_To PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(appRun_To
    PRIVATE
        Qt6::Quick
        Qt6::Mqtt
)

include(GNUInstallDirs)
install(TARGETS appRun_To
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
