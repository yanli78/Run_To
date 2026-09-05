import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    width: 380
    height: 360
    title: "设置"
    modality: Qt.ApplicationModal

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 12

        // MQTT 服务器地址
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                text: "IP地址:"
                Layout.preferredWidth: 70
            }

            TextField {
                id: mqttIpInput
                Layout.fillWidth: true
                placeholderText: "HA 的 IP，如 192.168.1.100"
                selectByMouse: true
                onAccepted: saveBtn.clicked()
            }
        }

        // MQTT 用户名（HA Mosquitto 插件必填）
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                text: "用户名:"
                Layout.preferredWidth: 70
            }

            TextField {
                id: mqttUserInput
                Layout.fillWidth: true
                placeholderText: "HA 用户名（Mosquitto 认证）"
                selectByMouse: true
            }
        }

        // MQTT 密码
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                text: "密码:"
                Layout.preferredWidth: 70
            }

            TextField {
                id: mqttPwdInput
                Layout.fillWidth: true
                placeholderText: "HA 密码"
                echoMode: TextInput.Password
                selectByMouse: true
                onAccepted: saveBtn.clicked()
            }
        }

        // 连接状态提示
        Label {
            id: statusLabel
            Layout.fillWidth: true
            text: "未连接"
            color: "#999999"
            wrapMode: Text.WordWrap
        }

        // 弹性占位符：将底部按钮推到底部
        Item {
            Layout.fillHeight: true
        }

        // --- 底部按钮区域 ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "取消"
                onClicked: close()
            }

            Button {
                id: saveBtn
                text: "保存并连接"
                highlighted: true
                onClicked: {
                    if (mqttIpInput.text === "") {
                        statusLabel.text = "请先输入 MQTT 服务器 IP"
                        statusLabel.color = "#E53935"
                        return
                    }
                    statusLabel.text = "正在连接 " + mqttIpInput.text + ":1883 ..."
                    statusLabel.color = "#FB8C00"
                    // 真正发起 MQTT 连接；连接成功后 C++ 端会自动订阅主题
                    mqttHandler.connectToBroker(mqttIpInput.text, 1883,
                                                mqttUserInput.text.trim(),
                                                mqttPwdInput.text)
                }
            }
        }
    }

    // 监听全局 MQTT 客户端的连接状态
    Connections {
        target: mqttHandler
        function onConnectionSuccess() {
            statusLabel.text = "已连接，正在监听 NFC 指令 ✓"
            statusLabel.color = "#43A047"
            closeTimer.start()
        }
        function onConnectionError(errorMsg) {
            statusLabel.text = "连接失败: " + errorMsg
            statusLabel.color = "#E53935"
        }
    }

    Timer {
        id: closeTimer
        interval: 1500
        onTriggered: root.close()
    }
}
