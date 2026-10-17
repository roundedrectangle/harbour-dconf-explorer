import QtQuick 2.0
import Sailfish.Silica 1.0

TextField {
    id: field
    label: qsTr("Value")
    text: parent.value
    readOnly: !writable

    rightItem: IconButton {
        visible: !!(field.parent && field.parent.remove)
        icon.source: 'image://theme/icon-splus-remove'
        onClicked: field.parent.remove()
    }
}
