pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
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

    readonly property bool isWorkspace: true // Flag for finding workspace children
    // Unanimated prop for others to use as reference
    readonly property int size: implicitHeight + (hasWindows ? Tokens.padding.small : 0)

    readonly property int ws: groupOffset + index + 1
    readonly property bool isOccupied: occupied[ws] ?? false
    readonly property bool hasWindows: isOccupied && Config.bar.workspaces.showWindows
    readonly property string displayName: {
        const ws = Hypr.workspaces.values.find(w => w.id === root.ws);
        const wsName = !ws || ws.name == root.ws ? root.ws : ws.name[0];
        let name = wsName.toString();
        if (Config.bar.workspaces.capitalisation.toLowerCase() === "upper") {
            name = name.toUpperCase();
        } else if (Config.bar.workspaces.capitalisation.toLowerCase() === "lower") {
            name = name.toLowerCase();
        }
        return name;
    }
    readonly property string defaultLabel: Config.bar.workspaces.label || displayName
    readonly property string occupiedLabel: Config.bar.workspaces.occupiedLabel === "" ? "" : (Config.bar.workspaces.occupiedLabel || defaultLabel)
    readonly property string activeLabel: Config.bar.workspaces.activeLabel || (root.isOccupied ? occupiedLabel : defaultLabel)
    readonly property string indicatorText: root.activeWsId === root.ws ? activeLabel : root.isOccupied ? occupiedLabel : defaultLabel
    readonly property bool hasIndicator: indicatorText.length > 0

    Layout.alignment: Qt.AlignHCenter
    Layout.preferredHeight: size

    spacing: 0

    StyledText {
        id: indicator

        Layout.alignment: Qt.AlignHCenter | Qt.AlignTop
        Layout.preferredHeight: root.hasIndicator ? Tokens.sizes.bar.innerWidth - Tokens.padding.small * 2 : 0

        visible: root.hasIndicator

        animate: true
        text: root.indicatorText
        color: Config.bar.workspaces.occupiedBg || root.isOccupied || root.activeWsId === root.ws ? Colours.palette.m3onSurface : Colours.layer(Colours.palette.m3outlineVariant, 2)
        verticalAlignment: Qt.AlignVCenter
    }

    Item {
        Layout.preferredHeight: !root.hasIndicator && root.hasWindows ? Tokens.padding.small : 0
    }

    Loader {
        id: windows

        asynchronous: true

        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: true
        Layout.topMargin: root.hasIndicator ? -Tokens.sizes.bar.innerWidth / 10 : 0

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
                        const ws = root.ws;
                        const windows = Hypr.toplevels.values.filter(c => c.workspace?.id === ws);
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

    Behavior on Layout.preferredHeight {
        Anim {}
    }
}
