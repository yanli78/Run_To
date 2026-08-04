import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs // Qt6 标准对话框
import QtQuick.Layouts

Window {
    id: appWindow
    width: 500
    height: 600
    title: "添加新程序"
    // 默认隐藏，由主界面的 selectApp.show() 触发显示
    visible: false

    // 用于在关闭窗口时重置状态
    onClosing: stackView.pop(null)

    StackView {
        id: stackView
        anchors.fill: parent

        // 初始页面：程序选择列表
        initialItem: Page {
            header: ToolBar {
                Label { text: "第一步：选择程序"; anchors.centerIn: parent }
            }

            // Qt6 原生 FileDialog
            FileDialog {
                id: fileDialog
                title: "选择应用程序"
                nameFilters: ["应用程序/快捷方式 (*.exe *.lnk)"]
                onAccepted: {
                    // Qt6 中使用 selectedFile 获取路径 URL
                    var path = selectedFile.toString().replace("file:///", "");
                    var name = path.substring(path.lastIndexOf("/") + 1);

                    // 将详细页压入栈，替换当前界面，并传递参数
                    stackView.push("DetailAppPage.qml", {"appName": name, "appPath": path})
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                Button {
                    text: "浏览本地文件 (手动选择)..."
                    Layout.fillWidth: true
                    onClicked: fileDialog.open()
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: "#ccc" }
                Label { text: "快速选择 (检测到的程序):" }

                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    model: softwareScanner.scanDefaultApps()

                    delegate: ItemDelegate {
                        width: ListView.view.width
                        padding: 10

                        contentItem: RowLayout {
                            spacing: 15

                            Image {
                                // 核心：使用刚才注册的 appicon 前缀，拼接程序的绝对路径
                                source: "image://appicon/" + modelData.appPath
                                sourceSize: Qt.size(32, 32)
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32
                            }

                            ColumnLayout {
                                spacing: 5
                                Label {
                                    text: modelData.appName
                                    font.pixelSize: 14
                                    font.bold: true
                                }
                                Label {
                                    text: modelData.appPath
                                    font.pixelSize: 11
                                    color: "gray"
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight // 路径太长时显示省略号
                                }
                            }
                        }

                        onClicked: {
                            stackView.push("DetailAppPage.qml", {
                                "appName": modelData.appName,
                                "appPath": modelData.appPath
                            })
                        }
                    }
                }
            }
        }
    }
}
