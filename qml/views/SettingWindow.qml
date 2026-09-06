import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    width: 380
    height: 360
    title: "设置"
    modality: Qt.ApplicationModal

    // 同步 C++ 缓存的持久化配置到输入框
    function syncFromHandler() {
        mqttIpInput.text = mqttHandler.host
        mqttUserInput.text = mqttHandler.user
        mqttPwdInput.text = mqttHandler.password
    }

    // 首次加载完成时回显配置
    Component.onCompleted: syncFromHandler()

    // 每次窗口重新显示时重置状态并拉取最新存盘数据
    onVisibleChanged: {
        if (visible) {
            syncFromHandler()
            statusLabel.text = "未连接"
            statusLabel.color = "#999999"
        }
    }

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

        // MQTT 用户名
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
                onAccepted: saveBtn.clicked()
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

        // 弹性占位符
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
                onClicked: root.close()
            }

            Button {
                id: saveBtn
                text: "保存并连接"
                highlighted: true
                onClicked: {
                    var ip = mqttIpInput.text.trim()
                    if (ip === "") {
                        statusLabel.text = "请先输入 MQTT 服务器 IP"
                        statusLabel.color = "#E53935"
                        return
                    }

                    statusLabel.text = "正在连接 " + ip + ":1883 ..."
                    statusLabel.color = "#FB8C00"

                    // 执行保存并触发网络连接
                    mqttHandler.saveAndConnect(ip, 1883,
                                               mqttUserInput.text.trim(),
                                               mqttPwdInput.text)
                }
            }
        }
    }

    // 监听全局连接状态信号
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