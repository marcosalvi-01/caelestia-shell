pragma ComponentBehavior: Bound

import QtQuick
import qs.components.controls
import Quickshell.Widgets
import Caelestia.Config
import qs.components
import qs.services

Item {
    id: root

    readonly property var player: Players.active
    readonly property var iconData: Players.getIconData(player)
    readonly property bool visiblePlayer: Players.usefulPlayers.length > 0 && !!player
    readonly property bool canToggle: player?.canTogglePlaying ?? false
    readonly property bool canGoPrevious: player?.canGoPrevious ?? false
    readonly property bool canGoNext: player?.canGoNext ?? false
    readonly property string buttonIcon: player?.isPlaying ? "pause" : "play_arrow"
    readonly property real contentPadding: Tokens.padding.small
    readonly property real contentSpacing: Math.floor(Tokens.spacing.small / 2)
    readonly property real workspaceInnerSize: Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2
    readonly property real mediaControlSize: Math.round(workspaceInnerSize * 0.80)

    implicitWidth: visiblePlayer ? Tokens.sizes.bar.innerWidth : 0
    implicitHeight: visiblePlayer ? content.implicitHeight + contentPadding * 2 : 0
    visible: visiblePlayer

    Behavior on implicitWidth {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    Behavior on implicitHeight {
        Anim {
            type: Anim.DefaultSpatial
        }
    }

    StyledRect {
        anchors.fill: parent

        color: Colours.tPalette.m3surfaceContainer
        radius: Tokens.rounding.full

        StateLayer {
            disabled: !root.canToggle
            radius: parent.radius
            onClicked: Players.toggleActive()
        }

        Item {
            id: content

            anchors.centerIn: parent

            implicitWidth: Math.max(iconSlot.implicitWidth, controls.implicitWidth)
            implicitHeight: iconSlot.implicitHeight + root.contentSpacing + controls.implicitHeight

            Column {
                anchors.centerIn: parent
                spacing: root.contentSpacing

                Item {
                    id: iconSlot

                    anchors.horizontalCenter: parent.horizontalCenter

                    implicitWidth: root.mediaControlSize
                    implicitHeight: implicitWidth

                    Item {
                        id: sourceIcon

                        anchors.centerIn: parent
                        implicitWidth: parent.implicitWidth
                        implicitHeight: implicitWidth

                        Loader {
                            anchors.fill: parent
                            sourceComponent: root.iconData.source ? appIcon : materialIcon
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
                                anchors.horizontalCenterOffset: font.pointSize * 0.04

                                text: root.iconData.materialIcon
                                color: Colours.palette.m3onSurfaceVariant
                                font.pointSize: Tokens.font.size.larger
                            }
                        }
                    }

                    StyledRect {
                        anchors.centerIn: parent
                        visible: !root.iconData.source
                        z: -1

                        implicitWidth: parent.implicitWidth
                        implicitHeight: implicitWidth
                        radius: Tokens.rounding.full
                        color: Colours.layer(Colours.palette.m3primary, 0.08)
                    }
                }

                Column {
                    id: controls

                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: root.contentSpacing

                    IconButton {
                        anchors.horizontalCenter: parent.horizontalCenter

                        icon: "fast_rewind"
                        disabled: !root.canGoPrevious
                        type: IconButton.Filled
                        padding: Math.max(1, Tokens.padding.smaller / 2)
                        implicitWidth: root.mediaControlSize
                        implicitHeight: implicitWidth
                        font.pointSize: Tokens.font.size.larger
                        onClicked: Players.previousActive()
                    }

                    IconButton {
                        anchors.horizontalCenter: parent.horizontalCenter

                        icon: root.buttonIcon
                        disabled: !root.canToggle
                        type: IconButton.Filled
                        padding: Math.max(1, Tokens.padding.smaller / 2)
                        implicitWidth: root.mediaControlSize
                        implicitHeight: implicitWidth
                        font.pointSize: Tokens.font.size.larger
                        onClicked: Players.toggleActive()
                    }

                    IconButton {
                        anchors.horizontalCenter: parent.horizontalCenter

                        icon: "fast_forward"
                        disabled: !root.canGoNext
                        type: IconButton.Filled
                        padding: Math.max(1, Tokens.padding.smaller / 2)
                        implicitWidth: root.mediaControlSize
                        implicitHeight: implicitWidth
                        font.pointSize: Tokens.font.size.larger
                        onClicked: Players.nextActive()
                    }
                }
            }
        }
    }
}
