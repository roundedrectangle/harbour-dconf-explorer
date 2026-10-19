import QtQuick 2.0
import Sailfish.Silica 1.0

Loader {
    id: loader
    width: parent.width

    property int type: -1
    readonly property Component implicitComponent:
        switch (type) {
        case 0:
            return boolComponent
        case 1:
            return numberComponent
        case 2:
            return stringComponent
        default:
            return unsupportedComponent
        }
    sourceComponent: implicitComponent

    property var value
    signal setValue(var value)

    property bool enterKeyEnabled: true
    property url enterKeyIconSource
    signal enterKeyClicked

    Component {
        id: boolComponent
        TextSwitch {
            id: textSwitch
            text: qsTr("Enabled")
            checked: !!parent.value
            automaticCheck: false
            onClicked: parent.setValue(!checked)
            enabled: writable

            IconButton {
                id: removeButton
                anchors {
                    right: parent.right
                    rightMargin: Theme.horizontalPageMargin
                }
                visible: writable && !!(textSwitch.parent && textSwitch.parent.remove)
                enabled: visible
                icon.source: 'image://theme/icon-m-remove'
                onClicked: textSwitch.parent.remove()
            }
            rightMargin: removeButton.visible
        }
    }
    Component {
        id: numberComponent
        EditorFieldBase {
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            acceptableInput: {
                if (!text) return false
                var n = Number(text)
                return !isNaN(n) && isFinite(n)
            }
            onTextChanged: if (acceptableInput) parent.setValue(Number(text))
        }
    }
    Component {
        id: stringComponent
        EditorFieldBase {
            onTextChanged: parent.setValue(text)
        }
    }
    Component {
        id: unsupportedComponent
        InfoLabel {
            text: qsTr("Unsupported type")
        }
    }
}
