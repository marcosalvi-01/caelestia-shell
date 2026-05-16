import QtQuick
import Quickshell
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services
import qs.utils
import qs.modules.launcher.services

Item {
    id: root

    required property DesktopEntry modelData
    required property DrawerVisibilities visibilities
    readonly property var iconData: Icons.resolveDesktopEntryIcon(root.modelData)

    implicitHeight: Tokens.sizes.launcher.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Tokens.rounding.normal
        onClicked: {
            Apps.launch(root.modelData);
            root.visibilities.launcher = false;
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Tokens.padding.larger
        anchors.rightMargin: Tokens.padding.larger
        anchors.margins: Tokens.padding.smaller

        Item {
            id: icon

            implicitWidth: parent.height * 0.8
            implicitHeight: implicitWidth

            anchors.verticalCenter: parent.verticalCenter

            Loader {
                anchors.fill: parent
                sourceComponent: root.iconData.materialIcon ? materialIcon : appIcon
            }

            Component {
                id: appIcon

                IconImage {
                    anchors.fill: parent
                    asynchronous: true
                    source: root.iconData.source
                }
            }

            Component {
                id: materialIcon

                MaterialIcon {
                    anchors.centerIn: parent
                    text: root.iconData.materialIcon
                    font.pointSize: Tokens.font.size.extraLarge
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Tokens.spacing.normal
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width - favouriteIcon.width
            implicitHeight: name.implicitHeight + comment.implicitHeight

            StyledText {
                id: name

                text: root.modelData?.name ?? ""
                font.pointSize: Tokens.font.size.normal
            }

            StyledText {
                id: comment

                text: (root.modelData?.comment || root.modelData?.genericName || root.modelData?.name) ?? ""
                font.pointSize: Tokens.font.size.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                width: root.width - icon.width - favouriteIcon.width - Tokens.rounding.normal * 2

                anchors.top: name.bottom
            }
        }

        Loader {
            id: favouriteIcon

            asynchronous: true
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            active: root.modelData && Strings.testRegexList(GlobalConfig.launcher.favouriteApps, root.modelData.id)

            sourceComponent: MaterialIcon {
                text: "favorite"
                fill: 1
                color: Colours.palette.m3primary
            }
        }
    }
}
