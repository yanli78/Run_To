import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Window {
    width: 320 // 稍微加宽一点，让底部按钮不那么拥挤
    height: 200
    title: "设置"
    modality: Qt.ApplicationModal

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        // --- 设置项区域 ---
        // 第一个设置项：MQTT IP 地址
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Label {
                text: "MQTT IP地址:"
            }

            TextField {
                id: mqttIpInput
                Layout.fillWidth: true
                placeholderText: "例如: 192.168.1.100"
                selectByMouse: true
            }
        }

        // 弹性占位符：将设置项向上推，将底部的按钮向下推到底
        Item {
            Layout.fillHeight: true
        }

        // --- 底部按钮区域 ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // 水平弹性占位符：利用它占据左侧空白，从而把后面的按钮挤到右边去
            Item {
                Layout.fillWidth: true
            }

            // 取消按钮
            Button {
                text: "取消"
                onClicked: {
                    // 点击取消时直接关闭窗口
                    close()
                }
            }

            // 保存按钮
            Button {
                text: "保存"
                highlighted: true // 设置为高亮（主题色），突出这是主要操作
                onClicked: {
                    // 这里填写保存数据的逻辑
                    console.log("准备保存的 MQTT IP 是:", mqttIpInput.text)

                    // 保存成功后关闭窗口
                    close()
                }
            }
        }
    }
}
