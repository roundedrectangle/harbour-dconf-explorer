import QtQuick 2.0
import Sailfish.Silica 1.0
import Nemo.Notifications 1.0
import io.thp.pyotherside 1.5
import Nemo.Configuration 1.0
import "pages"

ApplicationWindow {
    id: appWindow
    initialPage: Component { ListPage {} }
    cover: Qt.resolvedUrl("cover/CoverPage.qml")
    allowedOrientations: defaultAllowedOrientations

    Notification {
        id: notification
        replacesId: 0
        onReplacesIdChanged: if (replacesId !== 0) replacesId = 0
        isTransient: true
        icon: 'image://theme/icon-lock-warning'

        function showError(text, description) {
            summary = text
            body = description
            publish()
        }
    }

    ConfigurationValue {
        id: favorites
        key: '/apps/harbour-dconf-explorer/favorites'
    }

    Python {
        id: py

        signal listReceived(string path, var keys)
        signal valueChanged(string path, string key)
        signal isEmptyReceived(string path, string dir, bool isEmpty)
        signal isWritableReceived(string key, bool isWritable)

        Component.onCompleted: {
            setHandler('ctypes_error', function(e) {
                notification.showError(qsTr("Unable to load native libraries"), e)
            })
            setHandler('client_error', function() {
                notification.showError(qsTr("Unable to create a DConf client"))
            })

            setHandler('list', function(path, keys) { listReceived(path, keys) })
            setHandler('changed', function(path, key) { valueChanged(path, key) })
            setHandler('empty', function(path, dir, isEmpty) { isEmptyReceived(path, dir, isEmpty) })
            setHandler('writable', function(key, isWritable) { isWritableReceived(key, isWritable) })

            addImportPath(Qt.resolvedUrl('.'))
            importModule_sync('dconf_iface')
        }

        function list(path) { call('dconf_iface.list', [path]) }
        function add(path) {
            list(path)
            call('dconf_iface.watch', [path])
        }
        function remove(path) { call('dconf_iface.unwatch', [path]) }
        function checkIsEmpty(path, dir) { call('dconf_iface.check_empty', [path, dir]) }
        function checkIsWritable(key) { call('dconf_iface.check_is_writable', [key]) }

        onReceived: console.log("Received message from Python", data)
        onError: console.error("Received an error", traceback)
    }

    Component.onDestruction: py.call_sync('dconf_iface.cleanup')
}
