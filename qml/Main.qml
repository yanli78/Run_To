import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"
import "views"

ApplicationWindow {
    id: root
    width: 580
    height: 480
    visible: true
    title: "主界面"

    header: ToolBar {
        height: 50
        RowLayout {
            anchors.fill: parent
            spacing: 4

            Item { Layout.fillWidth: true }

            ToolButton {
                text: "分享"
                onClicked: console.log("触发：分享操作")
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "设置"
                onClicked: settingWin.show()
            }
        }
    }

    Flow {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        ActionCard {
            title: "快捷键"
            iconColor: "#9C27B0"
            onClicked: console.log("点击了全局总控")
        }

        ActionCard {
            title: "远程智能"
            iconColor: "#9C27B0"
            onClicked: console.log("点击了全局总控")
        }

        Repeater {
            // 1. 修正模型名称：与 main.cpp 注册的 "moduleModel" 保持绝对一致
            model: typeof moduleModel !== "undefined" ? moduleModel : 0

            delegate: ActionCard {
                title: model.name

                // 2. 修正颜色字段：改为使用新定义的 role -> "color"
                iconColor: model.color

                onClicked: {
                    myDetailPopup.titleText = model.name

                    // 3. 修正描述字段：detailText 已经被你删除了，此处可以改为显示路径 path
                    myDetailPopup.contentText = model.path

                    myDetailPopup.open()
                }
            }
        }

        ActionCard {
            title: "添加更多"
            onClicked: {
                console.log("打开添加设备页面")
                selectApp.show()
            }
        }
    }

    DetailPopup {
        id: myDetailPopup
        anchors.centerIn: parent
    }
    SelectAppPage {
        id: selectApp
    }

    SettingWindow {
        id: settingWin
    }

    // 监听全局 MQTT 客户端
    Connections {
        target: mqttHandler
        function onConnectionSuccess() {
            console.log("[主界面] MQTT 已连接，等待 NFC 指令...")
        }
        function onConnectionError(errorMsg) {
            console.log("[主界面] MQTT 连接失败:", errorMsg)
        }
        function onMessageReceived(topic, value) {
            // HA 转发来的 NFC 令牌，例如 "K1"、"R2"
            console.log("[主界面] 收到 NFC 指令 => 主题:", topic, "| value:", value)

            // 弹窗反馈，证明消息已到达（后续可在这里按 K/R + 数字执行启动程序等动作）
            myDetailPopup.titleText = "收到 NFC 指令"
            myDetailPopup.contentText = "主题: " + topic + "\n指令: " + value
            myDetailPopup.open()
        }
    }


}
