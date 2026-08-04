import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: detailPage

    // 接收参数
    property string appName: ""
    property string appPath: ""

    // 初始随机生成颜色
    property string randomColor: generateRandomColor()

    // 生成随机 HEX 颜色的辅助函数
    function generateRandomColor() {
        var letters = '0123456789ABCDEF'
        var color = '#'
        for (var i = 0; i < 6; i++) {
            color += letters[Math.floor(Math.random() * 16)]
        }
        return color
    }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent

            ToolButton {
                text: "< 返回"
                onClicked: detailPage.StackView.view.pop()
            }

            Label {
                text: "配置详情"
                Layout.fillWidth: true
                horizontalAlignment: Qt.AlignHCenter
            }

            Item { width: 40 }
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.8
        spacing: 15

        TextField {
            id: nameInput
            Layout.fillWidth: true
            placeholderText: "软件名称"
            text: detailPage.appName
        }

        TextField {
            id: pathInput
            Layout.fillWidth: true
            placeholderText: "软件路径"
            text: detailPage.appPath
            readOnly: true
            color: "#666"
        }

        TextField {
            id: characterInput
            Layout.fillWidth: true
            placeholderText: "代表字符 (如 A, B)"
            maximumLength: 2 // 限制字符长度
        }

        // 颜色输入与预览行
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            TextField {
                id: colorInput
                Layout.fillWidth: true
                placeholderText: "十六进制颜色 (如 #FF0000)"
                text: detailPage.randomColor
            }

            // 颜色预览方块
            Rectangle {
                width: 32
                height: 32
                radius: 4
                color: colorInput.text
                border.color: "#ccc"
            }

            // 重新随机按钮
            Button {
                text: "换一个"
                onClicked: {
                    colorInput.text = detailPage.generateRandomColor()
                }
            }
        }

        Button {
            text: "确定并保存"
            Layout.fillWidth: true
            onClicked: {
                console.log("准备保存:", nameInput.text, pathInput.text, colorInput.text, characterInput.text)

                // 调用 C++ 接口写入 config.json
                // 注意：此处的 moduleModel 必须是你通过 setContextProperty 注册到 QML 的实例名
                // 如果你的注册名不同（如 myModel 或 cppBlockModel），请替换对应的名字
                moduleModel.addModule(nameInput.text, pathInput.text, colorInput.text, characterInput.text)

                // 隐藏当前窗口
                detailPage.Window.window.hide()
            }
        }
    }
}