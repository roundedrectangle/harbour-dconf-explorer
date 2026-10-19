import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Configuration 1.0
import "../components"

Page {
    id: page
    allowedOrientations: Orientation.All

    property string path: '/'
    property bool loading: true
    property bool fromGoTo
    property string removingKey
    readonly property bool empty: !loading && keysModel.count == 0
    property bool wasAdded: !fromGoTo

    property var favoritesRemorse
    readonly property bool haveFavorites: page.path == '/' && !!(favorites.value && favorites.value.length) && !(favoritesRemorse && favoritesRemorse.active)

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

                tempValue.key = page.path + currentKey
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

    function removeKey(key, isFolder) {
        pageStack.pop()

        var remorse
        if (isFolder)
            remorse = Remorse.popupAction(page, qsTr("Directory removed"), function() {
                tempGroup.path = key
                tempGroup.sync()
                tempGroup.clear()
            })
        else
            remorse = Remorse.popupAction(page, qsTr("Key removed"), function() {
                tempValue.key = key
                tempValue.sync()
                tempValue.value = undefined
            })

        removingKey = Qt.binding(function() { return remorse && remorse.active ? key : '' })
    }

    Component.onCompleted: if (!fromGoTo && path) py.add(path)
    Component.onDestruction: if (path && wasAdded) py.remove(path)

    readonly property bool emptyNeedPop: !fromGoTo && empty && page.status == PageStatus.Active
    onEmptyNeedPopChanged:
        if (emptyNeedPop) {
            pageStack.completeAnimation()
            pageStack.pop()
        }

    Timer {
        id: scrollToTopTimer
        interval: 20
        onTriggered: if (page.status != PageStatus.Active) listView.scrollToTop()
    }
    onHaveFavoritesChanged: scrollToTopTimer.restart()

    BusyLabel { running: loading }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: keysModel
        opacity: loading ? 0 : 1
        Behavior on opacity { FadeAnimator {} }

        PullDownMenu {
            MenuItem {
                visible: haveFavorites
                text: qsTr("Clear favorites")
                onClicked: favoritesRemorse = Remorse.popupAction(page, qsTr("Cleared favorites"), function() { favorites.value = [] })
            }
            MenuItem {
                visible: path == '/'
                text: qsTr("Go to…")
                onClicked: pageStack.push(Qt.resolvedUrl("GoToPage.qml"))
            }
            MenuItem {
                visible: path != '/' // do not allow removing root (too dangerous)
                text: qsTr("Remove")
                onClicked: pageStack.previousPage().removeKey(path, true)
            }
            MenuItem {
                text: qsTr("Create entry")
                onClicked: pageStack.push(Qt.resolvedUrl("EditPage.qml"), {creating: true, createPath: path})
            }
        }

        header: Column {
            width: parent.width

            PageHeader {
                title: qsTr("DConf Explorer")
                description: haveFavorites ? '' : path
                descriptionWrapMode: Text.Wrap
            }

            Loader {
                id: favoritesLoader
                width: parent.width
                active: haveFavorites
                height: status == Loader.Ready ? implicitHeight : 0
                sourceComponent: Component {
                    Column {
                        width: parent.width

                        SectionHeader { text: qsTr("Favorites") }

                        Repeater {
                            model: favorites.value
                            onItemRemoved: scrollToTopTimer.restart()
                            onItemAdded: scrollToTopTimer.restart()
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

        ViewPlaceholder {
            enabled: empty
            text: qsTr("No entries")
            hintText: qsTr("Pull down to create a new entry")
        }
    }
}
