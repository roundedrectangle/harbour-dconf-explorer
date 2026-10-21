TARGET = harbour-dconf-explorer

CONFIG += sailfishapp_qml

DISTFILES += qml/harbour-dconf-explorer.qml \
    qml/components/ConfigurationListItem.qml \
    qml/components/EditorFieldBase.qml \
    qml/components/TypeContextMenu.qml \
    qml/components/ValueEditorLoader.qml \
    qml/components/dconf_iface.py \
    qml/cover/CoverPage.qml \
    qml/pages/EditPage.qml \
    qml/pages/GoToPage.qml \
    qml/pages/ListPage.qml \
    rpm/harbour-dconf-explorer.changes.in \
    rpm/harbour-dconf-explorer.changes.run.in \
    rpm/harbour-dconf-explorer.spec \
    translations/*.ts \
    harbour-dconf-explorer.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

CONFIG += sailfishapp_i18n

TRANSLATIONS += translations/harbour-dconf-explorer-ru.ts \
    translations/harbour-dconf-explorer-fr.ts
