// BigScreenFE Theme
// Copyright (C) 2026 Gonzalo
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/

import QtQuick 2.15
import QtGraphicalEffects 1.15
import SortFilterProxyModel 0.2
import "Utils.js" as Utils

FocusScope {
    id: root

    signal prevTabRequested()
    signal nextTabRequested()
    signal exitRequested()
    signal sortMenuRequested()
    signal openHub(var game)

    property var gamesModel: api.allGames
    property bool isCollections: false
    property bool inCollectionGames: false
    property var activeCollectionGames: null
    property string activeCollectionName: ""
    readonly property var currentEntry: grid.currentItem ? grid.currentItem.entry : null
    readonly property bool showingGames: !isCollections || inCollectionGames
    property string currentSortId: "alpha_asc"
    property bool preserveSourceOrder: false
    property bool lightTheme: false

    property string lastNavDirection: "right"
    property bool _restoringIndex: false

    readonly property color _textPrimary: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _textSecondary: lightTheme ? "#5a6472" : "#7e848c"
    readonly property color _textMuted: lightTheme ? "#8b929a" : "#556677"
    readonly property color _badgeBg: lightTheme ? "#e2e8f0" : "#2b3034"
    readonly property color _badgeText: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _selectionBorder: lightTheme ? "#0d1117" : "#c7c7c7"
    readonly property color _dimOverlay: lightTheme ? Qt.rgba(1,1,1,0.90) : Qt.rgba(0,0,0,0.90)
    readonly property color _fallbackBg: lightTheme ? "#c8cdd5" : "#1a1a1a"
    readonly property color _emptyText: lightTheme ? "#5a6472" : "#555555"

    SortFilterProxyModel {
        id: sortProxy

        sourceModel: {
            if (!root.isCollections) return root.gamesModel
                if (root.inCollectionGames) return root.activeCollectionGames
                    return null
        }

        sorters: [
            RoleSorter { roleName: "sortBy"; sortOrder: Qt.AscendingOrder; enabled: !root.preserveSourceOrder && root.currentSortId === "alpha_asc" },
            RoleSorter { roleName: "sortBy"; sortOrder: Qt.DescendingOrder; enabled: !root.preserveSourceOrder && root.currentSortId === "alpha_desc" },
            RoleSorter { roleName: "rating"; sortOrder: Qt.DescendingOrder; enabled: !root.preserveSourceOrder && root.currentSortId === "rating_desc" },
            RoleSorter { roleName: "rating"; sortOrder: Qt.AscendingOrder; enabled: !root.preserveSourceOrder && root.currentSortId === "rating_asc" },
            RoleSorter { roleName: "playTime"; sortOrder: Qt.DescendingOrder; enabled: !root.preserveSourceOrder && root.currentSortId === "playtime_desc" },
            RoleSorter { roleName: "playTime"; sortOrder: Qt.AscendingOrder; enabled: !root.preserveSourceOrder && root.currentSortId === "playtime_asc" },
            RoleSorter { roleName: "releaseYear"; sortOrder: Qt.DescendingOrder; enabled: !root.preserveSourceOrder && root.currentSortId === "release_desc" },
            RoleSorter { roleName: "releaseYear"; sortOrder: Qt.AscendingOrder; enabled: !root.preserveSourceOrder && root.currentSortId === "release_asc" },
            RoleSorter { roleName: "players"; sortOrder: Qt.DescendingOrder; enabled: !root.preserveSourceOrder && root.currentSortId === "players_desc" }
        ]
    }

    property var effectiveModel: {
        if (root.isCollections && !root.inCollectionGames) return api.collections
            if (sortProxy.sourceModel !== null) return sortProxy
                return root.gamesModel
    }

    onIsCollectionsChanged: {
        inCollectionGames = false
        activeCollectionGames = null
        if (isCollections) {
            Qt.callLater(function() {
                var saved = api.memory.get("gridIndex_collections")
                grid.currentIndex = (saved !== undefined) ? saved : 0
            })
        } else {
            api.memory.unset("gridIndex_collections")
            grid.currentIndex = 0
        }
    }

    onGamesModelChanged: {
        inCollectionGames = false
        if (!root.isCollections) grid.currentIndex = 0
    }

    function toggleFavorite() {
        if (currentEntry && showingGames) currentEntry.favorite = !currentEntry.favorite
    }
    function launchCurrent() {
        if (grid.currentItem) activateEntry(grid.currentItem.entry)
    }

    function saveIndex() {
        var key = "gridIndex_" + collecBar.currentShortName
        api.memory.set(key, grid.currentIndex)
    }

    function restoreIndex() {
        var key = "gridIndex_" + collecBar.currentShortName
        var saved = api.memory.get(key)
        grid.currentIndex = (saved !== undefined) ? saved : 0
    }

    readonly property int columns: 6
    readonly property real cellWidth: Math.floor(width / columns)
    readonly property bool showingCollectionList: isCollections && !inCollectionGames
    readonly property real gridAvailableHeight: height
    readonly property real cellHeight: showingCollectionList ? Math.floor(gridAvailableHeight / 3.0) : Math.floor(cellWidth * 1.4)

    readonly property real contentY: grid.contentY

    ConsoleColors { id: consoleColors }

    GridView {
        id: grid

        anchors {
            top: parent.top; left: parent.left; right: parent.right; bottom: parent.bottom
            bottomMargin: vpx(10)
        }
        focus: true
        clip: false

        model: root.effectiveModel
        cellWidth: root.cellWidth
        cellHeight: root.cellHeight

        flickDeceleration: 1500
        maximumFlickVelocity: 2500

        delegate: Item {
            id: cell
            width: root.cellWidth
            height: root.cellHeight

            property var entry: modelData
            property bool isCurrent: GridView.isCurrentItem

            readonly property bool isGame: !root.showingCollectionList

            readonly property string sortBadgeText: {
                if (root.preserveSourceOrder || !isGame || !entry) return ""
                    var sid = root.currentSortId
                    if (sid === "alpha_asc") return ""
                        if (sid === "alpha_desc") return "Z→A"
                            if (sid === "rating_desc" || sid === "rating_asc")
                                return Math.round((entry.rating || 0) * 100) + "%"
                                if (sid === "playtime_desc" || sid === "playtime_asc") {
                                    var secs = entry.playTime || 0
                                    var h = Math.floor(secs / 3600)
                                    var m = Math.floor((secs % 3600) / 60)
                                    var s = secs % 60
                                    return (h < 10 ? "0" + h : "" + h) + ":" + (m < 10 ? "0" + m : "" + m) + ":" + (s < 10 ? "0" + s : "" + s)
                                }
                                if (sid === "release_desc" || sid === "release_asc") {
                                    var y = entry.releaseYear || 0
                                    return y > 0 ? "" + y : ""
                                }
                                if (sid === "players_desc") {
                                    var p = entry.players || 1
                                    return "" + p
                                }
                                return ""
            }

            property string consoleColor: {
                if (!root.showingCollectionList) return _fallbackBg
                    if (!entry || !entry.name) return _fallbackBg
                        var sn = entry.shortName || entry.name.toLowerCase()
                        return consoleColors.data[sn] || _fallbackBg
            }
            property string systemLogoUrl: {
                if (!root.showingCollectionList) return ""
                    if (!entry || !entry.name) return ""
                        var sn = entry.shortName || entry.name.toLowerCase()
                        return "assets/systems/" + sn + ".png"
            }
            property string coverUrl: {
                if (root.isCollections && !root.inCollectionGames)
                    return entry.assets.background || entry.assets.boxFront || ""
                    return entry.assets.boxFront || ""
            }
            property string coverLabel: {
                if (root.isCollections && !root.inCollectionGames) return entry.name
                    return entry.title
            }

            Item {
                id: glowSource
                anchors.fill: parent; anchors.margins: vpx(10)
                visible: false
                Rectangle {
                    anchors.fill: parent
                    color: cell.consoleColor
                    visible: root.showingCollectionList
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Image {
                    anchors.centerIn: parent; width: parent.width * 0.65; height: parent.height * 0.65
                    source: cell.systemLogoUrl; fillMode: Image.PreserveAspectFit
                    asynchronous: true; mipmap: true; visible: root.showingCollectionList
                }
                Image {
                    anchors.fill: parent; source: cell.coverUrl
                    fillMode: Image.PreserveAspectCrop; asynchronous: true; mipmap: true
                    visible: !root.showingCollectionList
                }
            }
            FastBlur {
                id: glowBlur
                anchors.fill: glowSource; anchors.margins: vpx(-15)
                source: glowSource; radius: 75; transparentBorder: true
                opacity: cell.isCurrent && grid.activeFocus ? 0.40 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            Image {
                id: cover
                anchors.fill: parent; anchors.margins: vpx(10)
                source: cell.coverUrl; fillMode: Image.PreserveAspectCrop
                asynchronous: true; mipmap: true

                Rectangle {
                    anchors.fill: parent
                    color: root.showingCollectionList ? cell.consoleColor : _fallbackBg
                    visible: cover.status !== Image.Ready
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Text {
                    anchors.centerIn: parent
                    width: parent.width - vpx(12)
                    visible: !root.showingCollectionList && cover.status !== Image.Ready
                    text: cell.coverLabel
                    color: _textPrimary
                    font.family: global.fonts.sans
                    font.pixelSize: vpx(11)
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    style: Text.Outline
                    styleColor: lightTheme ? "#ffffff" : "#000000"
                    z: 1
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Image {
                id: systemLogo
                anchors.centerIn: cover; width: cover.width * 0.65; height: cover.height * 0.65
                source: cell.systemLogoUrl; fillMode: Image.PreserveAspectFit
                asynchronous: true; mipmap: true
                visible: root.showingCollectionList; opacity: 0.6; z: 1
            }

            Text {
                anchors {
                    left: cover.left; right: cover.right; bottom: cover.bottom
                    leftMargin: vpx(6); rightMargin: vpx(6); bottomMargin: vpx(8)
                }
                visible: root.showingCollectionList
                text: cell.coverLabel
                color: "white"
                font.family: global.fonts.sans; font.pixelSize: vpx(12)
                wrapMode: Text.WordWrap; horizontalAlignment: Text.AlignHCenter
                style: Text.Outline; styleColor: "#2a2a2a"
                z: 2
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Item {
                id: gameCountOverlay
                anchors.fill: cover
                visible: root.showingCollectionList && cell.isCurrent && grid.activeFocus
                z: 3
                clip: true

                Rectangle {
                    id: dimmingBg
                    anchors.fill: parent
                    color: _dimOverlay
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
                        text: entry && entry.games ? entry.games.count : ""
                        color: _textPrimary
                        font.family: global.fonts.condensed
                        font.pixelSize: vpx(38)
                        font.bold: true
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "GAMES"
                        color: _textPrimary
                        font.family: global.fonts.condensed
                        font.pixelSize: vpx(18)
                        font.bold: true
                        font.letterSpacing: vpx(2)
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }

                SequentialAnimation {
                    id: slideAnim
                    running: false

                    property real fromX: vpx(120)
                    property real exitX: vpx(-120)

                    function startForDirection(dir) {
                        slideAnim.stop()
                        dimmingBg.opacity = 0.0

                        if (dir === "left") { fromX = vpx(-120); exitX = vpx(120) }
                        else { fromX = vpx(120); exitX = vpx(-120) }

                        gameCountColumn.offsetX = fromX
                        dimmingBg.opacity = 0.55
                        slideAnim.restart()
                    }

                    NumberAnimation { target: gameCountColumn; property: "offsetX"; to: 0; duration: 400; easing.type: Easing.OutCubic }
                    PauseAnimation { duration: 1000 }
                    NumberAnimation { target: gameCountColumn; property: "offsetX"; to: slideAnim.exitX; duration: 400; easing.type: Easing.InCubic }

                    onStopped: {
                        if (!gameCountOverlay.visible) return
                            dimmingBg.opacity = 0.0
                    }
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

            Item {
                id: favBadge
                readonly property bool sortActive: cell.sortBadgeText !== ""

                anchors {
                    right: cover.right
                    rightMargin: vpx(2)
                    bottom: sortActive ? sortBadge.top : cover.bottom
                    bottomMargin: sortActive ? vpx(4) : vpx(2)
                }

                width: vpx(32); height: vpx(32)
                visible: cell.isGame && cell.entry && cell.entry.favorite === true

                Behavior on anchors.bottomMargin { NumberAnimation { duration: 150; easing.type: Easing.OutQuad } }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.rgba(0,0,0,0.70)
                }
                Item {
                    anchors.centerIn: parent
                    width: vpx(25); height: vpx(25)
                    Image {
                        id: favIconSrc
                        anchors.fill: parent
                        source: "assets/icons/favorite.svg"
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: parent
                        source: favIconSrc
                        color: "#00ff08"
                    }
                }
            }

            Item {
                id: sortBadge
                anchors { left: cover.left; right: cover.right; bottom: cover.bottom }
                height: vpx(34)
                visible: cell.sortBadgeText !== ""

                Rectangle {
                    anchors.fill: parent
                    color: _badgeBg
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Text {
                    id: sortBadgeLabel
                    anchors.centerIn: parent
                    text: cell.sortBadgeText
                    color: _badgeText
                    font.family: global.fonts.sans
                    font.pixelSize: vpx(16)
                    font.bold: true
                    font.letterSpacing: vpx(0.3)
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Rectangle {
                id: selectionRect
                anchors.fill: cover
                property real borderExtra: 0
                anchors.margins: vpx(-3.5) - borderExtra
                border.width: vpx(1.5) + borderExtra
                color: "transparent"
                border.color: _selectionBorder
                radius: 0
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

            onIsCurrentChanged: {
                if (cell.isCurrent && grid.activeFocus) {
                    borderPulse.restart()
                    if (root.isCollections && !root._restoringIndex) {
                        if (root.inCollectionGames) {
                            api.memory.set("gridIndex_" + root.activeCollectionName, grid.currentIndex)
                        } else {
                            api.memory.set("gridIndex_collections", grid.currentIndex)
                        }
                    }
                }
            }

            scale: cell.isCurrent && grid.activeFocus ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 120 } }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    grid.currentIndex = index
                    grid.forceActiveFocus()
                }
                onDoubleClicked: root.activateEntry(cell.entry)
            }
        }

        Keys.onDownPressed: {
            var next = grid.currentIndex + root.columns
            grid.currentIndex = next >= grid.count ? grid.count - 1 : next
            event.accepted = true
        }

        Keys.onLeftPressed: { root.lastNavDirection = "left"; event.accepted = false }
        Keys.onRightPressed: { root.lastNavDirection = "right"; event.accepted = false }

        Keys.onPressed: {
            if (!event.isAutoRepeat && api.keys.isAccept(event)) { event.accepted = true; if (grid.currentItem) root.activateEntry(grid.currentItem.entry); return }
            if (api.keys.isDetails(event) && root.showingGames) { event.accepted = true; root.toggleFavorite(); return }
            if (api.keys.isCancel(event)) {
                event.accepted = true
                if (root.isCollections && root.inCollectionGames) {
                    api.memory.set("gridIndex_" + root.activeCollectionName, grid.currentIndex)
                    var savedIdx = api.memory.get("gridIndex_collections")
                    root._restoringIndex = true
                    root.inCollectionGames = false
                    root.activeCollectionGames = null
                    grid.currentIndex = (savedIdx !== undefined) ? savedIdx : 0
                    Qt.callLater(function() { root._restoringIndex = false })
                } else {
                    root.exitRequested()
                }
                return
            }
            if (api.keys.isPrevPage(event)) { event.accepted = true; root.prevTabRequested(); return }
            if (api.keys.isNextPage(event)) { event.accepted = true; root.nextTabRequested(); return }
            if (api.keys.isFilters(event) && root.showingGames) { event.accepted = true; root.sortMenuRequested(); return }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: grid.count === 0 && !root.showingCollectionList
        text: "No games here yet"
        color: _emptyText
        font.family: global.fonts.sans
        font.pixelSize: vpx(18)
        Behavior on color { ColorAnimation { duration: 200 } }
    }

    function activateEntry(entry) {
        if (!entry) return
            if (root.isCollections && !root.inCollectionGames) {
                if (!entry.games || entry.games.count === 0) return
                    api.memory.set("gridIndex_collections", grid.currentIndex)
                    root.activeCollectionName = entry.name
                    root.activeCollectionGames = entry.games
                    root.inCollectionGames = true
                    var saved = api.memory.get("gridIndex_" + entry.name)
                    grid.currentIndex = (saved !== undefined) ? saved : 0
            } else {
                root.openHub(entry)
            }
    }
}
