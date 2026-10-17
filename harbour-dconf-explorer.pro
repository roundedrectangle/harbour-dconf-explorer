# NOTICE:
#
# Application name defined in TARGET has a corresponding QML filename.
# If name defined in TARGET is changed, the following needs to be done
# to match new name:
#   - corresponding QML filename must be changed
#   - desktop icon filename must be changed
#   - desktop filename must be changed
#   - icon definition filename in desktop file must be changed
#   - translation filenames have to be changed

# The name of your application
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
    qml/pages/ListPage.qml \
    rpm/harbour-dconf-explorer.changes.in \
    rpm/harbour-dconf-explorer.changes.run.in \
    rpm/harbour-dconf-explorer.spec \
    translations/*.ts \
    harbour-dconf-explorer.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172

# to disable building translations every time, comment out the
# following CONFIG line
CONFIG += sailfishapp_i18n

# German translation is enabled as an example. If you aren't
# planning to localize your app, remember to comment out the
# following TRANSLATIONS line. And also do not forget to
# modify the localized app name in the the .desktop file.
TRANSLATIONS += translations/harbour-dconf-explorer-de.ts
