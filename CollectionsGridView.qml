// BigScreenFE Theme
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/

import QtQuick 2.15
import QtGraphicalEffects 1.15

FocusScope {
    id: root

    signal prevTabRequested()
    signal nextTabRequested()
    signal exitRequested()
    signal collectionSelected(var collection)

    property bool lightTheme: false
    property string lastNavDirection: "right"
    property bool preloadEnabled: false
    property var collectionCoverCache: ({})

    readonly property var currentCollection: grid.currentItem ? grid.currentItem.entry : null
    readonly property int currentIndex: grid.currentIndex
    readonly property real contentY: grid.contentY

    readonly property color _textPrimary: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _dimOverlay: lightTheme ? Qt.rgba(1,1,1,0.90) : Qt.rgba(0,0,0,0.90)
    readonly property color _fallbackBg: lightTheme ? "#c8cdd5" : "#1a1a1a"
    readonly property color _selectionBorder: lightTheme ? "#0d1117" : "#c7c7c7"

    readonly property int columns: 6
    readonly property real cellWidth: Math.floor(width / columns)
    readonly property real cellHeight: Math.max(0, Math.floor(height / 3.0))
    readonly property real collageTilt: -45

    ConsoleColors { id: consoleColors }

    function _getCoverUrls(col) {
        if (!col || !col.games) return []
            var key = col.shortName || col.name || ""
            var cached = root.collectionCoverCache[key]
            if (cached !== undefined) return cached
                var gm = col.games
                var urls = []
                var limit = Math.min(gm.count || 0, 24)
                for (var i = 0; i < limit && urls.length < 4; i++) {
                    var g = gm.get(i)
                    if (g && g.assets && g.assets.boxFront)
                        urls.push(g.assets.boxFront)
                }
                root.collectionCoverCache[key] = urls
                return urls
    }

    function restoreIndex() {
        var saved = api.memory.get("gridIndex_collections")
        grid.currentIndex = (saved !== undefined && saved >= 0) ? saved : 0
    }

    GridView {
        id: grid

        anchors {
            top: parent.top; left: parent.left; right: parent.right; bottom: parent.bottom
            bottomMargin: vpx(10)
        }
        focus: true
        clip: false

        model: api.collections
        cellWidth: root.cellWidth
        cellHeight: root.cellHeight

        cacheBuffer: root.preloadEnabled
        ? root.cellHeight * (Math.ceil((api.collections.count || 0) / root.columns) + 2)
        : root.cellHeight

        flickDeceleration: 1500
        maximumFlickVelocity: 2500

        delegate: Item {
            id: cell

            width: root.cellWidth
            height: root.cellHeight

            property var entry: modelData
            property bool isCurrent: GridView.isCurrentItem

            property string consoleColor: {
                if (!entry || !entry.name) return root._fallbackBg
                    var sn = entry.shortName || entry.name.toLowerCase()
                    return consoleColors.data[sn] || root._fallbackBg
            }
            property string systemLogoUrl: {
                if (!entry || !entry.name) return ""
                    var sn = entry.shortName || entry.name.toLowerCase()
                    return "assets/systems/" + sn + ".png"
            }
            property string coverLabel: entry ? (entry.name || "") : ""

            readonly property var coverUrls: entry ? root._getCoverUrls(entry) : []

            Item {
                id: glowSource
                anchors.fill: parent; anchors.margins: vpx(10)
                visible: false
                Rectangle {
                    anchors.fill: parent
                    color: cell.consoleColor
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Image {
                    anchors.centerIn: parent
                    width: parent.width * 0.65; height: parent.height * 0.65
                    source: cell.systemLogoUrl
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true; mipmap: true
                    sourceSize.width: width; sourceSize.height: height
                }
            }
            FastBlur {
                anchors.fill: glowSource; anchors.margins: vpx(-15)
                source: glowSource; radius: 75; transparentBorder: true
                opacity: cell.isCurrent && grid.activeFocus ? 0.40 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            Item {
                id: cover
                anchors.fill: parent; anchors.margins: vpx(10)
                clip: true

                Rectangle {
                    anchors.fill: parent
                    color: cell.consoleColor
                    visible: cell.coverUrls.length === 0
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Item {
                    id: mosaic
                    readonly property int cellsPerSide: 3
                    readonly property real side: Math.max(cover.width, cover.height) * 1.9
                    readonly property real tileSlot: side / cellsPerSide
                    readonly property real tileGap: 0.10
                    readonly property real tileSize: tileSlot * (1.0 - tileGap)

                    width: side; height: side
                    anchors.centerIn: parent
                    rotation: root.collageTilt
                    visible: cell.coverUrls.length > 0

                    layer.enabled: true
                    layer.smooth: true

                    Repeater {
                        model: mosaic.cellsPerSide * mosaic.cellsPerSide
                        delegate: Item {
                            readonly property int col: index % mosaic.cellsPerSide
                            readonly property int row: Math.floor(index / mosaic.cellsPerSide)

                            x: col * mosaic.tileSlot + (mosaic.tileSlot - width) / 2
                            y: row * mosaic.tileSlot + (mosaic.tileSlot - height) / 2
                            width: mosaic.tileSize
                            height: mosaic.tileSize

                            Rectangle {
                                anchors.fill: parent
                                color: Qt.darker(cell.consoleColor, 1.3)
                                antialiasing: true
                            }
                            Image {
                                anchors.fill: parent
                                source: cell.coverUrls.length > 0
                                ? cell.coverUrls[index % cell.coverUrls.length]
                                : ""
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true; mipmap: true; smooth: true
                                sourceSize.width: Math.ceil(mosaic.tileSize)
                                sourceSize.height: Math.ceil(mosaic.tileSize)
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    color: cell.consoleColor
                    opacity: cell.coverUrls.length > 0 ? 0.5 : 0.85
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: parent.height * 0.6
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#00000000" }
                        GradientStop { position: 1.0; color: "#CC000000" }
                    }
                }
            }

            Image {
                anchors.centerIn: cover
                width: cover.width * 0.65; height: cover.height * 0.65
                source: cell.systemLogoUrl
                fillMode: Image.PreserveAspectFit
                asynchronous: true; mipmap: true
                visible: cell.coverUrls.length === 0
                opacity: 0.6; z: 1
            }

            Text {
                anchors {
                    left: cover.left; right: cover.right; bottom: cover.bottom
                    leftMargin: vpx(6); rightMargin: vpx(6); bottomMargin: vpx(8)
                }
                text: cell.coverLabel
                color: "white"
                font.family: global.fonts.sans; font.pixelSize: vpx(12)
                wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
                style: Text.Outline; styleColor: "#2a2a2a"
                z: 2
            }

            Item {
                id: gameCountOverlay
                anchors.fill: cover
                visible: cell.isCurrent && grid.activeFocus
                z: 3
                clip: true

                Rectangle {
                    id: dimmingBg
                    anchors.fill: parent
                    color: "#B3000000"
                    opacity: 0.0
                    Behavior on opacity { NumberAnimation { duration: 250 } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Column {
                    id: gameCountColumn
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: vpx(2)
                    property real offsetX: 0
                    transform: Translate { x: gameCountColumn.offsetX }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: cell.entry && cell.entry.games ? "( " + cell.entry.games.count + " )" : ""
                        color: "white"
                        font.family: global.fonts.condensed
                        font.pixelSize: vpx(38); font.bold: true
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "GAMES"
                        color: "white"
                        font.family: global.fonts.condensed
                        font.pixelSize: vpx(18); font.bold: true
                        font.letterSpacing: vpx(2)
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                SequentialAnimation {
                    id: slideAnim
                    running: false
                    property real fromX: 0
                    property real exitX: 0

                    function startForDirection(dir) {
                        slideAnim.stop()
                        dimmingBg.opacity = 0.0
                        var travel = cover.width / 2 + gameCountColumn.width / 2 + vpx(20)
                        if (dir === "left") { fromX = -travel; exitX = travel }
                        else { fromX = travel; exitX = -travel }
                        gameCountColumn.offsetX = fromX
                        dimmingBg.opacity = 0.55
                        slideAnim.restart()
                    }

                    NumberAnimation { target: gameCountColumn; property: "offsetX"; to: 0; duration: 400; easing.type: Easing.OutCubic }
                    PauseAnimation { duration: 1000 }
                    NumberAnimation { target: gameCountColumn; property: "offsetX"; to: slideAnim.exitX; duration: 400; easing.type: Easing.InCubic }
                    onStopped: { if (!gameCountOverlay.visible) return; dimmingBg.opacity = 0.0 }
                }

                onVisibleChanged: {
                    if (visible) {
                        slideAnim.startForDirection(root.lastNavDirection)
                    } else {
                        slideAnim.stop()
                        dimmingBg.opacity = 0.0
                        gameCountColumn.offsetX = 0
                    }
                }
            }

            Rectangle {
                id: selectionRect
                anchors.fill: cover
                property real borderExtra: 0
                anchors.margins: vpx(-3.5) - borderExtra
                border.width: vpx(1.5) + borderExtra
                color: "transparent"
                border.color: root._selectionBorder
                opacity: 0
                Behavior on border.color { ColorAnimation { duration: 200 } }

                SequentialAnimation on opacity {
                    running: cell.isCurrent && grid.activeFocus
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.8; duration: 600; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutQuad }
                    onStopped: selectionRect.opacity = 0
                }
                SequentialAnimation on borderExtra {
                    id: borderPulse
                    running: false
                    NumberAnimation { to: vpx(3.5); duration: 150; easing.type: Easing.OutQuad }
                    NumberAnimation { to: 0; duration: 250; easing.type: Easing.InQuad }
                }
            }

            scale: cell.isCurrent && grid.activeFocus ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 120 } }

            onIsCurrentChanged: {
                if (cell.isCurrent && grid.activeFocus) {
                    borderPulse.restart()
                    api.memory.set("gridIndex_collections", grid.currentIndex)
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: { grid.currentIndex = index; grid.forceActiveFocus() }
                onDoubleClicked: { if (cell.entry) root.collectionSelected(cell.entry) }
            }
        }

        Keys.onLeftPressed: { root.lastNavDirection = "left"; event.accepted = false }
        Keys.onRightPressed: { root.lastNavDirection = "right"; event.accepted = false }

        Keys.onDownPressed: {
            var next = grid.currentIndex + root.columns
            grid.currentIndex = next >= grid.count ? grid.count - 1 : next
            event.accepted = true
        }

        Keys.onPressed: {
            if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                event.accepted = true
                if (grid.currentItem && grid.currentItem.entry)
                    root.collectionSelected(grid.currentItem.entry)
                    return
            }
            if (api.keys.isCancel(event)) { event.accepted = true; root.exitRequested(); return }
            if (api.keys.isPrevPage(event)) { event.accepted = true; root.prevTabRequested(); return }
            if (api.keys.isNextPage(event)) { event.accepted = true; root.nextTabRequested(); return }
        }
    }
}
