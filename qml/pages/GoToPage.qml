import QtQuick 2.0
import Sailfish.Silica 1.0

Dialog {
    allowedOrientations: Orientation.All

    property string normalizedPath: appWindow.normalizePath('/' + pathField.text)
    property bool isFolder: normalizedPath[normalizedPath.length - 1] === '/'

    canAccept: !!normalizedPath
    acceptDestinationAction: PageStackAction.Replace
    acceptDestination: canAccept ? Qt.resolvedUrl(isFolder ? "ListPage.qml" : "EditPage.qml") : null

    // Do not make it depend on isFolder to avoid race conditions
    acceptDestinationProperties: ({
        path: normalizedPath,
        fromGoTo: true // Force to never close
    })

    onAcceptPendingChanged: if (acceptPending) acceptDestinationInstance.path = normalizedPath
    onAccepted:
        // ideally a folder's contents should be loaded when acceptPending = true,
        // but Dialog.acceptDestionation is pretty unstable and running py.remove() on a not yet added path results in a crash
        if (isFolder) {
            py.add(normalizedPath)
            acceptDestinationInstance.wasAdded = true
        }

    Column {
        width: parent.width
        DialogHeader {
            title: qsTr("Go to…")
            acceptText: qsTr("Go")
        }
        TextField {
            id: pathField
            label: qsTr("Path")
            textLeftMargin: textMargin
            text: '/'
            onTextChanged: if (text.indexOf('/') != 0) text = '/' + text
            focus: true
        }
    }
}
