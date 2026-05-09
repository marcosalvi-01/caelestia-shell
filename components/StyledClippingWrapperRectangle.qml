import QtQuick
import Quickshell.Widgets

StyledClippingWrapperRectangleInternal {
    id: root

    property alias margin: manager.margin
    property alias extraMargin: manager.extraMargin
    property alias topMargin: manager.topMargin
    property alias bottomMargin: manager.bottomMargin
    property alias leftMargin: manager.leftMargin
    property alias rightMargin: manager.rightMargin
    property alias resizeChild: manager.resizeChild
    property alias implicitWidth: manager.implicitWidth
    property alias implicitHeight: manager.implicitHeight
    property alias child: manager.child

    border.width: 0

    __implicitWidthInternal: root.contentItem.implicitWidth + (root.contentInsideBorder ? root.border.width * 2 : 0)
    __implicitHeightInternal: root.contentItem.implicitHeight + (root.contentInsideBorder ? root.border.width * 2 : 0)

    MarginWrapperManager {
        id: manager
    }
}
