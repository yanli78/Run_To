// DetailPopup.qml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Popup {
    id: popup
    width: 440
    implicitHeight: mainLayout.implicitHeight + 40
    modal: true
    focus: true
    anchors.centerIn: Overlay.overlay
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    // 对外数据接口
    property string titleText: ""
    property string contentText: ""
    property string iconColor: "#3B82F6"
    property string characterText: ""

    // 功能控制接口
    property bool editable: false // 是否启用编辑/操作扩展模式（通知类弹窗设为 false，应用卡片设为 true）
    property bool isEditing: false // 当前是否正处于编辑状态

    // 动作信号：供外部（如 Main.qml）监听处理
    signal saved(string newTitle, string newContent)
    signal deleted()
    signal launched()

    // 弹窗打开或关闭时重置编辑状态
    onAboutToShow: {
        isEditing = false
        editNameField.text = titleText
        editPathField.text = contentText
    }

    // 模态背景遮罩（深色半透明平滑暗化）
    Overlay.modal: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.45)
    }

    background: Rectangle {
        radius: 12
        color: "#FFFFFF"
        border.color: "#E5E7EB"
        border.width: 1
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // --- 1. 顶部标题栏与关闭按钮 ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Label {
                text: popup.isEditing ? "编辑配置" : (popup.titleText || "详情")
                font.pixelSize: 16
                font.bold: true
                color: "#111827"
                Layout.fillWidth: true
                elide: Text.ElideRight
            }

            // 右上角平滑关闭小图标
            Rectangle {
                width: 26
                height: 26
                radius: 13
                color: closeMouse.containsMouse ? "#F3F4F6" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    font.pixelSize: 12
                    color: "#9CA3AF"
                }

                MouseArea {
                    id: closeMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: popup.close()
                }
            }
        }

        // 分割线
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#F3F4F6"
        }

        // --- 2. 内容展示与编辑交互区 ---

        // 场景 A：编辑模式表单输入
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: popup.editable && popup.isEditing

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "程序名称"
                    font.pixelSize: 12
                    font.bold: true
                    color: "#4B5563"
                }

                TextField {
                    id: editNameField
                    Layout.fillWidth: true
                    implicitHeight: 38
                    text: popup.titleText
                    placeholderText: "输入程序名称"
                    font.pixelSize: 13
                    selectByMouse: true
                    background: Rectangle {
                        radius: 6
                        border.color: editNameField.activeFocus ? "#3B82F6" : "#D1D5DB"
                        border.width: editNameField.activeFocus ? 1.5 : 1
                        color: "#FFFFFF"
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "执行路径"
                    font.pixelSize: 12
                    font.bold: true
                    color: "#4B5563"
                }

                TextField {
                    id: editPathField
                    Layout.fillWidth: true
                    implicitHeight: 38
                    text: popup.contentText
                    placeholderText: "输入可执行文件绝对路径"
                    font.pixelSize: 12
                    selectByMouse: true
                    background: Rectangle {
                        radius: 6
                        border.color: editPathField.activeFocus ? "#3B82F6" : "#D1D5DB"
                        border.width: editPathField.activeFocus ? 1.5 : 1
                        color: "#FFFFFF"
                    }
                }
            }
        }

        // 场景 B：普通查看模式（支持普通通知文本或应用卡片信息）
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: !popup.isEditing

            // 若带有路径/应用信息，渲染预览信息框
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: infoLayout.implicitHeight + 20
                radius: 8
                color: "#F9FAFB"
                border.color: "#E5E7EB"
                border.width: 1

                RowLayout {
                    id: infoLayout
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 12

                    // 软件代表字符徽标（当有字符时显示）
                    Rectangle {
                        visible: popup.characterText !== ""
                        width: 38
                        height: 38
                        radius: 8
                        color: popup.iconColor
                        Layout.alignment: Qt.AlignTop

                        Label {
                            anchors.centerIn: parent
                            text: popup.characterText
                            font.pixelSize: 15
                            font.bold: true
                            color: "#FFFFFF"
                        }
                    }

                    // 文本信息详情
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: popup.editable ? "路径 / 详细信息" : "信息内容"
                            font.pixelSize: 11
                            color: "#9CA3AF"
                        }

                        // 支持文本长内容选择与复制
                        TextEdit {
                            Layout.fillWidth: true
                            text: popup.contentText
                            font.pixelSize: 13
                            color: "#374151"
                            wrapMode: Text.WrapAnywhere
                            readOnly: true
                            selectByMouse: true
                        }
                    }
                }
            }
        }

        // --- 3. 底部操作按钮区域 ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // 模式 1：处于编辑状态时的操作按钮 [取消] [保存]
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: popup.editable && popup.isEditing

                Item { Layout.fillWidth: true }

                Button {
                    text: "取消"
                    implicitHeight: 36
                    implicitWidth: 72
                    font.pixelSize: 13
                    background: Rectangle {
                        radius: 6
                        border.color: "#D1D5DB"
                        color: parent.down ? "#E5E7EB" : (parent.hovered ? "#F9FAFB" : "#FFFFFF")
                    }
                    onClicked: popup.isEditing = false
                }

                Button {
                    id: saveSubmitBtn
                    text: "保存修改"
                    implicitHeight: 36
                    implicitWidth: 88
                    font.pixelSize: 13
                    font.bold: true

                    contentItem: Text {
                        text: saveSubmitBtn.text
                        font: saveSubmitBtn.font
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 6
                        color: saveSubmitBtn.down ? "#1D4ED8" : (saveSubmitBtn.hovered ? "#2563EB" : "#3B82F6")
                    }

                    onClicked: {
                        popup.titleText = editNameField.text.trim()
                        popup.contentText = editPathField.text.trim()
                        popup.saved(popup.titleText, popup.contentText)
                        popup.isEditing = false
                        popup.close()
                    }
                }
            }

            // 模式 2：应用卡片预览状态的操作按钮 [删除] [编辑] [启动]
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                visible: popup.editable && !popup.isEditing

                Button {
                    text: "删除"
                    implicitHeight: 36
                    implicitWidth: 64
                    font.pixelSize: 12

                    contentItem: Text {
                        text: parent.text
                        font: parent.font
                        color: "#EF4444"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 6
                        border.color: parent.down ? "#FCA5A5" : "#FECACA"
                        color: parent.down ? "#FEE2E2" : (parent.hovered ? "#FEF2F2" : "#FFFFFF")
                    }

                    onClicked: {
                        popup.deleted()
                        popup.close()
                    }
                }

                Item { Layout.fillWidth: true }

                Button {
                    text: "编辑"
                    implicitHeight: 36
                    implicitWidth: 72
                    font.pixelSize: 13
                    background: Rectangle {
                        radius: 6
                        border.color: "#D1D5DB"
                        color: parent.down ? "#E5E7EB" : (parent.hovered ? "#F9FAFB" : "#FFFFFF")
                    }
                    onClicked: {
                        editNameField.text = popup.titleText
                        editPathField.text = popup.contentText
                        popup.isEditing = true
                    }
                }

                Button {
                    id: launchBtn
                    text: "立即运行"
                    implicitHeight: 36
                    implicitWidth: 88
                    font.pixelSize: 13
                    font.bold: true

                    contentItem: Text {
                        text: launchBtn.text
                        font: launchBtn.font
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 6
                        color: launchBtn.down ? "#1D4ED8" : (launchBtn.hovered ? "#2563EB" : "#3B82F6")
                    }

                    onClicked: {
                        popup.launched()
                        popup.close()
                    }
                }
            }

            // 模式 3：普通信息/通知弹窗状态（非可编辑） [确定]
            RowLayout {
                Layout.fillWidth: true
                visible: !popup.editable

                Item { Layout.fillWidth: true }

                Button {
                    id: okBtn
                    text: "我知道了"
                    implicitHeight: 36
                    implicitWidth: 90
                    font.pixelSize: 13

                    contentItem: Text {
                        text: okBtn.text
                        font: okBtn.font
                        color: "#374151"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    background: Rectangle {
                        radius: 6
                        border.color: okBtn.down ? "#9CA3AF" : "#D1D5DB"
                        color: okBtn.down ? "#E5E7EB" : (okBtn.hovered ? "#F9FAFB" : "#FFFFFF")
                    }

                    onClicked: popup.close()
                }
            }
        }
    }
}