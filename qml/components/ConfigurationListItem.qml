import QtQuick 2.0
import Sailfish.Silica 1.0

ListItem {
    property string key
    property string displayKey: key
    property bool favorite: !!favorites.value && favorites.value.indexOf(key) >= 0

    contentHeight: Math.max(icon.height + Theme.paddingSmall, label.height + Theme.paddingSmall, Theme.itemSizeSmall)
    hidden: page.removingKey == key

    readonly property bool isFolder: key[key.length - 1] === '/'

    function remove() {
        if (isFolder) {
            tempGroup.path = key.slice(0, -1)
            tempGroup.sync()
            tempGroup.clear()
        } else {
            tempValue.key = key
            tempValue.sync()
            tempValue.value = undefined
        }
    }

    Icon {
        id: icon
        x: Theme.horizontalPageMargin
        anchors.verticalCenter: parent.verticalCenter
        source: isFolder ? 'image://theme/icon-m-file-folder' : 'image://theme/icon-m-document'
    }

    Label {
        id: label
        anchors {
            left: icon.right
            leftMargin: Theme.paddingMedium
            right: parent.right
            rightMargin: Theme.horizontalPageMargin
            verticalCenter: parent.verticalCenter
        }
        text: isFolder ? displayKey.slice(0, -1) : displayKey
        wrapMode: Text.Wrap
    }

    onClicked:
        if (isFolder)
            pageStack.push(Qt.resolvedUrl('../pages/ListPage.qml'), {path: key})
        else
            pageStack.push(Qt.resolvedUrl('../pages/EditPage.qml'), {key: key})

    menu: Component {
        ContextMenu {
            MenuItem {
                text: qsTr("Remove")
                onClicked: remorseDelete(remove)
            }
            MenuItem {
                text: favorite ? qsTr("Remove from favorites") : qsTr("Add to favorites")
                onClicked: {
                    if (!favorites.value) favorites.value = []

                    if (favorite)
                        favorites.value = favorites.value.filter(function (el) { return el !== key })
                    else
                        favorites.value = favorites.value.concat(key)
                }
            }
        }
    }
}
