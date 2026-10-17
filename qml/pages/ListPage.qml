import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property string path: '/'
    property bool loading: true

    ListModel {
        id: keysModel

        function find(key) {
            var res = -1
            for (var i=0; i < keysModel.count; i++)
                if (keysModel.get(i).key === key)
                    res = i
            return res
        }
    }

    ConfigurationGroup { id: tempGroup; synchronous: true }
    ConfigurationValue { id: tempValue }

    Connections {
        target: py
        onListReceived:
            if (path == page.path) {
                keysModel.clear()
                for (var i=0; i < keys.length; i++)
                    keysModel.append({key: keys[i]})
                loading = false
            }
        onValueChanged: {
            if (path.indexOf(page.path) != 0) return
            var parts = path.slice(page.path.length).split('/')

            var currentKey
            if (parts.length > 0)
                currentKey = parts[0] + (parts.length > 1 ? '/' : '')
            else currentKey = key

            if (!currentKey) {
                py.list(page.path)
                return
            }

            if (currentKey[currentKey.length - 1] === '/')
                // Folder
                py.checkIsEmpty(page.path, currentKey)
            else {
                var existingIndex = keysModel.find(currentKey)

                tempValue.key = path + currentKey
                tempValue.sync()
                if (typeof tempValue.value === 'undefined') {
                    // removed value
                    if (existingIndex >= 0) keysModel.remove(existingIndex)
                } else if (existingIndex < 0)
                    keysModel.append({key: currentKey}) // new value
            }
        }
        onIsEmptyReceived:
            if (path == page.path) {
                var existingIndex = keysModel.find(dir)
                if (isEmpty) { // removed value
                    if (existingIndex >= 0) keysModel.remove(existingIndex)
                } else if (existingIndex < 0)
                    keysModel.append({key: dir}) // new value
            }
    }

    Component.onCompleted: py.add(path)
    Component.onDestruction: py.remove(path)

    BusyLabel { running: loading }

    SilicaListView {
        anchors.fill: parent
        model: keysModel
        opacity: loading ? 0 : 1
        Behavior on opacity { FadeAnimator {} }

        PullDownMenu {
            // TODO
            visible: false
            MenuItem {
                visible: path != '/' // do not allow deleting root (too dangerous)
                text: qsTr("Remove")
                //onClicked: 0 // TODO: like in Remorse docs for fullscreen item
            }
            MenuItem {
                text: qsTr("Create entry")
                //onClicked: 0//pageStack.push(Qt.resolvedUrl("EditPage.qml", {create: true}))
            }
        }

        header: Column {
            width: parent.width

            PageHeader {
                title: qsTr("DConf Explorer")
                description: favoritesLoader.active ? '' : path
                descriptionWrapMode: Text.Wrap
            }

            Loader {
                id: favoritesLoader
                width: parent.width
                active: path == '/' && !!(favorites.value && favorites.value.length)
                height: status == Loader.Ready ? implicitHeight : 0
                sourceComponent: Component {
                    Column {
                        width: parent.width

                        SectionHeader { text: qsTr("Favorites") }

                        Repeater {
                            model: favorites.value
                            ConfigurationListItem {
                                key: modelData
                                favorite: true
                            }
                        }

                        SectionHeader { text: path }
                    }
                }
            }
        }

        delegate: ConfigurationListItem {
            key: path + model.key
            displayKey: model.key
        }
    }
}
