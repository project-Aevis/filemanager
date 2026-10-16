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
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import FishUI 1.0 as FishUI

Item {
    id: control

    property alias text: searchInput.text
    property string placeholderText: qsTr("Search")

    signal accepted()
    signal cleared()
    signal escapePressed()

    implicitHeight: 28
    implicitWidth: searchInput.activeFocus || searchInput.text.length > 0 ? 210 : 160

    Behavior on implicitWidth {
        NumberAnimation { duration: 150; easing.type: Easing.OutQuad }
    }

    function forceFocus() {
        searchInput.forceActiveFocus()
        searchInput.selectAll()
    }

    function clear() {
        searchInput.text = ""
        control.cleared()
    }

    Rectangle {
        anchors.fill: parent
        radius: 8
        color: FishUI.Theme.darkMode ? Qt.rgba(1, 1, 1, 0.1) : Qt.rgba(0, 0, 0, 0.06)
        border.width: searchInput.activeFocus ? 2 : 1
        border.color: searchInput.activeFocus ? FishUI.Theme.highlightColor
                                             : (FishUI.Theme.darkMode ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.08))
        antialiasing: true

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            spacing: 6

            FishUI.IconItem {
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                source: "edit-find"
                color: searchInput.activeFocus ? FishUI.Theme.highlightColor : FishUI.Theme.disabledTextColor
            }

            TextInput {
                id: searchInput
                Layout.fillWidth: true
                font.pointSize: 9
                color: FishUI.Theme.textColor
                selectByMouse: true
                clip: true

                Text {
                    anchors.fill: parent
                    text: control.placeholderText
                    color: FishUI.Theme.disabledTextColor
                    font.pointSize: searchInput.font.pointSize
                    verticalAlignment: Text.AlignVCenter
                    visible: !searchInput.text && !searchInput.activeFocus
                }

                onAccepted: control.accepted()

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Escape) {
                        control.clear()
                        control.escapePressed()
                        event.accepted = true
                    }
                }
            }

            Item {
                Layout.preferredWidth: 14
                Layout.preferredHeight: 14
                visible: searchInput.text.length > 0

                Text {
                    anchors.centerIn: parent
                    text: "×"
                    font.pixelSize: 13
                    font.bold: true
                    color: clearMouse.containsMouse ? FishUI.Theme.textColor : FishUI.Theme.disabledTextColor
                }

                MouseArea {
                    id: clearMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        control.clear()
                        searchInput.forceActiveFocus()
                    }
                }
            }
        }
    }
}
