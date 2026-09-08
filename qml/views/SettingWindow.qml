import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    width: 420
    height: 440
    minimumWidth: 400
    minimumHeight: 420
    title: "MQTT 远程配置"
    modality: Qt.ApplicationModal
    color: "#F5F6F8"

    // 移除最大化/最小化按钮，仅保留单 X 关闭
    flags: Qt.Dialog | Qt.WindowTitleHint | Qt.WindowCloseButtonHint | Qt.CustomizeWindowHint

    // 状态管理枚举值
    // 0: 未连接, 1: 连接中, 2: 已连接, 3: 失败
    property int connStatus: 0
    property string statusMessage: "未连接"

    function syncFromHandler() {
        if (typeof mqttHandler !== "undefined") {
            mqttIpInput.text = mqttHandler.host || ""
            mqttUserInput.text = mqttHandler.user || ""
            mqttPwdInput.text = mqttHandler.password || ""
        }
    }

    Component.onCompleted: syncFromHandler()

    onVisibleChanged: {
        if (visible) {
            syncFromHandler()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // 主表单卡片
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: formLayout.implicitHeight + 32
            radius: 10
            color: "#FFFFFF"
            border.color: "#E5E7EB"
            border.width: 1

            ColumnLayout {
                id: formLayout
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                // 服务器地址
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Label {
                        text: "服务器地址 (Broker IP / 域名)"
                        font.pixelSize: 12
                        font.bold: true
                        color: "#374151"
                    }

                    TextField {
                        id: mqttIpInput
                        Layout.fillWidth: true
                        implicitHeight: 38
                        placeholderText: "例如：192.168.1.100"
                        font.pixelSize: 13
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
                    spacing: 6

                    Label {
                        text: "用户名 (User)"
                        font.pixelSize: 12
                        font.bold: true
                        color: "#374151"
                    }

                    TextField {
                        id: mqttUserInput
                        Layout.fillWidth: true
                        implicitHeight: 38
                        placeholderText: "Mosquitto 用户名 (选填)"
                        font.pixelSize: 13
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
                    spacing: 6

                    Label {
                        text: "访问密码 (Password)"
                        font.pixelSize: 12
                        font.bold: true
                        color: "#374151"
                    }

                    TextField {
                        id: mqttPwdInput
                        Layout.fillWidth: true
                        implicitHeight: 38
                        placeholderText: "Mosquitto 访问密码 (选填)"
                        font.pixelSize: 13
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
            }
        }

        // 状态提示状态条卡片
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 40
            radius: 8
            border.width: 1

            // 根据状态切换背景与边框色
            color: root.connStatus === 2 ? "#ECFDF5" :
                                           (root.connStatus === 1 ? "#FFFBEB" :
                                                                    (root.connStatus === 3 ? "#FEF2F2" : "#F3F4F6"))

            border.color: root.connStatus === 2 ? "#A7F3D0" :
                                                  (root.connStatus === 1 ? "#FDE68A" :
                                                                           (root.connStatus === 3 ? "#FECACA" : "#E5E7EB"))

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                // 状态指示圆点
                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: root.connStatus === 2 ? "#10B981" :
                                                   (root.connStatus === 1 ? "#F59E0B" :
                                                                            (root.connStatus === 3 ? "#EF4444" : "#9CA3AF"))
                }

                Label {
                    Layout.fillWidth: true
                    text: root.statusMessage
                    font.pixelSize: 12
                    color: root.connStatus === 2 ? "#065F46" :
                                                   (root.connStatus === 1 ? "#92400E" :
                                                                            (root.connStatus === 3 ? "#991B1B" : "#4B5563"))
                    elide: Text.ElideRight
                }
            }
        }

        Item { Layout.fillHeight: true }

        // 底部操作按钮
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Item { Layout.fillWidth: true }

            Button {
                id: cancelBtn
                text: "取消"
                implicitHeight: 38
                implicitWidth: 80
                font.pixelSize: 13

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
                implicitHeight: 38
                implicitWidth: 104
                font.pixelSize: 13
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
                    var ip = mqttIpInput.text.trim()
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
    }

    // 监听网络响应
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
        interval: 1200
        onTriggered: root.close()
    }
}