import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

Window {
    id: appWindow
    width: 520
    height: 640
    minimumWidth: 440
    minimumHeight: 520
    title: "添加新程序"
    visible: false
    color: "#F5F6F8"

    // 控制右上角按钮：只保留关闭按钮，禁用/移除最大化与最小化控件
    flags: Qt.Dialog | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.CustomizeWindowHint

    // 若需要【完全移除右上角所有按钮】（包括关闭按钮），请替换为下面这行：
    // flags: Qt.Window | Qt.WindowTitleHint | Qt.CustomizeWindowHint

    onClosing: stackView.pop(null)

    StackView {
        id: stackView
        anchors.fill: parent

        initialItem: Page {
            id: selectPage

            property var rawAppList: []
            property string searchText: ""

            function loadApps() {
                if (typeof softwareScanner !== "undefined" && softwareScanner.scanDefaultApps) {
                    rawAppList = softwareScanner.scanDefaultApps() || []
                }
            }

            Component.onCompleted: loadApps()

            Connections {
                target: appWindow
                function onVisibleChanged() {
                    if (appWindow.visible && selectPage.rawAppList.length === 0) {
                        selectPage.loadApps()
                    }
                }
            }

            readonly property var filteredApps: {
                if (!rawAppList || rawAppList.length === 0) return []
                if (!searchText.trim()) return rawAppList
                var kw = searchText.trim().toLowerCase()
                return rawAppList.filter(function(item) {
                    var nameMatch = item.appName && item.appName.toLowerCase().indexOf(kw) !== -1
                    var pathMatch = item.appPath && item.appPath.toLowerCase().indexOf(kw) !== -1
                    return nameMatch || pathMatch
                })
            }

            background: Rectangle {
                color: "#F5F6F8"
            }

            header: ToolBar {
                background: Rectangle {
                    color: "#FFFFFF"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: 1
                        color: "#E2E4E8"
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 16

                    Label {
                        text: "第一步：选择程序"
                        font.pixelSize: 15
                        font.bold: true
                        color: "#1E2022"
                    }
                }
            }

            FileDialog {
                id: fileDialog
                title: "选择可执行文件"
                nameFilters: ["可执行程序/快捷方式 (*.exe *.lnk)", "所有文件 (*)"]
                onAccepted: {
                    var rawUrl = selectedFile.toString()
                    var cleanPath = decodeURIComponent(rawUrl.replace(/^file:\/{2,3}/, ""))

                    if (cleanPath.length >= 3 && cleanPath[0] === '/' && cleanPath[2] === ':') {
                        cleanPath = cleanPath.substring(1)
                    }

                    var normalizedPath = cleanPath.replace(/\\/g, "/")
                    var fullName = normalizedPath.substring(normalizedPath.lastIndexOf("/") + 1)
                    var dotIndex = fullName.lastIndexOf(".")
                    var name = (dotIndex > 0) ? fullName.substring(0, dotIndex) : fullName

                    stackView.push("DetailAppPage.qml", {
                                       "appName": name,
                                       "appPath": cleanPath
                                   })
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                // 手动选择卡片
                Rectangle {
                    id: browseCard
                    Layout.fillWidth: true
                    implicitHeight: 64
                    radius: 10
                    color: browseMouseArea.pressed ? "#F3F4F6" : (browseMouseArea.containsMouse ? "#FAFAFA" : "#FFFFFF")
                    border.color: browseMouseArea.containsMouse ? "#3B82F6" : "#E5E7EB"
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        Rectangle {
                            width: 36
                            height: 36
                            radius: 8
                            color: "#EFF6FF"

                            Label {
                                anchors.centerIn: parent
                                text: "📁"
                                font.pixelSize: 16
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: "浏览本地文件"
                                font.pixelSize: 13
                                font.bold: true
                                color: "#1F2937"
                            }
                            Label {
                                text: "手动选择 .exe 或 .lnk 快捷方式"
                                font.pixelSize: 11
                                color: "#6B7280"
                            }
                        }

                        Label {
                            text: "浏览 ›"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#3B82F6"
                        }
                    }

                    MouseArea {
                        id: browseMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: fileDialog.open()
                    }
                }

                // 分割与标题栏
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: "已检测到的软件"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#374151"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#E5E7EB"
                    }
                }

                // 搜索过滤输入框
                TextField {
                    id: searchField
                    Layout.fillWidth: true
                    implicitHeight: 36
                    placeholderText: "搜索已扫描到的软件名称或路径..."
                    font.pixelSize: 12
                    selectByMouse: true
                    onTextChanged: selectPage.searchText = text

                    background: Rectangle {
                        radius: 8
                        border.color: searchField.activeFocus ? "#3B82F6" : "#D1D5DB"
                        border.width: searchField.activeFocus ? 1.5 : 1
                        color: "#FFFFFF"
                    }
                }

                // 软件列表容器卡片
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: 10
                    color: "#FFFFFF"
                    border.color: "#E5E7EB"
                    border.width: 1
                    clip: true

                    ListView {
                        id: appListView
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: selectPage.filteredApps

                        // 自定义现代细条滚动条
                        ScrollBar.vertical: ScrollBar {
                            id: vbar
                            policy: ScrollBar.AsNeeded
                            width: 6
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.right: parent.right
                            anchors.topMargin: 2
                            anchors.bottomMargin: 2

                            contentItem: Rectangle {
                                implicitWidth: 6
                                radius: 3
                                color: vbar.pressed ? "#4B5563" : (vbar.hovered ? "#9CA3AF" : "#D1D5DB")
                            }
                        }

                        delegate: ItemDelegate {
                            id: appDelegate
                            // 动态避让滚动条，滚动条显示时不遮挡右侧箭头
                            width: appListView.width - (vbar.visible ? (vbar.width + 4) : 0)
                            implicitHeight: 56
                            padding: 8

                            background: Rectangle {
                                radius: 6
                                color: appDelegate.down ? "#E5E7EB" : (appDelegate.hovered ? "#F3F4F6" : "transparent")
                            }

                            contentItem: RowLayout {
                                spacing: 12

                                Rectangle {
                                    width: 36
                                    height: 36
                                    radius: 8
                                    color: "#F3F4F6"
                                    border.color: "#E5E7EB"
                                    border.width: 1

                                    Image {
                                        anchors.centerIn: parent
                                        source: "image://appicon/" + modelData.appPath
                                        sourceSize: Qt.size(28, 28)
                                        width: 28
                                        height: 28
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    Label {
                                        text: modelData.appName || "未知程序"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: "#111827"
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        text: modelData.appPath || ""
                                        font.pixelSize: 11
                                        color: "#6B7280"
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }
                                }

                                Label {
                                    text: "›"
                                    font.pixelSize: 16
                                    color: appDelegate.hovered ? "#3B82F6" : "#D1D5DB"
                                    Layout.alignment: Qt.AlignVCenter
                                    Layout.rightMargin: 4
                                }
                            }

                            onClicked: {
                                stackView.push("DetailAppPage.qml", {
                                                   "appName": modelData.appName,
                                                   "appPath": modelData.appPath
                                               })
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            visible: appListView.count === 0
                            text: selectPage.rawAppList.length === 0 ? "未扫描到系统默认程序" : "未找到匹配的程序"
                            font.pixelSize: 12
                            color: "#9CA3AF"
                        }
                    }
                }
            }
        }
    }
}