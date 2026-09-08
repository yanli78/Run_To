import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: cardRoot
    width: 120
    height: 120
    radius: 12
    color: mouseArea.containsMouse ? "#FFFFFF" : "#FAFAFA"

    // 对外属性
    property string title: ""
    property string iconColor: "#3B82F6"
    property string iconSource: ""
    signal clicked()

    // 悬停边框动效
    border.color: mouseArea.containsMouse ? "#3B82F6" : "#E5E7EB"
    border.width: mouseArea.containsMouse ? 1.5 : 1
    Behavior on border.color { ColorAnimation { duration: 150 } }
    Behavior on color { ColorAnimation { duration: 150 } }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 8

        // 图标区域
        Rectangle {
            id: iconContainer
            Layout.alignment: Qt.AlignHCenter
            width: 48
            height: 48
            radius: 24
            color: (cardImg.status === Image.Ready) ? "transparent" : cardRoot.iconColor

            // 占位字符
            Label {
                anchors.centerIn: parent
                text: cardRoot.title ? cardRoot.title.charAt(0).toUpperCase() : "A"
                color: "#FFFFFF"
                font.pixelSize: 22
                font.bold: true
                visible: cardImg.status !== Image.Ready
            }

            // 图标图片
            Image {
                id: cardImg
                anchors.centerIn: parent
                width: 32
                height: 32
                source: cardRoot.iconSource
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                sourceSize: Qt.size(64, 64)
                visible: status === Image.Ready
            }
        }

        // 标题与悬停提示
        Label {
            id: titleLabel
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            text: cardRoot.title
            font.pixelSize: 13
            font.bold: mouseArea.containsMouse
            elide: Text.ElideRight

            // 悬停颜色过渡
            color: mouseArea.containsMouse ? "#2563EB" : "#1F2937"
            Behavior on color { ColorAnimation { duration: 150 } }

            // 优化后的独立 ToolTip
            ToolTip {
                id: cardToolTip
                // 仅在卡片悬停且文字被截断（超出宽度）时才弹出
                visible: mouseArea.containsMouse && titleLabel.truncated
                text: cardRoot.title
                delay: 350
                timeout: 4000

                // 定位在标题正下方居中
                y: titleLabel.height + 4
                x: (titleLabel.width - width) / 2

                contentItem: Text {
                    text: cardToolTip.text
                    font.pixelSize: 11
                    color: "#F9FAFB"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }

                background: Rectangle {
                    radius: 6
                    color: "#1F2937"
                    border.color: "#374151"
                    border.width: 1
                }
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: cardRoot.clicked()
    }
}