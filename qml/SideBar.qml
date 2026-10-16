/*
 * Copyright (C) 2021 CutefishOS Team.
 * Copyright (C) 2026 Project Aevis Contributors.
 *
 * Author:     revenmartin <revenmartin@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import QtQuick 2.12 as Quick
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Window 2.12

import FishUI 1.0 as FishUI
import Cutefish.FileManager 1.0

Item {
    id: sideBar

    implicitWidth: 210

    property string title
    // macOS Window Controls Spacer
    property alias titleItem: windowControlsSpacer
    property alias currentIndex: listView.currentIndex
    property alias count: listView.count
    property alias model: listView.model
    property string selectedPath
    property int dropIndex: -1
    property real dropY: 0
    property real pointerY: 0

    signal clicked(string path)
    signal openInNewWindow(string path)
    signal openInNewTab(string path)

    Fm {
        id: _fm
    }

    PlacesModel {
        id: placesModel
        onFavoritesChanged: sideBar.updateSelection(sideBar.selectedPath)
        onDeviceSetupDone: sideBar.clicked(filePath)    // 设备挂载上后，模拟点击了该设备以打开该页面
    }

    Rectangle {
        anchors.fill: parent
        color: FishUI.Theme.darkMode
               ? Qt.rgba(0.10, 0.10, 0.14, FishUI.Theme.blurEnabled ? 0.76 : 0.98)
               : Qt.rgba(0.95, 0.95, 0.97, FishUI.Theme.blurEnabled ? 0.72 : 0.98)

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.Linear
            }
        }

        Rectangle {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 1
            color: FishUI.Theme.glassBorderColor
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // macOS Window Controls Spacer
        Item {
            id: windowControlsSpacer
            Layout.fillWidth: true
            Layout.preferredHeight: root.header.height
        }

        ListView {
            id: listView
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.topMargin: FishUI.Units.smallSpacing
            clip: true
            model: placesModel
            header: Label {
                width: listView.width
                height: listView.snap(30)
                leftPadding: listView.sideInset + FishUI.Units.smallSpacing
                verticalAlignment: Text.AlignVCenter
                text: qsTr("Favorites")
                color: FishUI.Theme.disabledTextColor
                font.pointSize: 8
                font.bold: true
            }

            // Rounding to whole *logical* pixels is not enough at a fractional scale:
            // at 150% a 37px row pitch is 55.5 device px, so every other row lands on
            // a half pixel and its icon is resampled.
            readonly property real dpr: FishUI.Dpi.ratio
            function snap(v) {
                return Math.round(v * listView.dpr) / listView.dpr
            }

            FishUI.WheelHandler {
                target: listView
            }

            // Not leftMargin/rightMargin: Qt rounds the content item's position to a
            // whole logical pixel, so a snapped fractional margin never takes effect.
            // The inset is applied inside the rows instead.
            readonly property real sideInset: listView.snap(FishUI.Units.smallSpacing * 1.5)

            bottomMargin: listView.snap(FishUI.Units.smallSpacing)
            spacing: listView.snap(3)

            ScrollBar.vertical: ScrollBar {
                bottomPadding: FishUI.Units.smallSpacing
            }

            section.property: "category"
            section.delegate: Label {
                width: ListView.view.width
                height: section === qsTr("Favorites") ? 0 : listView.snap(32)
                // ListView controls delegate visibility, including zero-height sections.
                text: section === qsTr("Favorites") ? "" : section
                leftPadding: listView.snap(listView.sideInset + FishUI.Units.smallSpacing)
                rightPadding: FishUI.Units.smallSpacing
                verticalAlignment: Text.AlignVCenter
                color: FishUI.Theme.disabledTextColor
                font.pointSize: 8
                font.bold: true
            }

            delegate: Item {
                id: _item
                width: ListView.view.width
                height: listView.snap(Math.max(34, FishUI.Units.fontMetrics.height + 12))

                property bool checked: sideBar.currentIndex === index
                opacity: _mouseArea.drag.active ? 0.45 : 1
                property color hoveredColor: FishUI.Theme.darkMode ? Qt.lighter(FishUI.Theme.backgroundColor, 1.1)
                                                                 : Qt.darker(FishUI.Theme.backgroundColor, 1.1)
                MouseArea {
                    id: _mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    drag.target: index < placesModel.favoriteCount ? dragProxy : null
                    drag.axis: Drag.YAxis
                    onPressed: function(mouse) {
                        if (mouse.button === Qt.LeftButton) {
                            dragProxy.favoriteRow = index
                            dragProxy.x = mouse.x
                            dragProxy.y = _item.mapToItem(sideBar, mouse.x, mouse.y).y
                        }
                    }
                    onReleased: {
                        if (drag.active)
                            dragProxy.Drag.drop()
                        sideBar.dropIndex = -1
                    }
                    onCanceled: {
                        dragProxy.Drag.cancel()
                        sideBar.dropIndex = -1
                    }
                    onPositionChanged: function(mouse) {
                        if (drag.active)
                            dragProxy.y = _item.mapToItem(sideBar, mouse.x, mouse.y).y
                    }
                    onClicked: function(mouse) {
                        if (mouse.button === Qt.LeftButton) {
                            if (model.isDevice && model.setupNeeded)
                                placesModel.requestSetup(index)
                            else
                                sideBar.clicked(model.path ? model.path : model.url)
                        } else if (mouse.button === Qt.RightButton) {
                            _menu.popup()
                        }
                    }
                }

                Connections {
                    target: _mouseArea.drag
                    function onActiveChanged() {
                        dragProxy.dragging = _mouseArea.drag.active
                    }
                }

                FishUI.DesktopMenu {
                    id: _menu

                    FishUI.MenuItem {
                        text: qsTr("Open")

                        onTriggered: {
                            if (model.isDevice && model.setupNeeded)
                                placesModel.requestSetup(index)
                            else
                                sideBar.clicked(model.path ? model.path : model.url)
                        }
                    }

                    FishUI.MenuItem {
                        text: qsTr("Open in new window")

                        onTriggered: {
                            sideBar.openInNewWindow(model.path ? model.path : model.url)
                        }
                    }

                    FishUI.MenuItem {
                        text: qsTr("Open In New Tab")
                        enabled: !model.isDevice || !model.setupNeeded
                        onTriggered: sideBar.openInNewTab(model.path ? model.path : model.url)
                    }

                    FishUI.MenuSeparator {
                        visible: index < placesModel.favoriteCount
                    }

                    FishUI.MenuItem {
                        text: qsTr("Remove from Favorites")
                        visible: index < placesModel.favoriteCount
                        onTriggered: placesModel.removeFavorite(index)
                    }

                    FishUI.MenuSeparator {
                        Layout.fillWidth: true
                        visible: _ejectMenuItem.visible || _umountMenuItem.visible
                    }

                    FishUI.MenuItem {
                        id: _ejectMenuItem
                        text: qsTr("Eject")
                        visible: model.isDevice &&
                                 !model.setupNeeded &&
                                 model.isOpticalDisc &&
                                 !model.url.toString() === _fm.rootPath()

                        onTriggered: {
                            placesModel.requestEject(index)
                        }
                    }

                    FishUI.MenuItem {
                        id: _umountMenuItem
                        text: qsTr("Unmount")
                        visible: model.isDevice &&
                                 !model.setupNeeded &&
                                 !model.isOpticalDisc &&
                                 !model.url.toString() === _fm.rootPath()

                        onTriggered: {
                            placesModel.requestTeardown(index)
                        }
                    }
                }

                Rectangle {
                    x: listView.sideInset
                    width: _item.width - listView.sideInset * 2
                    height: parent.height
                    radius: 8
                    antialiasing: true
                    color: {
                        if (checked)
                            return FishUI.Theme.highlightColor
                        else if (_mouseArea.pressed)
                            return FishUI.Theme.darkMode ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(0, 0, 0, 0.08)
                        else if (_mouseArea.containsMouse)
                            return FishUI.Theme.darkMode ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.04)
                        else
                            return "transparent"
                    }
                }

                // Snap icon coordinates as well as size for fractional display scales.
                FishUI.IconItem {
                    id: _icon
                    x: listView.snap(listView.sideInset + FishUI.Units.smallSpacing)
                    y: listView.snap((_item.height - height) / 2)
                    width: listView.snap(20)
                    height: width

                    source: model.iconName
                    color: checked ? "#FFFFFF" : FishUI.Theme.textColor
                }

                Label {
                    id: _label
                    x: listView.snap(_icon.x + _icon.width + FishUI.Units.smallSpacing)
                    y: listView.snap((_item.height - height) / 2)
                    width: _item.width - x - listView.snap(FishUI.Units.smallSpacing)
                    text: model.name
                    color: checked ? "#FFFFFF" : FishUI.Theme.textColor
                    font.weight: checked ? Font.DemiBold : Font.Normal
                    elide: Text.ElideRight
                }
            }
        }
    }

    Item {
        id: dragProxy
        width: 1
        height: 1
        property int favoriteRow: -1
        property bool dragging: false
        Drag.active: dragging
        Drag.source: dragProxy
        Drag.supportedActions: Qt.MoveAction
    }

    Quick.DropArea {
        id: favoritesDrop
        anchors.fill: parent
        z: 10
        property bool internalDrag: false
        onEntered: function(drag) {
            internalDrag = drag.source === dragProxy
            drag.accepted = internalDrag || (drag.hasUrls && placesModel.canAddFavorites(drag.urls))
            if (drag.accepted)
                sideBar.positionDrop(drag.y)
        }
        onPositionChanged: function(drag) {
            sideBar.positionDrop(drag.y)
        }
        onExited: sideBar.dropIndex = -1
        onDropped: function(drop) {
            if (sideBar.dropIndex < 0)
                return
            var accepted = internalDrag
                    ? placesModel.moveFavorite(dragProxy.favoriteRow, sideBar.dropIndex)
                    : placesModel.addFavorites(drop.urls, sideBar.dropIndex)
            if (accepted)
                drop.accept(internalDrag ? Qt.MoveAction : Qt.CopyAction)
            sideBar.dropIndex = -1
        }
    }

    Rectangle {
        z: 11
        visible: sideBar.dropIndex >= 0
        x: listView.sideInset + FishUI.Units.smallSpacing
        y: sideBar.dropY - height / 2
        width: sideBar.width - x - listView.sideInset
        height: listView.snap(2)
        color: FishUI.Theme.highlightColor
        radius: height / 2
        Rectangle {
            x: -3
            anchors.verticalCenter: parent.verticalCenter
            width: 6
            height: 6
            radius: 3
            color: FishUI.Theme.highlightColor
        }
    }

    Timer {
        interval: 30
        repeat: true
        running: favoritesDrop.containsDrag
        onTriggered: {
            var localY = sideBar.pointerY - listView.y
            var delta = localY < 32 ? -6 : localY > listView.height - 32 ? 6 : 0
            if (delta !== 0) {
                var minimum = listView.originY
                var maximum = Math.max(minimum, listView.contentHeight - listView.height + listView.originY)
                listView.contentY = Math.max(minimum, Math.min(maximum, listView.contentY + delta))
                sideBar.positionDrop(sideBar.pointerY)
            }
        }
    }

    function positionDrop(y) {
        pointerY = y
        var count = placesModel.favoriteCount
        var contentY = y - listView.y + listView.contentY
        var boundary = listView.headerItem.y + listView.headerItem.height
        dropIndex = count
        for (var i = 0; i < count; ++i) {
            var item = listView.itemAtIndex(i)
            if (!item)
                continue
            if (contentY < item.y + item.height / 2) {
                dropIndex = i
                boundary = item.y
                break
            }
            boundary = item.y + item.height
        }
        dropY = listView.y + boundary - listView.contentY
        if (contentY > boundary + 24 || dropY < listView.y || dropY > listView.y + listView.height)
            dropIndex = -1
    }

    function updateSelection(path) {
        selectedPath = path
        listView.currentIndex = -1

        for (var i = 0; i < listView.count; ++i) {
            if (path === listView.model.get(i).path ||
                    path === listView.model.get(i).url) {
                listView.currentIndex = i
                break
            }
        }
    }
}
