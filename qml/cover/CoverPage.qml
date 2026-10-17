import QtQuick 2.0
import Sailfish.Silica 1.0

CoverBackground {
    Column {
        x: Theme.paddingSmall
        width: parent.width - 2*x
        spacing: Theme.paddingMedium
        anchors.verticalCenter: parent.verticalCenter

        Text {
            width: parent.width
            text: qsTr("DConf Explorer")
            font.pixelSize: Theme.fontSizeLarge
            color: Theme.highlightColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }

        Label {
            width: parent.width
            text: pageStack.currentPage.path || pageStack.currentPage.key || ''
            visible: !!text
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.secondaryHighlightColor
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
        }
    }
}
