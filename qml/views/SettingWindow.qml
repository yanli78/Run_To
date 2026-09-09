// qmllint disable unqualified
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    width: 440
    height: 520
    minimumWidth: 420
    minimumHeight: 480
    title: "设置"
    modality: Qt.ApplicationModal
    color: "#F5F6F8"

    flags: Qt.Dialog | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.CustomizeWindowHint

    // 状态管理枚举值
    // 0: 未连接, 1: 连接中, 2: 已连接, 3: 失败
    property int connStatus: 0
    property string statusMessage: "未连接"
    property bool autoStart: false

    // 同步 C++ 配置数据
    function syncFromHandler() {
        if (typeof mqttHandler !== "undefined") {
            mqttIpInput.text = mqttHandler.host || ""
            mqttUserInput.text = mqttHandler.user || ""
            mqttPwdInput.text = mqttHandler.password || ""
        }

        // 读取开机自启状态（优先从 settingManager 或 mqttHandler 读取）
        if (typeof settingManager !== "undefined" && typeof settingManager.autoStart !== "undefined") {
            root.autoStart = settingManager.autoStart
        } else if (typeof mqttHandler !== "undefined" && typeof mqttHandler.autoStart !== "undefined") {
            root.autoStart = mqttHandler.autoStart
        }
    }

    Component.onCompleted: syncFromHandler()

    onVisibleChanged: {
        if (visible) {
            syncFromHandler()
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.width - 40
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 16

            Item { height: 4 } // 顶部留白

            // --- 卡片 1：通用偏好设置 ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: generalLayout.implicitHeight + 28
                radius: 10
                color: "#FFFFFF"
                border.color: "#E5E7EB"
                border.width: 1

                ColumnLayout {
                    id: generalLayout
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    Label {
                        text: "常规设置"
                        font.pixelSize: 13
                        font.bold: true
                        color: "#111827"
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#F3F4F6"
                    }

                    // 开机自启动行
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: "开机自启动"
                                font.pixelSize: 13
                                font.bold: true
                                color: "#374151"
                            }

                            Label {
                                text: "计算机启动后自动在后台运行本程序"
                                font.pixelSize: 11
                                color: "#6B7280"
                            }
                        }

                        Switch {
                            id: autoStartSwitch
                            checked: root.autoStart
                            Layout.alignment: Qt.AlignVCenter

                            // 自定义扁平化 Switch 样式
                            indicator: Rectangle {
                                implicitWidth: 38
                                implicitHeight: 22
                                radius: 11
                                color: autoStartSwitch.checked ? "#3B82F6" : "#E5E7EB"
                                Behavior on color { ColorAnimation { duration: 150 } }

                                Rectangle {
                                    x: autoStartSwitch.checked ? parent.width - width - 2 : 2
                                    y: 2
                                    width: 18
                                    height: 18
                                    radius: 9
                                    color: "#FFFFFF"
                                    Behavior on x { NumberAnimation { duration: 150 } }
                                }
                            }

                            onToggled: {
                                root.autoStart = checked
                                // 调用 C++ 写入注册表或开机启动目录
                                if (typeof settingManager !== "undefined" && settingManager.setAutoStart) {
                                    settingManager.setAutoStart(checked)
                                } else if (typeof mqttHandler !== "undefined" && mqttHandler.setAutoStart) {
                                    mqttHandler.setAutoStart(checked)
                                } else {
                                    console.log("[设置] 自启动状态更改为:", checked)
                                }
                            }
                        }
                    }
                }
            }

            // --- 卡片 2：MQTT 远程配置卡片 ---
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: mqttLayout.implicitHeight + 28
                radius: 10
                color: "#FFFFFF"
                border.color: "#E5E7EB"
                border.width: 1

                ColumnLayout {
                    id: mqttLayout
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 14

                    // 标题与状态指示标签（将状态直接整合至卡片头部）
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Label {
                            text: "MQTT 远程协同"
                            font.pixelSize: 13
                            font.bold: true
                            color: "#111827"
                        }

                        Item { Layout.fillWidth: true }

                        // 状态徽标（替代原本突兀的全局横幅）
                        Rectangle {
                            implicitWidth: statusRow.implicitWidth + 14
                            implicitHeight: 22
                            radius: 11
                            color: root.connStatus === 2 ? "#ECFDF5" :
                                                           (root.connStatus === 1 ? "#FFFBEB" :
                                                                                    (root.connStatus === 3 ? "#FEF2F2" : "#F3F4F6"))
                            border.color: root.connStatus === 2 ? "#A7F3D0" :
                                                                  (root.connStatus === 1 ? "#FDE68A" :
                                                                                           (root.connStatus === 3 ? "#FECACA" : "#E5E7EB"))

                            RowLayout {
                                id: statusRow
                                anchors.centerIn: parent
                                spacing: 5

                                Rectangle {
                                    width: 6
                                    height: 6
                                    radius: 3
                                    color: root.connStatus === 2 ? "#10B981" :
                                                                   (root.connStatus === 1 ? "#F59E0B" :
                                                                                            (root.connStatus === 3 ? "#EF4444" : "#9CA3AF"))
                                }

                                Label {
                                    text: root.connStatus === 2 ? "已连接" :
                                                                  (root.connStatus === 1 ? "连接中..." :
                                                                                           (root.connStatus === 3 ? "连接失败" : "未连接"))
                                    font.pixelSize: 11
                                    color: root.connStatus === 2 ? "#065F46" :
                                                                   (root.connStatus === 1 ? "#92400E" :
                                                                                            (root.connStatus === 3 ? "#991B1B" : "#6B7280"))
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 1
                        color: "#F3F4F6"
                    }

                    // Broker 地址
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: "服务器地址 (IP / 域名)"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#4B5563"
                        }

                        TextField {
                            id: mqttIpInput
                            Layout.fillWidth: true
                            implicitHeight: 36
                            placeholderText: "例如：192.168.1.100"
                            font.pixelSize: 12
                            selectByMouse: true
                            background: Rectangle {
                                radius: 6
                                border.color: mqttIpInput.activeFocus ? "#3B82F6" : "#D1D5DB"
                                border.width: mqttIpInput.activeFocus ? 1.5 : 1
                                color: "#FFFFFF"
                            }
                            onAccepted: saveBtn.clicked()
                        }
                    }

                    // 用户名
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: "用户名 (User)"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#4B5563"
                        }

                        TextField {
                            id: mqttUserInput
                            Layout.fillWidth: true
                            implicitHeight: 36
                            placeholderText: "Mosquitto 用户名 (选填)"
                            font.pixelSize: 12
                            selectByMouse: true
                            background: Rectangle {
                                radius: 6
                                border.color: mqttUserInput.activeFocus ? "#3B82F6" : "#D1D5DB"
                                border.width: mqttUserInput.activeFocus ? 1.5 : 1
                                color: "#FFFFFF"
                            }
                            onAccepted: saveBtn.clicked()
                        }
                    }

                    // 密码
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: "访问密码 (Password)"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#4B5563"
                        }

                        TextField {
                            id: mqttPwdInput
                            Layout.fillWidth: true
                            implicitHeight: 36
                            placeholderText: "Mosquitto 访问密码 (选填)"
                            font.pixelSize: 12
                            echoMode: TextInput.Password
                            selectByMouse: true
                            background: Rectangle {
                                radius: 6
                                border.color: mqttPwdInput.activeFocus ? "#3B82F6" : "#D1D5DB"
                                border.width: mqttPwdInput.activeFocus ? 1.5 : 1
                                color: "#FFFFFF"
                            }
                            onAccepted: saveBtn.clicked()
                        }
                    }

                    // 详细信息反馈区域（仅在连接中或出错时内嵌展开）
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: errorMsgLabel.implicitHeight + 12
                        radius: 6
                        color: root.connStatus === 3 ? "#FEF2F2" : "#FFFBEB"
                        border.color: root.connStatus === 3 ? "#FCA5A5" : "#FDE68A"
                        visible: root.connStatus === 1 || root.connStatus === 3

                        Label {
                            id: errorMsgLabel
                            anchors.fill: parent
                            anchors.margins: 6
                            text: root.statusMessage
                            font.pixelSize: 11
                            color: root.connStatus === 3 ? "#B91C1C" : "#B45309"
                            wrapMode: Text.WordWrap
                            verticalAlignment: Text.AlignVCenter
                        }
                    }
                }
            }

            Item { height: 2 } // 弹性间距

            // --- 底部操作栏 ---
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item { Layout.fillWidth: true }

                Button {
                    id: cancelBtn
                    text: "取消"
                    implicitHeight: 36
                    implicitWidth: 76
                    font.pixelSize: 12

                    contentItem: Text {
                        text: cancelBtn.text
                        font: cancelBtn.font
                        color: "#374151"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 6
                        border.color: cancelBtn.down ? "#9CA3AF" : "#D1D5DB"
                        color: cancelBtn.down ? "#E5E7EB" : (cancelBtn.hovered ? "#F9FAFB" : "#FFFFFF")
                    }

                    onClicked: root.close()
                }

                Button {
                    id: saveBtn
                    text: "保存并连接"
                    implicitHeight: 36
                    implicitWidth: 96
                    font.pixelSize: 12
                    font.bold: true

                    contentItem: Text {
                        text: saveBtn.text
                        font: saveBtn.font
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 6
                        color: saveBtn.down ? "#1D4ED8" : (saveBtn.hovered ? "#2563EB" : "#3B82F6")
                    }

                    onClicked: {
                        const ip = mqttIpInput.text.trim()
                        if (ip === "") {
                            root.connStatus = 3
                            root.statusMessage = "请先输入 MQTT 服务器 IP"
                            return
                        }

                        root.connStatus = 1
                        root.statusMessage = "正在连接 " + ip + ":1883 ..."

                        if (typeof mqttHandler !== "undefined" && mqttHandler.saveAndConnect) {
                            mqttHandler.saveAndConnect(ip, 1883,
                                                       mqttUserInput.text.trim(),
                                                       mqttPwdInput.text)
                        } else {
                            root.connStatus = 3
                            root.statusMessage = "未找到 mqttHandler 后端实例"
                        }
                    }
                }
            }

            Item { height: 8 } // 底部留白
        }
    }

    Connections {
        target: typeof mqttHandler !== "undefined" ? mqttHandler : null
        function onConnectionSuccess() {
            root.connStatus = 2
            root.statusMessage = "已连接，正在监听 NFC 指令 ✓"
            closeTimer.start()
        }
        function onConnectionError(errorMsg) {
            root.connStatus = 3
            root.statusMessage = "连接失败: " + errorMsg
        }
    }

    Timer {
        id: closeTimer
        interval: 1000
        onTriggered: root.close()
    }
}