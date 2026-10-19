import QtQuick 2.0
import Sailfish.Silica 1.0

TextField {
    id: field
    label: qsTr("Value")
    text: parent.value
    readOnly: !writable
    inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase

    rightItem: IconButton {
        visible: !!(field.parent && field.parent.remove)
        icon.source: 'image://theme/icon-splus-remove'
        onClicked: field.parent.remove()
    }

    EnterKey.enabled: !!(field.parent && field.parent.enterKeyEnabled)
    EnterKey.iconSource: field.parent ? field.parent.enterKeyIconSource || '' : ''
    EnterKey.onClicked: field.parent.enterKeyClicked()
}
