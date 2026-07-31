import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: root
    width: 640
    height: 480
    visible: true
    title: "主界面"

    // 顶栏布局
    header: ToolBar {
        height: 50

        // 左侧：添加图标 (此处使用 ToolButton 结合文本占位)
        ToolButton {
            id: addButton
            text: "+"
            // 建议：如果你有实际的图标资产，请取消下方注释并替换为真实路径
            // icon.source: "qrc:/icons/add_icon.png"
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            onClicked: {
                console.log("触发：添加操作")
            }
        }

        // 中间：打开新窗口的按钮
        Button {
            id: centerButton
            text: "打开新窗口"
            // 使用 anchors.centerIn 确保按钮在顶栏中绝对居中
            anchors.centerIn: parent
            onClicked: {
                newWindow.show()
            }
        }

        // 右侧：分享按钮
        ToolButton {
            id: shareButton
            text: "分享"
            // 建议：如果有实际的图标资产，请替换为真实路径
            // icon.source: "qrc:/icons/share_icon.png"
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            onClicked: {
                console.log("触发：分享操作")
            }
        }
    }

    // 主窗口内容占位
    Label {
        text: "这里是主窗口内容"
        anchors.centerIn: parent
        color: "gray"
    }

    // 独立的子窗口定义
    Window {
        id: newWindow
        width: 300
        height: 200
        title: "新窗口"

        // 设置为应用模态：打开此窗口时，将阻止用户与主窗口交互
        // 若你需要两个窗口可同时操作，请将此行注释或改为 Qt.NonModal
        modality: Qt.ApplicationModal

        Label {
            text: "这是一个新打开的窗口"
            anchors.centerIn: parent
        }
    }
}
