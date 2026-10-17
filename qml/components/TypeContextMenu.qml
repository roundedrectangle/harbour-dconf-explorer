import QtQuick 2.0
import Sailfish.Silica 1.0

ContextMenu {
    property bool isList
    MenuItem { text: qsTr("Boolean") }
    MenuItem { text: qsTr("Number") } // combines int and double
    MenuItem { text: qsTr("String") }
    MenuItem { visible: !isList; text: qsTr("List") }
}
