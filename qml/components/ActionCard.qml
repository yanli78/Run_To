import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: cardRoot
    width: 120
    height: 120
    radius: 12
    color: "white"

    // 对外暴露需要的属性
    property string title: ""
    property string iconColor: "#4A90E2"
    // 【新增】图标源路径。默认留空
    property string iconSource: ""

    signal clicked() // 自定义点击信号

    // 恢复了你代码中去除的鼠标悬浮边框变色效果（可选）
    border.color: mouseArea.containsMouse ? "#4A90E2" : "#E0E0E0"
    border.width: mouseArea.containsMouse ? 2 : 1
    Behavior on border.color { ColorAnimation { duration: 200 } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 10

        // 图标区域
        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 50
            height: 50
            radius: 25

            // 如果传入了自定义图标，背景可以设为透明；否则使用占位颜色
            color: cardRoot.iconSource === "" ? cardRoot.iconColor : "transparent"

            // 1. 文字占位符：只有在未提供 iconSource 时显示
            Label {
                anchors.centerIn: parent
                text: cardRoot.title.charAt(0)
                color: "white"
                font.pixelSize: 24
                font.bold: true
                visible: cardRoot.iconSource === ""
            }

            // 2. 自定义图片：只有在提供了 iconSource 时显示
            Image {
                anchors.centerIn: parent
                width: 32 // 建议比外层Rectangle稍小一点留出内边距
                height: 32
                source: cardRoot.iconSource
                fillMode: Image.PreserveAspectFit // 类似 Flutter 的 BoxFit.contain
                visible: cardRoot.iconSource !== ""
            }
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: cardRoot.title
            font.pixelSize: 16
            color: "#333333"
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        onClicked: cardRoot.clicked()
    }
}
