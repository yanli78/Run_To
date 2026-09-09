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

    // 对外数据接口（对应 4 个角色）
    property string titleText: ""
    property string contentText: ""
    property string iconColor: "#3B82F6"
    property string characterText: ""

    // 功能控制接口
    property bool editable: false // 是否启用编辑/操作模式
    property bool isEditing: false // 当前是否处于编辑状态

    // 【修改】信号携带 4 个参数：名称、路径、颜色、代表字符
    signal saved(string newTitle, string newContent, string newColor, string newCharacter)
    signal deleted()
    signal launched()

    // 颜色合法性校验辅助函数，防止非法字符串导致 QML 报错
    function getValidColor(colorStr, fallback) {
        if (!colorStr) return fallback
        var c = Qt.color(colorStr)
        return (c.a > 0 || colorStr.toLowerCase() === "#000000" || colorStr.toLowerCase() === "black") ? colorStr : fallback
    }

    // 弹窗展开时同步初始化表单
    onAboutToShow: {
        isEditing = false
        editNameField.text = titleText
        editPathField.text = contentText
        editCharField.text = characterText
        editColorField.text = iconColor
    }

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

        // --- 1. 顶部标题栏 ---
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

            // 软件名称与代表字符（并排）
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // 软件名称输入框
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

                // 代表字符输入框与徽标实时预览
                ColumnLayout {
                    Layout.preferredWidth: 120
                    spacing: 4

                    Label {
                        text: "代表字符"
                        font.pixelSize: 12
                        font.bold: true
                        color: "#4B5563"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        TextField {
                            id: editCharField
                            Layout.fillWidth: true
                            implicitHeight: 38
                            text: popup.characterText
                            placeholderText: "A"
                            maximumLength: 2
                            font.pixelSize: 13
                            selectByMouse: true
                            background: Rectangle {
                                radius: 6
                                border.color: editCharField.activeFocus ? "#3B82F6" : "#D1D5DB"
                                border.width: editCharField.activeFocus ? 1.5 : 1
                                color: "#FFFFFF"
                            }
                        }

                        // 字符与颜色联动实时预览色块
                        Rectangle {
                            width: 38
                            height: 38
                            radius: 6
                            color: popup.getValidColor(editColorField.text, popup.iconColor)
                            border.color: Qt.rgba(0, 0, 0, 0.08)
                            border.width: 1

                            Label {
                                anchors.centerIn: parent
                                text: editCharField.text.trim() !== "" ? editCharField.text.toUpperCase() : "A"
                                font.pixelSize: 14
                                font.bold: true
                                color: "#FFFFFF"
                            }
                        }
                    }
                }
            }

            // 【新增】图标背景色输入行
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: "图标背景色 (#HEX)"
                    font.pixelSize: 12
                    font.bold: true
                    color: "#4B5563"
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    TextField {
                        id: editColorField
                        Layout.fillWidth: true
                        implicitHeight: 38
                        text: popup.iconColor
                        placeholderText: "例如：#3B82F6"
                        font.pixelSize: 13
                        selectByMouse: true
                        background: Rectangle {
                            radius: 6
                            border.color: editColorField.activeFocus ? "#3B82F6" : "#D1D5DB"
                            border.width: editColorField.activeFocus ? 1.5 : 1
                            color: "#FFFFFF"
                        }
                    }

                    // 纯色块预览
                    Rectangle {
                        width: 38
                        height: 38
                        radius: 6
                        color: popup.getValidColor(editColorField.text, "#CCCCCC")
                        border.color: "#D1D5DB"
                        border.width: 1
                    }
                }
            }

            // 执行路径输入框
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

        // 场景 B：普通查看模式
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12
            visible: !popup.isEditing

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

                    // 徽标块
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

                    // 信息展示
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label {
                            text: popup.editable ? "路径 / 详细信息" : "信息内容"
                            font.pixelSize: 11
                            color: "#9CA3AF"
                        }

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

        // --- 3. 底部操作栏 ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // 编辑状态按钮：[取消] [保存修改]
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

                    // 【核心】提取输入框内容，并触发 4 参信号
                    onClicked: {
                        popup.titleText = editNameField.text.trim()
                        popup.contentText = editPathField.text.trim()
                        popup.iconColor = popup.getValidColor(editColorField.text.trim(), popup.iconColor)
                        popup.characterText = editCharField.text.trim().toUpperCase()

                        popup.saved(popup.titleText, popup.contentText, popup.iconColor, popup.characterText)
                        popup.isEditing = false
                        popup.close()
                    }
                }
            }

            // 查看状态按钮：[删除] [编辑] [立即运行]
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
                        editColorField.text = popup.iconColor
                        editCharField.text = popup.characterText
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

            // 只读通知状态按钮：[我知道了]
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