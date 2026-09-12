pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import M3Shapes
import Caelestia.Config
import qs.components
import qs.services
import qs.utils

ColumnLayout {
    id: root

    required property int index
    required property int activeWsId
    required property var occupied
    required property int groupOffset
    required property bool shouldShow

    required property Repeater workspaceRepeater
    required property real layoutSpacing

    readonly property bool isWorkspace: true // Flag for finding workspace children
    // Unanimated prop for others to use as reference
    readonly property int size: implicitHeight + (hasWindows ? Tokens.padding.extraSmall : 0)

    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows && (Config.bar.workspaces.maxWindowIcons > 0)
    readonly property bool focused: activeWsId === ws
    readonly property bool isText: Config.bar.workspaces.displayType === BarWorkspaceDisplay.Text
    readonly property list<int> focusedShapeList: [MaterialShape.Slanted, MaterialShape.Oval, MaterialShape.Pill, MaterialShape.Triangle, MaterialShape.Arrow, MaterialShape.Diamond, MaterialShape.Pentagon, MaterialShape.Gem, MaterialShape.VerySunny, MaterialShape.Sunny, MaterialShape.Cookie4Sided, MaterialShape.Cookie6Sided, MaterialShape.Cookie7Sided, MaterialShape.Cookie9Sided, MaterialShape.Cookie12Sided, MaterialShape.Clover4Leaf, MaterialShape.SoftBurst, MaterialShape.Ghostish]

    readonly property real revealProgress: Math.max(0, Math.min(1, reveal))
    readonly property bool revealTransitionRunning: revealAnimation.running
    readonly property real precedingRevealProgress: {
        let progress = 0;

        for (let i = 0; i < index; ++i) {
            const workspace = workspaceRepeater.itemAt(i) as Workspace;
            if (workspace)
                progress = Math.max(progress, workspace.revealProgress);
        }

        return progress;
    }
    readonly property real targetY: {
        let offset = 0;

        for (let i = 0; i < index; ++i) {
            const workspace = workspaceRepeater.itemAt(i) as Workspace;
            if (workspace?.shouldShow)
                offset += workspace.size + layoutSpacing;
        }

        return offset;
    }

    property real reveal: shouldShow ? 1 : 0
    property real animatedSize: size

    readonly property string displayName: {
        const ws = Hypr.workspaces.values.find(w => w.id === root.ws);
        const wsName = !ws || ws.name == root.ws ? root.ws : ws.name[0];
        let name = wsName.toString();
        if (Config.bar.workspaces.capitalisation === BarWorkspaceCapitalisation.Upper) {
            name = name.toUpperCase();
        } else if (Config.bar.workspaces.capitalisation === BarWorkspaceCapitalisation.Lower) {
            name = name.toLowerCase();
        }
        return name;
    }
    readonly property string defaultLabel: Config.bar.workspaces.label || displayName
    readonly property string occupiedLabel: Config.bar.workspaces.occupiedLabel === "" ? "" : (Config.bar.workspaces.occupiedLabel || defaultLabel)
    readonly property string activeLabel: Config.bar.workspaces.activeLabel === "" ? "" : (Config.bar.workspaces.activeLabel || defaultLabel)
    readonly property string indicatorText: root.isOccupied ? occupiedLabel : (root.activeWsId === root.ws ? activeLabel : defaultLabel)
    readonly property bool hasIndicator: indicatorText.length > 0

    function updateShape(): void {
        const shape = indicator.item as MaterialShape;
        if (!shape)
            return;

        if (focused)
            shape.shape = focusedShapeList[Math.floor(Math.random() * focusedShapeList.length)];
        else
            shape.shape = Qt.binding(() => isOccupied ? MaterialShape.Square : MaterialShape.Circle);
    }

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredHeight: animatedSize * revealProgress
    Layout.topMargin: layoutSpacing * Math.min(revealProgress, precedingRevealProgress)

    visible: shouldShow || revealProgress > 0
    opacity: revealProgress
    clip: true

    spacing: 0

    onFocusedChanged: updateShape()
    Component.onCompleted: updateShape()

    Loader {
        id: indicator

        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        Layout.preferredHeight: root.isText && !root.hasIndicator ? 0 : Tokens.sizes.bar.innerWidth - Tokens.padding.small
        visible: !root.isText || root.hasIndicator
        sourceComponent: Config.bar.workspaces.displayType === BarWorkspaceDisplay.Text ? textComponent : shapeComponent

        onItemChanged: root.updateShape()
    }

    Component {
        id: shapeComponent

        MaterialShape {
            implicitSize: Tokens.sizes.bar.innerWidth - Tokens.padding.small

            color: Config.bar.workspaces.occupiedBg || root.isOccupied || root.focused ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)
            scale: root.focused ? 2 / 3 : root.isOccupied ? 1 / 3 : 1 / 4

            animationEasing: Tokens.anim.expressiveDefaultSpatial
            animationDuration: Tokens.anim.durations.expressiveDefaultSpatial * Tokens.anim.durations.scale

            Behavior on color {
                CAnim {}
            }

            Behavior on scale {
                Anim {}
            }
        }
    }

    Component {
        id: textComponent

        StyledText {
            animate: true
            text: root.indicatorText
            color: Config.bar.workspaces.occupiedBg || root.isOccupied || root.focused ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)
            verticalAlignment: Qt.AlignVCenter
            font.family: Tokens.font.workspaces
        }
    }

    Item {
        Layout.preferredHeight: !root.hasIndicator && root.hasWindows ? Tokens.padding.small : 0
    }

    Loader {
        id: windows

        asynchronous: true

        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: true
        Layout.topMargin: root.isText ? (root.hasIndicator ? -Tokens.sizes.bar.innerWidth / 10 : 0) : -Tokens.spacing.extraSmall / 2

        visible: active
        active: root.hasWindows

        sourceComponent: Column {
            spacing: 0

            add: Transition {
                Anim {
                    properties: "scale"
                    from: 0
                    to: 1
                    easing: Tokens.anim.standardDecel
                }
            }

            move: Transition {
                Anim {
                    properties: "scale"
                    to: 1
                    easing: Tokens.anim.standardDecel
                }
                Anim {
                    properties: "x,y"
                }
            }

            Repeater {
                model: ScriptModel {
                    values: {
                        const windows = Hypr.toplevelsForWs(root.ws);
                        const maxIcons = root.Config.bar.workspaces.maxWindowIcons;
                        return maxIcons > 0 ? windows.slice(0, maxIcons) : windows;
                    }
                }

                MaterialIcon {
                    required property var modelData

                    grade: 0
                    text: Icons.getAppCategoryIcon(modelData.lastIpcObject.class, "terminal")
                    color: Colours.palette.m3onSurfaceVariant
                }
            }
        }
    }

    Behavior on animatedSize {
        Anim {}
    }

    Behavior on reveal {
        Anim {
            id: revealAnimation

            type: Anim.DefaultEffects
        }
    }
}
