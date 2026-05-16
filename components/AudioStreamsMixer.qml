import QtQuick
import QtQuick.Layouts
import Caelestia.Config
import qs.components
import qs.components.controls
import qs.services

ColumnLayout {
    id: root

    SectionHeader {
        title: qsTr("Applications")
        description: qsTr("Control volume for individual applications")
    }

    SectionContainer {
        contentSpacing: Tokens.spacing.normal

        ColumnLayout {
            Layout.fillWidth: true
            spacing: Tokens.spacing.small

            Repeater {
                model: Audio.streams
                Layout.fillWidth: true

                delegate: ColumnLayout {
                    required property var modelData
                    required property int index

                    Layout.fillWidth: true
                    spacing: Tokens.spacing.smaller

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Tokens.spacing.normal

                        MaterialIcon {
                            text: "apps"
                            font.pointSize: Tokens.font.size.normal
                            fill: 0
                        }

                        StyledText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            text: Audio.getStreamName(modelData)
                            font.pointSize: Tokens.font.size.normal
                            font.weight: 500
                        }

                        StyledInputField {
                            id: streamVolumeInput

                            Layout.preferredWidth: 70
                            validator: IntValidator {
                                bottom: 0
                                top: 100
                            }
                            enabled: !Audio.getStreamMuted(modelData)

                            Component.onCompleted: {
                                text = Math.round(Audio.getStreamVolume(modelData) * 100).toString();
                            }

                            onTextEdited: text => {
                                if (hasFocus) {
                                    const val = parseInt(text);
                                    if (!isNaN(val) && val >= 0 && val <= 100)
                                        Audio.setStreamVolume(modelData, val / 100);
                                }
                            }

                            onEditingFinished: {
                                const val = parseInt(text);
                                if (isNaN(val) || val < 0 || val > 100)
                                    text = Math.round(Audio.getStreamVolume(modelData) * 100).toString();
                            }

                            Connections {
                                function onAudioChanged() {
                                    if (!streamVolumeInput.hasFocus && modelData?.audio)
                                        streamVolumeInput.text = Math.round(modelData.audio.volume * 100).toString();
                                }

                                target: modelData
                            }
                        }

                        StyledText {
                            text: "%"
                            color: Colours.palette.m3outline
                            font.pointSize: Tokens.font.size.normal
                            opacity: Audio.getStreamMuted(modelData) ? 0.5 : 1
                        }

                        StyledRect {
                            implicitWidth: implicitHeight
                            implicitHeight: streamMuteIcon.implicitHeight + Tokens.padding.normal * 2

                            radius: Tokens.rounding.normal
                            color: Audio.getStreamMuted(modelData) ? Colours.palette.m3secondary : Colours.palette.m3secondaryContainer

                            StateLayer {
                                onClicked: Audio.setStreamMuted(modelData, !Audio.getStreamMuted(modelData))
                            }

                            MaterialIcon {
                                id: streamMuteIcon

                                anchors.centerIn: parent
                                text: Audio.getStreamMuted(modelData) ? "volume_off" : "volume_up"
                                color: Audio.getStreamMuted(modelData) ? Colours.palette.m3onSecondary : Colours.palette.m3onSecondaryContainer
                            }
                        }
                    }

                    StyledSlider {
                        Layout.fillWidth: true
                        implicitHeight: Tokens.padding.normal * 3

                        value: Audio.getStreamVolume(modelData)
                        enabled: !Audio.getStreamMuted(modelData)
                        opacity: enabled ? 1 : 0.5
                        onMoved: {
                            Audio.setStreamVolume(modelData, value);
                            if (!streamVolumeInput.hasFocus)
                                streamVolumeInput.text = Math.round(value * 100).toString();
                        }

                        Connections {
                            function onAudioChanged() {
                                if (modelData?.audio)
                                    value = modelData.audio.volume;
                            }

                            target: modelData
                        }
                    }
                }
            }

            StyledText {
                Layout.fillWidth: true
                visible: Audio.streams.length === 0
                text: qsTr("No applications currently playing audio")
                color: Colours.palette.m3outline
                font.pointSize: Tokens.font.size.small
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
