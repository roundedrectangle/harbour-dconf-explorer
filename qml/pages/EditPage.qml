import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import "../components"

// TODO: decide if this should be a Dialog instead
Page {
    id: page

    property alias key: configurationValue.key
    property alias value: configurationValue.value

    property bool writable: false

    ConfigurationValue {
        id: configurationValue
        onValueChanged: if (typeof value === 'undefined') pageStack.pop()
    }

    function getType(value) {
        console.log(value, JSON.stringify(value), typeof value)
        switch (typeof value) {
        case 'boolean':
            return 0
        case 'number':
            return 1
        case 'string':
            return 2
        }

        if (typeof value.length == 'number')
            return 3 // Array
        return -1
    }

    Connections {
        target: py
        onIsWritableReceived: if (key == page.key) page.writable = isWritable
    }
    onKeyChanged: py.checkIsWritable(key)

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            visible: false
            MenuItem {
                text: qsTr("Remove")
                // TODO
            }
        }

        Column {
            id: column
            width: parent.width

            PageHeader {
                id: header
                title: qsTr("Editing")
                description: key
                descriptionWrapMode: Text.Wrap
            }

            ComboBox {
                id: typeComboBox
                label: qsTr("Type")
                enabled: writable
                currentIndex: getType(page.value)
                menu: TypeContextMenu {}
            }

            ValueEditorLoader {
                type: typeComboBox.currentIndex
                sourceComponent: type == 3 ? listComponent : implicitComponent

                value: page.value
                onSetValue: {
                    console.log("Setting", value, page.value, page.value === value)
                    if (page.value !== value) page.value = value
                }

                Component {
                    id: listComponent
                    Column {
                        width: parent.width
                        bottomPadding: Theme.paddingLarge

                        ComboBox {
                            id: listTypeComboBox
                            label: qsTr("List type")
                            currentIndex: page.value && page.value.length ? getType(page.value[0]) : -1
                            menu: TypeContextMenu { isList: true }
                        }

                        Repeater {
                            model: value.length
                            delegate: ValueEditorLoader {
                                type: listTypeComboBox.currentIndex

                                value: page.value[index]
                                onSetValue: {
                                    var newValue = page.value.slice(0)
                                    newValue[index] = value
                                    page.value = newValue
                                }

                                function remove() {
                                    page.value = page.value.slice(0, index).concat(page.value.slice(index + 1))
                                }
                            }
                        }

                        Button {
                            visible: writable && listTypeComboBox.currentIndex >= 0
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                topMargin: Theme.paddingMedium
                            }
                            icon.source: 'image://theme/icon-splus-add'
                            text: qsTr("Add")
                            onClicked: {
                                var value
                                switch (listTypeComboBox.currentIndex) {
                                case 0:
                                    value = false
                                    break
                                case 1:
                                    value = 0
                                    break
                                case 2:
                                    value = ''
                                    break
                                default:
                                    return
                                }
                                page.value = page.value.concat(value)
                            }
                        }
                    }
                }
            }
        }
    }
}
