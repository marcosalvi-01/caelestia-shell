pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Pipewire
import Caelestia.Config
import qs.components
import qs.components.containers
import qs.components.controls
import qs.services

Item {
    id: root

    required property PopoutState popouts

    readonly property int contentWidth: 360
    readonly property int screenHeight: (QsWindow.window as QsWindow)?.screen?.height ?? 0
    readonly property int maxContentHeight: screenHeight > 0 ? Math.floor(screenHeight * 0.7) : 520

    implicitWidth: contentWidth + Tokens.padding.normal * 2
    implicitHeight: flickable.height + Tokens.padding.normal * 2

    ButtonGroup {
        id: sinks
    }

    ButtonGroup {
        id: sources
    }

    StyledFlickable {
        id: flickable

        anchors.left: parent.left
        anchors.top: parent.top
        width: root.contentWidth
        height: Math.min(contentLayout.implicitHeight, root.maxContentHeight)
        clip: true
        contentWidth: width
        contentHeight: contentLayout.implicitHeight
        flickableDirection: Flickable.VerticalFlick

        StyledScrollBar.vertical: StyledScrollBar {
            flickable: flickable
        }

        ColumnLayout {
            id: contentLayout

            width: flickable.width - Tokens.padding.small
            spacing: Tokens.spacing.normal

            StyledText {
                text: qsTr("Output device")
                font.weight: 500
            }

            Repeater {
                model: Audio.sinks

                StyledRadioButton {
                    id: control

                    required property PwNode modelData

                    ButtonGroup.group: sinks
                    checked: Audio.sink?.id === modelData.id
                    onClicked: Audio.setAudioSink(modelData)
                    text: modelData.description
                }
            }

            StyledText {
                Layout.topMargin: Tokens.spacing.smaller
                text: qsTr("Input device")
                font.weight: 500
            }

            Repeater {
                model: Audio.sources

                StyledRadioButton {
                    required property PwNode modelData

                    ButtonGroup.group: sources
                    checked: Audio.source?.id === modelData.id
                    onClicked: Audio.setAudioSource(modelData)
                    text: modelData.description
                }
            }

            StyledText {
                Layout.topMargin: Tokens.spacing.smaller
                Layout.bottomMargin: -Tokens.spacing.small / 2
                text: qsTr("Volume (%1)").arg(Audio.muted ? qsTr("Muted") : `${Math.round(Audio.volume * 100)}%`)
                font.weight: 500
            }

            CustomMouseArea {
                Layout.fillWidth: true
                implicitHeight: Tokens.padding.normal * 3

                onWheel: event => {
                    if (event.angleDelta.y > 0)
                        Audio.incrementVolume();
                    else if (event.angleDelta.y < 0)
                        Audio.decrementVolume();
                }

                StyledSlider {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    implicitHeight: parent.implicitHeight

                    value: Audio.volume
                    onMoved: Audio.setVolume(value)

                    Behavior on value {
                        Anim {}
                    }
                }
            }

            AudioStreamsMixer {
                Layout.fillWidth: true
            }

            IconTextButton {
                Layout.fillWidth: true
                Layout.topMargin: Tokens.spacing.normal
                inactiveColour: Colours.palette.m3primaryContainer
                inactiveOnColour: Colours.palette.m3onPrimaryContainer
                verticalPadding: Tokens.padding.small
                text: qsTr("Open settings")
                icon: "settings"

                onClicked: root.popouts.detachRequested("audio")
            }
        }
    }
}
