import QtQuick 2.6
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import "../components"

Dialog {
    id: page
    allowedOrientations: Orientation.All

    property bool creating
    property string createPath
    property bool fromGoTo
    property alias key: configurationValue.key
    property alias path: configurationValue.key
    property var value: configurationValue.value

    property bool writable

    ConfigurationValue {
        id: configurationValue
    }

    function getType(value) {
        console.log("Getting type", typeof value, value, JSON.stringify(value))
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
    onKeyChanged: {
        if (key) py.checkIsWritable(key)
        else writable = false
    }

    readonly property bool valueUndefined: typeof configurationValue.value === 'undefined'
    onValueUndefinedChanged: if (!fromGoTo && !creating && valueUndefined) pageStack.pop()

    canAccept: writable
    onAcceptBlocked: nonWritableLabel.active = true
    onAccepted: configurationValue.value = value

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        PullDownMenu {
            visible: !creating && writable
            MenuItem {
                text: qsTr("Remove")
                onClicked: pageStack.previousPage().removeKey(key)
            }
            MenuItem {
                visible: writable
                text: qsTr("Save")
                onClicked: configurationValue.value = value
            }
        }

        Column {
            id: column
            width: parent.width

            Item {
                width: parent.width
                height: header.height + keyText.height

                DialogHeader {
                    id: header
                    title: creating ? qsTr("New entry") : qsTr("Editing")
                    acceptText: qsTr("Save")
                }
                Label {
                    id: keyText
                    anchors {
                        top: header.bottom
                        topMargin: -Theme.paddingMedium - Theme.paddingSmall // Move padding below the key
                    }
                    x: Theme.horizontalPageMargin
                    width: parent.width - 2*x
                    text: creating ? qsTr("in %1").arg(createPath) : key
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.secondaryHighlightColor
                    wrapMode: Text.Wrap
                }
            }

            Label {
                id: nonWritableLabel
                x: Theme.horizontalPageMargin
                width: parent.width - 2*x
                topPadding: Theme.paddingSmall
                text: qsTr("Value is read-only")
                property bool active: creating && !!key
                visible: active && !writable
                font.pixelSize: Theme.fontSizeMedium
                color: Theme.errorColor
                wrapMode: Text.Wrap
            }

            Loader {
                width: parent.width
                active: creating
                sourceComponent: Component {
                    TextField {
                        label: qsTr("Key")
                        description: qsTr("To create the key in a subdirectory, separate the path with slashes.") + (valueUndefined ? '' : ' ' + qsTr("Warning: the key is already used. Existing value will be overwritten"))
                        onTextChanged: {
                            // Remove any slashes at start, and replace duplicate ones with 1
                            var newKey = appWindow.normalizePath(text.replace(/^\/+/, ''))
                            page.key = newKey ? (createPath + newKey) : ''
                        }
                    }
                }
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

                        function addListValue() {
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

                        ComboBox {
                            id: listTypeComboBox
                            label: qsTr("List type")
                            enabled: writable
                            currentIndex: page.value && page.value.length ? getType(page.value[0]) : -1
                            menu: TypeContextMenu { isList: true }
                            onCurrentIndexChanged:
                                if (!page.value || !page.value.length || !page.value[0]) {
                                    page.value = []
                                    addListValue()
                                }
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
                            onClicked: addListValue()
                        }
                    }
                }
            }
        }
    }
}
