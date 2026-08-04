// DetailPopup.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    width: 400
    height: 300
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // 对外暴露的属性接口
    property string titleText: ""
    property string contentText: ""

    background: Rectangle {
        color: "white"
        radius: 12
        border.color: "#DDDDDD"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Label {
            text: titleText // 直接使用对外暴露的属性
            font.pixelSize: 22
            font.bold: true
            Layout.alignment: Qt.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#EEEEEE"
        }

        Label {
            text: contentText
            font.pixelSize: 16
            color: "#666666"
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Layout.fillHeight: true
            verticalAlignment: Text.AlignTop
        }

        Button {
            text: "关闭"
            Layout.alignment: Qt.AlignHCenter
            // 注意：这里需要使用 this.close() 或者只写 close() 来关闭弹窗自身
            onClicked: close()
        }
    }
}
