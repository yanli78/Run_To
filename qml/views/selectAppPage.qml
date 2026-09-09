// qmllint disable unqualified
pragma ComponentBehavior: Bound

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

    flags: Qt.Dialog | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.CustomizeWindowHint

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
                    selectPage.rawAppList = softwareScanner.scanDefaultApps() || []
                }
            }

            Component.onCompleted: selectPage.loadApps()

            Connections {
                target: appWindow
                function onVisibleChanged() {
                    if (appWindow.visible && selectPage.rawAppList.length === 0) {
                        selectPage.loadApps()
                    }
                }
            }

            // 过滤后的应用列表
            readonly property var filteredApps: {
                if (!selectPage.rawAppList || selectPage.rawAppList.length === 0) return []
                if (!selectPage.searchText.trim()) return selectPage.rawAppList
                const kw = selectPage.searchText.trim().toLowerCase()
                return selectPage.rawAppList.filter(function(item) {
                    const nameMatch = item.appName && item.appName.toLowerCase().indexOf(kw) !== -1
                    const pathMatch = item.appPath && item.appPath.toLowerCase().indexOf(kw) !== -1
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
                    const rawUrl = fileDialog.selectedFile.toString()
                    let cleanPath = decodeURIComponent(rawUrl.replace(/^file:\/{2,3}/, ""))

                    if (cleanPath.length >= 3 && cleanPath[0] === '/' && cleanPath[2] === ':') {
                        cleanPath = cleanPath.substring(1)
                    }

                    const normalizedPath = cleanPath.replace(/\\/g, "/")
                    const fullName = normalizedPath.substring(normalizedPath.lastIndexOf("/") + 1)
                    const dotIndex = fullName.lastIndexOf(".")
                    const name = (dotIndex > 0) ? fullName.substring(0, dotIndex) : fullName

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

                        reuseItems: true
                        cacheBuffer: 200

                        ScrollBar.vertical: ScrollBar {
                            id: vbar
                            policy: ScrollBar.AsNeeded
                            width: 6

                            contentItem: Rectangle {
                                implicitWidth: 6
                                radius: 3
                                color: vbar.pressed ? "#4B5563" : (vbar.hovered ? "#9CA3AF" : "#D1D5DB")
                            }
                        }

                        delegate: ItemDelegate {
                            id: appDelegate

                            required property var modelData

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
                                        source: "image://appicon/" + appDelegate.modelData.appPath
                                        sourceSize: Qt.size(28, 28)
                                        width: 28
                                        height: 28
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        asynchronous: true
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 3

                                    Label {
                                        text: appDelegate.modelData.appName || "未知程序"
                                        font.pixelSize: 13
                                        font.bold: true
                                        color: "#111827"
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                    }

                                    Label {
                                        text: appDelegate.modelData.appPath || ""
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
                                                   "appName": appDelegate.modelData.appName,
                                                   "appPath": appDelegate.modelData.appPath
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