// qmllint disable unqualified
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Page {
    id: detailPage

    property string appName: ""
    property string appPath: ""
    property string randomColor: generateRandomColor()

    function generateRandomColor() {
        const letters = '0123456789ABCDEF'
        let color = '#'
        for (let i = 0; i < 6; i++) {
            color += letters[Math.floor(Math.random() * 16)]
        }
        return color
    }

    // 颜色合法性校验辅助函数，防止非法字符串导致 QML 报警
    function getValidColor(colorStr, fallback) {
        const c = Qt.color(colorStr)
        return (c.a > 0 || colorStr.toLowerCase() === "#000000" || colorStr.toLowerCase() === "black") ? colorStr : fallback
    }

    background: Rectangle {
        color: "#F5F6F8"
    }

    header: ToolBar {
        background: Rectangle {
            color: "#FFFFFF"
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: "#E2E4E8"
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12

            ToolButton {
                text: "‹ 返回"
                font.pixelSize: 14
                font.bold: true
                onClicked: detailPage.StackView.view.pop()
            }

            Label {
                text: "应用配置"
                font.pixelSize: 15
                font.bold: true
                color: "#1E2022"
                Layout.fillWidth: true
                horizontalAlignment: Qt.AlignHCenter
            }

            Item { width: 48 } // 视觉平衡占位
        }
    }

    ScrollView {
        anchors.fill: parent
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: Math.min(parent.width - 32, 440)
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 20

            Item { height: 8 } // 顶部间距

            // 顶部实时徽标预览卡片
            Rectangle {
                Layout.fillWidth: true
                height: 108
                radius: 12
                color: "#FFFFFF"
                border.color: "#E5E7EB"
                border.width: 1

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 16

                    Rectangle {
                        width: 64
                        height: 64
                        radius: 14
                        color: detailPage.getValidColor(colorInput.text, "#4F46E5")
                        border.color: Qt.rgba(0, 0, 0, 0.08)
                        border.width: 1

                        Label {
                            anchors.centerIn: parent
                            text: characterInput.text.trim() !== "" ? characterInput.text.toUpperCase() : "A"
                            font.pixelSize: 26
                            font.bold: true
                            color: "#FFFFFF"
                        }
                    }

                    ColumnLayout {
                        spacing: 4
                        Label {
                            text: nameInput.text.trim() !== "" ? nameInput.text : "应用名称"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#111827"
                            Layout.maximumWidth: 260
                            elide: Text.ElideRight
                        }
                        Label {
                            text: "实时图标与配置预览"
                            font.pixelSize: 12
                            color: "#6B7280"
                        }
                    }
                }
            }

            // 表单卡片区域
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: formLayout.implicitHeight + 32
                radius: 12
                color: "#FFFFFF"
                border.color: "#E5E7EB"
                border.width: 1

                ColumnLayout {
                    id: formLayout
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 14

                    // 软件名称
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Label {
                            text: "软件名称"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#4B5563"
                        }

                        TextField {
                            id: nameInput
                            Layout.fillWidth: true
                            implicitHeight: 38
                            text: detailPage.appName
                            placeholderText: "例如：Google Chrome"
                            font.pixelSize: 13
                            selectByMouse: true
                            background: Rectangle {
                                radius: 6
                                border.color: nameInput.activeFocus ? "#3B82F6" : "#D1D5DB"
                                border.width: nameInput.activeFocus ? 1.5 : 1
                                color: "#FFFFFF"
                            }
                        }
                    }

                    // 软件路径
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Label {
                            text: "执行路径 (不可编辑)"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#4B5563"
                        }

                        TextField {
                            id: pathInput
                            Layout.fillWidth: true
                            implicitHeight: 38
                            text: detailPage.appPath
                            readOnly: true
                            font.pixelSize: 12
                            color: "#6B7280"
                            selectByMouse: true
                            background: Rectangle {
                                radius: 6
                                border.color: "#E5E7EB"
                                color: "#F9FAFB"
                            }
                        }
                    }

                    // 代表字符
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Label {
                            text: "代表字符 (1~2 个字符)"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#4B5563"
                        }

                        TextField {
                            id: characterInput
                            Layout.fillWidth: true
                            implicitHeight: 38
                            placeholderText: "如：C、CH"
                            maximumLength: 2
                            font.pixelSize: 13
                            selectByMouse: true
                            background: Rectangle {
                                radius: 6
                                border.color: characterInput.activeFocus ? "#3B82F6" : "#D1D5DB"
                                border.width: characterInput.activeFocus ? 1.5 : 1
                                color: "#FFFFFF"
                            }
                        }
                    }

                    // 主题颜色
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        Label {
                            text: "图标背景色"
                            font.pixelSize: 12
                            font.bold: true
                            color: "#4B5563"
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            TextField {
                                id: colorInput
                                Layout.fillWidth: true
                                implicitHeight: 38
                                text: detailPage.randomColor
                                placeholderText: "#HEX 格式"
                                font.pixelSize: 13
                                selectByMouse: true
                                background: Rectangle {
                                    radius: 6
                                    border.color: colorInput.activeFocus ? "#3B82F6" : "#D1D5DB"
                                    border.width: colorInput.activeFocus ? 1.5 : 1
                                    color: "#FFFFFF"
                                }
                            }

                            // 颜色色块预览
                            Rectangle {
                                width: 38
                                height: 38
                                radius: 6
                                color: detailPage.getValidColor(colorInput.text, "#CCCCCC")
                                border.color: "#D1D5DB"
                                border.width: 1
                            }

                            // 随机颜色按钮
                            Button {
                                id: randomBtn
                                implicitHeight: 38
                                implicitWidth: 70
                                text: "随机"
                                font.pixelSize: 12
                                onClicked: {
                                    colorInput.text = detailPage.generateRandomColor()
                                }
                                background: Rectangle {
                                    radius: 6
                                    border.color: randomBtn.down ? "#9CA3AF" : "#D1D5DB"
                                    color: randomBtn.down ? "#E5E7EB" : (randomBtn.hovered ? "#F3F4F6" : "#FFFFFF")
                                }
                            }
                        }
                    }
                }
            }

            // 保存按钮
            Button {
                id: submitBtn
                Layout.fillWidth: true
                implicitHeight: 42
                text: "确定并保存"
                font.pixelSize: 14
                font.bold: true

                contentItem: Text {
                    text: submitBtn.text
                    font: submitBtn.font
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 8
                    color: submitBtn.down ? "#1D4ED8" : (submitBtn.hovered ? "#2563EB" : "#3B82F6")
                }

                onClicked: {
                    const targetWin = detailPage.Window.window
                    const stack = detailPage.StackView.view

                    if (typeof moduleModel !== "undefined" && moduleModel.addModule) {
                        moduleModel.addModule(nameInput.text, pathInput.text, colorInput.text, characterInput.text)
                    } else {
                        console.warn("moduleModel 未注册或未找到 addModule 方法")
                    }

                    if (stack) {
                        stack.pop(null, StackView.Immediate)
                    }

                    if (targetWin) {
                        targetWin.close()
                    }
                }
            }

            Item { height: 16 } // 底部留白
        }
    }
}