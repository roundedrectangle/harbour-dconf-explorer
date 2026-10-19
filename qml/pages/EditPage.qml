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
        id: flickable
        anchors.fill: parent
        contentHeight: column.height

        property bool scrollToBottomOnFlickEnd
        onFlickEnded:
            if (scrollToBottomOnFlickEnd) {
                scrollToBottom()
                scrollToBottomOnFlickEnd = false
            }

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
                focus: true // needed to make TextField focus work (and inner QML TextInput)
                sourceComponent: Component {
                    TextField {
                        label: qsTr("Key")
                        description: qsTr("To create the key in a subdirectory, separate the path with slashes.") + (valueUndefined ? '' : ' ' + qsTr("Warning: the key is already used. Existing value will be overwritten"))
                        inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                        focus: true
                        onTextChanged: {
                            // Remove any slashes at start, remove duplicate ones
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
                id: valueEditorLoader
                type: typeComboBox.currentIndex
                sourceComponent: type == 3 ? listComponent : implicitComponent
                focus: true

                value: page.value
                onSetValue: {
                    console.log("Setting", value, page.value, page.value === value)
                    if (page.value !== value) page.value = value
                }

                enterKeyEnabled: writable
                enterKeyIconSource: "image://theme/icon-m-enter-accept"
                onEnterKeyClicked: accept()

                Component {
                    id: listComponent
                    Column {
                        id: listColumn
                        width: parent.width
                        bottomPadding: Theme.paddingLarge

                        property alias listType: listTypeComboBox.currentIndex

                        function addListValue() {
                            var value
                            switch (listType) {
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
                            if (listType == 1 || listType == 2) listRepeater.indexToFocus = page.value.length
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
                            id: listRepeater
                            model: value.length

                            property int indexToFocus: -1
                            onItemAdded:
                                if (index == indexToFocus)
                                    item.forceActiveFocus()

                            delegate: ValueEditorLoader {
                                type: listType

                                value: page.value[index]
                                onSetValue: {
                                    var newValue = page.value.slice(0)
                                    newValue[index] = value
                                    page.value = newValue
                                }

                                function remove() {
                                    page.value = page.value.slice(0, index).concat(page.value.slice(index + 1))
                                }

                                property bool needFocus
                                function forceActiveFocus() {
                                    if (status == Loader.Ready) {
                                        item.forceActiveFocus()
                                        flickable.scrollToBottomOnFlickEnd = true
                                    } else needFocus = true
                                }
                                onStatusChanged: if (needFocus && (type == 1 || type == 2)) forceActiveFocus()

                                property bool isLast: index == page.value.length - 1
                                enterKeyIconSource: isLast ? "image://theme/icon-m-add" : "image://theme/icon-m-enter-next"
                                onEnterKeyClicked:
                                    if (isLast) listColumn.addListValue()
                                    else listRepeater.itemAt(index + 1).forceActiveFocus()
                            }
                        }
                    }
                }
            }
        }

        PushUpMenu {
            visible: writable && valueEditorLoader.type == 3
                     && valueEditorLoader.status == Loader.Ready && valueEditorLoader.item.listType >= 0
            quickSelect: true
            MenuItem {
                text: qsTr("Add")
                onClicked: valueEditorLoader.item.addListValue()
            }
        }
    }
}
