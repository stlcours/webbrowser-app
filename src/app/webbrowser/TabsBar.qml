/*
 * Copyright 2015 Canonical Ltd.
 *
 * This file is part of webbrowser-app.
 *
 * webbrowser-app is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 3.
 *
 * webbrowser-app is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Ubuntu.Components 1.0
import ".."

Item {
    id: root

    property alias model: repeater.model

    property real minTabWidth: 0 //units.gu(6)
    property real maxTabWidth: units.gu(20)
    property real tabWidth: model ? Math.max(Math.min(width / model.count, maxTabWidth), minTabWidth) : 0

    property bool incognito: false

    Repeater {
        id: repeater

        delegate: Item {
            id: tabDelegate
            anchors {
                top: parent ? parent.top : undefined
                bottom: parent ? parent.bottom : undefined
            }
            width: tabWidth

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                onPressed: {
                    if (mouse.button === Qt.LeftButton) {
                        root.model.currentIndex = index
                    }
                }
                onReleased: {
                    if (mouse.button === Qt.MiddleButton) {
                        internal.closeTab(index)
                    }
                }
                // XXX: should not start a drag when middle button was pressed
                drag {
                    target: tabDelegate
                    axis: Drag.XAxis
                    minimumX: 0
                    maximumX: root.width - tabDelegate.width
                }
            }

            readonly property string assetPrefix: (index == root.model.currentIndex) ? "assets/tab-active" : "assets/tab-inactive"

            Image {
                id: tabBackgroundLeft
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: parent.left
                }
                source: "%1-left.png".arg(assetPrefix)
            }

            Image {
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    left: tabBackgroundLeft.right
                    right: tabBackgroundRight.left
                }
                source: "%1-center.png".arg(assetPrefix)
                fillMode: Image.TileHorizontally
            }

            Image {
                id: tabBackgroundRight
                anchors {
                    top: parent.top
                    bottom: parent.bottom
                    right: parent.right
                }
                source: "%1-right.png".arg(assetPrefix)
            }

            Row {
                anchors {
                    left: parent.left
                    right: parent.right
                    margins: units.gu(1.5)
                    verticalCenter: parent.verticalCenter
                }
                spacing: units.gu(1)

                Favicon {
                    id: favicon
                    source: model.icon
                    shouldCache: !incognito
                }

                Label {
                    fontSize: "small"
                    text: model.title ? model.title : (model.url.toString() ? model.url : i18n.tr("New tab"))
                    elide: Text.ElideRight
                    width: parent.width - favicon.width - closeIcon.width - parent.spacing * 2
                }

                Icon {
                    id: closeIcon
                    name: "close"
                    width: units.gu(1.5)
                    height: units.gu(1.5)
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        onClicked: internal.closeTab(index)
                    }
                }
            }

            Binding on x {
                when: !mouseArea.drag.active
                value: index * width
            }

            Behavior on x { NumberAnimation { duration: 250 } }

            onXChanged: {
                if (!mouseArea.drag.active) return
                if (x < (index * width - width / 2)) {
                    root.model.move(index, index - 1)
                } else if ((x > (index * width + width / 2)) && (index < (root.model.count - 1))) {
                    root.model.move(index + 1, index)
                }
            }

            z: (root.model.currentIndex == index) ? 2 : 1 - index / root.model.count
        }
    }

    QtObject {
        id: internal

        function closeTab(index) {
            root.model.remove(index)
        }
    }
}
