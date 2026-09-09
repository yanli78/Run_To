// qmllint disable unqualified
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt.labs.platform

import "components"
import "views"

ApplicationWindow {
    id: root
    width: 570
    height: 520
    minimumWidth: 435
    minimumHeight: 400
    visible: true
    title: "快捷控制台"
    color: "#F5F6F8"

    // 1. 增加一个标识，判断是否是彻底退出
    property bool isReallyQuit: false

    // 2. 修改 onClosing 逻辑
    onClosing: function(close) {
        if (root.isReallyQuit) {
            // 如果是彻底退出，放行关闭事件
            close.accepted = true
        } else {
            // 否则仅拦截并隐藏窗口到托盘
            close.accepted = false
            root.hide()
        }
    }


    SystemTrayIcon {
        id: trayIcon
        visible: true
        tooltip: "桌面快捷控制台"
        // 需指定托盘显示的图标文件（支持本地绝对路径或 qrc:/ 资源路径）
        icon.source: Qt.resolvedUrl("../assets/Run.png")

        // 左键单击或双击托盘图标：恢复并激活主窗口
        onActivated: function(reason) {
            if (reason === SystemTrayIcon.Trigger || reason === SystemTrayIcon.DoubleClick) {
                root.show()
                root.raise()
                root.requestActivate()
            }
        }

        // 右键托盘弹出原生菜单
        menu: Menu {
            MenuItem {
                text: "打开主界面"
                onTriggered: {
                    root.show()
                    root.raise()
                    root.requestActivate()
                }
            }

            MenuSeparator {}

            MenuItem {
                text: "彻底退出"
                onTriggered: {
                    root.isReallyQuit = true // 标记为真退出
                    trayIcon.visible = false // 立即隐藏托盘图标
                    Qt.quit() // 触发正常退出
                }
            }
        }
    }

    // 状态标识与选中项索引记录
    property bool mqttConnected: false
    property int currentAppIndex: -1

    header: ToolBar {
        implicitHeight: 52
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
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 12

            // 左侧：界面标题与连接状态指示
            RowLayout {
                spacing: 8

                Label {
                    text: "控制面板"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#111827"
                }

                Rectangle {
                    width: 7
                    height: 7
                    radius: 3.5
                    color: root.mqttConnected ? "#10B981" : "#9CA3AF"
                    Layout.alignment: Qt.AlignVCenter
                }

                Label {
                    text: root.mqttConnected ? "在线" : "未连接"
                    font.pixelSize: 11
                    color: root.mqttConnected ? "#059669" : "#9CA3AF"
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Item { Layout.fillWidth: true }

            // 分享导出按钮
            Button {
                id: shareBtn
                text: "导出配置"
                implicitHeight: 32
                implicitWidth: 84
                font.pixelSize: 12

                contentItem: Text {
                    text: shareBtn.text
                    font: shareBtn.font
                    color: "#374151"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 6
                    border.color: shareBtn.down ? "#9CA3AF" : "#D1D5DB"
                    color: shareBtn.down ? "#E5E7EB" : (shareBtn.hovered ? "#F9FAFB" : "#FFFFFF")
                }

                onClicked: {
                    if (typeof shareManager !== "undefined" && shareManager.exportSharePackage) {
                        shareManager.exportSharePackage()
                    } else {
                        console.warn("[主界面] shareManager 实例未就绪")
                    }
                }
            }

            // 系统设置按钮
            Button {
                id: settingBtn
                text: "设置"
                implicitHeight: 32
                implicitWidth: 64
                font.pixelSize: 12

                contentItem: Text {
                    text: settingBtn.text
                    font: settingBtn.font
                    color: "#374151"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 6
                    border.color: settingBtn.down ? "#9CA3AF" : "#D1D5DB"
                    color: settingBtn.down ? "#E5E7EB" : (settingBtn.hovered ? "#F9FAFB" : "#FFFFFF")
                }

                onClicked: settingWin.show()
            }
        }
    }

    // 主内容展示区
    ScrollView {
        id: scrollView
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ScrollBar.vertical: ScrollBar {
            active: true
            policy: ScrollBar.AsNeeded
        }

        Flow {
            width: scrollView.availableWidth
            topPadding: 20
            bottomPadding: 20
            leftPadding: 20
            rightPadding: 20
            spacing: 16

            // 内置功能卡片
            ActionCard {
                title: "快捷键"
                iconColor: "#8B5CF6"
                onClicked: console.log("点击了快捷键卡片")
            }

            ActionCard {
                title: "远程智能"
                iconColor: "#3B82F6"
                onClicked: console.log("点击了远程智能卡片")
            }

            // 动态注册的软件列表卡片
            Repeater {
                model: typeof moduleModel !== "undefined" ? moduleModel : 0

                delegate: ActionCard {
                    id: cardDelegate

                    // 显式声明注入的属性，消除 unqualified 报错
                    required property int index
                    required property var model

                    title: cardDelegate.model.name || "未命名"
                    iconColor: cardDelegate.model.color || "#6B7280"
                    iconSource: cardDelegate.model.path ? ("image://appicon/" + cardDelegate.model.path) : ""

                    onClicked: {
                        root.currentAppIndex = cardDelegate.index
                        myDetailPopup.editable = true
                        myDetailPopup.titleText = cardDelegate.model.name || "未命名应用"
                        myDetailPopup.contentText = cardDelegate.model.path || ""
                        myDetailPopup.iconColor = cardDelegate.model.color || "#3B82F6"
                        myDetailPopup.characterText = cardDelegate.model.character || (cardDelegate.model.name ? cardDelegate.model.name.charAt(0).toUpperCase() : "A")
                        myDetailPopup.open()
                    }
                }
            }

            // 添加按钮卡片
            // 添加按钮卡片
            ActionCard {
                title: "添加更多"
                iconColor: "#6B7280"
                onClicked: {
                    if (!selectAppLoader.active) {
                        selectAppLoader.active = true
                    } else {
                        const win = selectAppLoader.item as Window
                        if (win) {
                            win.show()
                            win.raise()
                            win.requestActivate()
                        }
                    }
                }
            }
        }
    }

    // 详情与编辑弹窗
    DetailPopup {
        id: myDetailPopup
        anchors.centerIn: parent

        onSaved: function(newName, newPath, newColor, newChar) {
            console.log("[主界面] 保存修改:", root.currentAppIndex, newName, newPath, newColor, newChar)
            if (typeof moduleModel !== "undefined" && moduleModel.updateModule) {
                moduleModel.updateModule(root.currentAppIndex, newName, newPath, newColor, newChar)
            } else {
                console.warn("[主界面] moduleModel 未就绪或未找到 updateModule")
            }
        }

        onDeleted: {
            console.log("[主界面] 删除模块, 索引:", root.currentAppIndex)
            if (typeof moduleModel !== "undefined") {
                if (moduleModel.removeModule) {
                    moduleModel.removeModule(root.currentAppIndex)
                } else if (moduleModel.removeAt) {
                    moduleModel.removeAt(root.currentAppIndex)
                } else {
                    console.warn("[主界面] moduleModel 未提供 removeModule 或 removeAt 接口")
                }
            }
        }

        onLaunched: {
            console.log("[主界面] 启动目标程序:", myDetailPopup.contentText)
            if (typeof moduleModel !== "undefined" && moduleModel.launchApp) {
                moduleModel.launchApp(myDetailPopup.contentText)
            } else {
                Qt.openUrlExternally("file:///" + myDetailPopup.contentText)
            }
        }
    }

    Loader {
        id: selectAppLoader
        active: false
        source: "views/SelectAppPage.qml"

        // 首次激活加载完成后立即展示窗口
        onLoaded: {
            const win = item as Window
            if (win) {
                win.show()
            }
        }
    }

    SettingWindow {
        id: settingWin
    }

    // 监听配置包导出反馈
    Connections {
        target: typeof shareManager !== "undefined" ? shareManager : null
        function onExportFinished(success, message) {
            myDetailPopup.editable = false
            myDetailPopup.characterText = ""
            myDetailPopup.titleText = success ? "导出成功" : "导出失败"
            myDetailPopup.contentText = message || (success ? "配置文件已导出至程序根目录" : "未能完成导出")
            myDetailPopup.open()
        }
    }

    // 监听 MQTT 客户端信号
    Connections {
        target: typeof mqttHandler !== "undefined" ? mqttHandler : null

        function onConnectionSuccess() {
            root.mqttConnected = true
            console.log("[主界面] MQTT 已连接，等待 NFC 指令...")
        }

        function onConnectionError(errorMsg) {
            root.mqttConnected = false
            console.log("[主界面] MQTT 连接断开或失败:", errorMsg)
        }

        function onMessageReceived(topic, value) {
            console.log("[主界面] 收到 NFC 指令 => 主题:", topic, "| 指令:", value)
            myDetailPopup.editable = false
            myDetailPopup.characterText = ""
            myDetailPopup.titleText = "收到 NFC 指令"
            myDetailPopup.contentText = "主题: " + topic + "\n指令: " + value
            myDetailPopup.open()
        }
    }
}