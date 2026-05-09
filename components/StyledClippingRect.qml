pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import Quickshell
import Quickshell.Widgets

Item {
    id: root

    property bool contentUnderBorder: false
    property bool contentInsideBorder: !root.contentUnderBorder
    property alias antialiasing: rectangle.antialiasing
    property alias color: shader.backgroundColor
    property clippingRectangleBorder border
    property alias radius: rectangle.radius
    property alias topLeftRadius: rectangle.topLeftRadius
    property alias topRightRadius: rectangle.topRightRadius
    property alias bottomLeftRadius: rectangle.bottomLeftRadius
    property alias bottomRightRadius: rectangle.bottomRightRadius
    default property alias data: contentItem.data
    property alias children: contentItem.children
    readonly property alias contentItem: contentItem

    readonly property real dpr: (QsWindow.window as QsWindow)?.devicePixelRatio ?? Screen.devicePixelRatio ?? 1
    readonly property size offscreenTextureSize: Qt.size(Math.max(1, Math.ceil(width * dpr)), Math.max(1, Math.ceil(height * dpr)))

    Rectangle {
        id: rectangle

        anchors.fill: root
        color: "#ffff0000"
        border.color: "#ff00ff00"
        border.pixelAligned: root.border.pixelAligned
        border.width: root.border.width

        layer.enabled: true
        layer.textureSize: root.offscreenTextureSize
        visible: false
    }

    Item {
        id: contentItemContainer

        anchors.fill: root

        Item {
            id: contentItem

            anchors.fill: parent
            anchors.margins: root.contentInsideBorder ? root.border.width : 0
        }
    }

    ShaderEffectSource {
        id: shaderSource

        hideSource: true
        sourceItem: contentItemContainer
        textureSize: root.offscreenTextureSize
    }

    ShaderEffect {
        id: shader

        anchors.fill: root
        fragmentShader: `qrc:/Quickshell/Widgets/shaders/cliprect${root.contentUnderBorder ? "-ub" : ""}.frag.qsb`
        property Rectangle rect: rectangle
        property color backgroundColor: "white"
        property color borderColor: root.border.color
        property ShaderEffectSource content: shaderSource
    }

    Behavior on color {
        CAnim {}
    }
}
