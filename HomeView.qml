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

    signal goToLibrary()
    signal focusSearchRequested()
    signal openHub(var game)
    signal openRA(var game, string raGameId)

    property bool lightTheme: false

    readonly property var currentGame: _strip.currentIndex < _recentCount ? _getGame(_strip.currentIndex) : null
    readonly property bool onViewMore: _strip.currentIndex >= _recentCount
    readonly property bool onViewMoreFocused: _strip.activeFocus && (_strip.currentIndex >= _recentCount)
    readonly property bool raStripFocused: _raStrip.activeFocus

    property real _savedScrollY: 0
    property bool _returningFromRA: false

    function saveScrollForRA() {
        _savedScrollY = _scroller.contentY;
    }

    function restoreScrollFromRA() {
        _returningFromRA = true;
        _scroller.contentY = _savedScrollY;
        _returningFromRA = false;
        _raStrip.forceActiveFocus();
    }
    readonly property string currentTitle: currentGame ? currentGame.title : ""
    readonly property string currentPlaytime: currentGame ? Utils.formatPlayTime(currentGame.playTime) : ""
    readonly property string currentLastPlayed: currentGame ? Utils.formatLastPlayed(currentGame.lastPlayed) : ""

    readonly property var recCurrentGame: {
        if (_recStrip.activeFocus && root._recGames.length > 0)
            return root._recGames[_recStrip.currentIndex] || null;
        return null;
    }

    readonly property string _bgSrc: {
        if (_recStrip.activeFocus) {
            var rg = root.recCurrentGame;
            return rg ? (rg.assets.background || rg.assets.screenshot || "") : "";
        }
        var g = root.currentGame;
        return g ? (g.assets.background || g.assets.screenshot || "") : "";
    }

    SortFilterProxyModel {
        id: _recentSrc
        sourceModel: api.allGames
        filters: ExpressionFilter {
            expression: {
                var d = model.lastPlayed;
                return d instanceof Date && !isNaN(d.getTime());
            }
        }
        sorters: RoleSorter { roleName: "lastPlayed"; sortOrder: Qt.DescendingOrder }
    }

    readonly property int _recentCount: 3
    readonly property int _totalSlots: _recentCount + 1
    property var _recentGames: []

    function _rebuildCache() {
        var arr = [];
        var usedTitles = {};
        var recentLimit = Math.min(_recentSrc.count, 3);
        for (var i = 0; i < recentLimit; i++) {
            var proxy = _recentSrc.get(i);
            if (!proxy) continue;
            for (var j = 0; j < api.allGames.count; j++) {
                var g = api.allGames.get(j);
                if (g && g.title === proxy.title && String(g.lastPlayed) === String(proxy.lastPlayed)) {
                    arr.push(g);
                    usedTitles[g.title] = true;
                    break;
                }
            }
        }

        for (var k = 0; k < api.allGames.count && arr.length < 3; k++) {
            var fg = api.allGames.get(k);
            if (fg && !usedTitles[fg.title]) {
                arr.push(fg);
                usedTitles[fg.title] = true;
            }
        }

        _recentGames = arr;
    }

    function _getGame(idx) {
        if (idx < 0 || idx >= _recentGames.length) return null;
        return _recentGames[idx];
    }

    property var _recGames: []
    property var _recReasons: []
    readonly property string _raApiKey: api.memory.has("ra_api_key") ? api.memory.get("ra_api_key") : ""
    readonly property string _raUser: api.memory.has("ra_api_user") ? api.memory.get("ra_api_user") : ""
    property var _raRecentGames: []
    property bool _raLoading: false

    function _loadRARecent() {
        _raLoading = true;
        var xhr = new XMLHttpRequest();
        var url = "https://retroachievements.org/API/API_GetUserRecentlyPlayedGames.php"
        + "?y=" + _raApiKey + "&u=" + _raUser + "&c=4";
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            _raLoading = false;
            if (xhr.status !== 200) return;
            try {
                var arr = JSON.parse(xhr.responseText);
                if (!Array.isArray(arr)) return;
                var result = [];
                for (var i = 0; i < arr.length && i < 4; i++) {
                    var g = arr[i];
                    result.push({
                        title: g.Title || "",
                        consoleName: g.ConsoleName || "",
                        imgIcon: g.ImageIcon ? "https://media.retroachievements.org" + g.ImageIcon : "",
                        imgTitle: g.ImageTitle ? "https://media.retroachievements.org" + g.ImageTitle : "",
                        raGameId: String(g.GameID || ""),
                                numAch: parseInt(g.NumAchievements) || 0,
                                numEarned: parseInt(g.NumAchievementsEarned) || 0,
                                pctWon: parseFloat(g.PctWon) || 0.0,
                                lastPlayed: g.LastPlayed || ""
                    });
                }
                _raRecentGames = result;
            } catch(e) { console.log("RA parse error:", e); }
        };
        xhr.send();
    }

    function _buildRecommended() {
        var total = api.allGames.count;
        if (total === 0) { _recGames = []; _recReasons = []; return; }

        var now = new Date();
        var oneWeekMs = 7 * 24 * 60 * 60 * 1000;

        var refGenres = {};
        var refCollections = {};
        var recentTitles = {};

        for (var j = 0; j < total; j++) {
            var pg = api.allGames.get(j);
            if (!pg || pg.playCount <= 0) continue;

            var pgl = pg.genreList;
            for (var pgi = 0; pgi < pgl.length; pgi++)
                refGenres[pgl[pgi].toLowerCase()] = true;
            var pcl = pg.collections;
            for (var pci = 0; pci < pcl.count; pci++) {
                var pc = pcl.get(pci);
                if (pc) refCollections[pc.name] = true;
            }

            var lp = pg.lastPlayed;
            if (lp instanceof Date && !isNaN(lp.getTime())) {
                if ((now - lp) < oneWeekMs)
                    recentTitles[pg.title] = true;
            }
        }

        var hasRef = Object.keys(refGenres).length > 0 || Object.keys(refCollections).length > 0;

        var poolPlayed = [];
        var poolFavorites = [];
        var poolOther = [];

        for (var i = 0; i < total; i++) {
            var g2 = api.allGames.get(i);
            if (!g2 || recentTitles[g2.title]) continue;

            var score = g2.rating * 10;
            var reason = "";

            var hasPlayTime = g2.playTime > 60;
            var hasPlayCount = g2.playCount > 0;

            if (g2.playCount >= 20) {
                reason = "A true classic for you";
                score += 12;
            } else if (g2.playCount >= 10) {
                reason = "You really loved this";
                score += 10;
            } else if (g2.playCount >= 5) {
                reason = "An old favorite";
                score += 8;
            } else if (g2.playCount >= 2) {
                reason = "Remember this one?";
                score += 6;
            } else if (g2.playCount === 1) {
                reason = "You played this once";
                score += 4;
            }

            if (!hasPlayCount && hasPlayTime) {
                var mins = Math.floor(g2.playTime / 60);
                if (mins >= 60) {
                    reason = "You spent time on this";
                    score += 7;
                } else if (mins >= 10) {
                    reason = "You gave this a try";
                    score += 5;
                } else {
                    reason = "You started this once";
                    score += 3;
                }
            }

            if (hasRef && !reason) {
                var ggl = g2.genreList;
                for (var ggi = 0; ggi < ggl.length; ggi++) {
                    if (refGenres[ggl[ggi].toLowerCase()]) {
                        score += 8;
                        reason = "Based on your taste";
                        break;
                    }
                }
                var gcl = g2.collections;
                for (var gci = 0; gci < gcl.count; gci++) {
                    var gc = gcl.get(gci);
                    if (gc && refCollections[gc.name]) {
                        score += 4;
                        if (!reason) reason = "From your library";
                        break;
                    }
                }
            }

            if (g2.favorite) {
                score += 2;
                if (!reason) reason = "In your favorites";
            }

            if (g2.assets.background || g2.assets.banner) score += 1;
            if (g2.rating >= 0.8 && !reason) reason = "Highly rated";
            if (!reason) reason = "Try something new";

            score += Math.random() * 10;

            var entry = { game: g2, score: score, reason: reason };

            if (hasPlayCount || hasPlayTime) {
                poolPlayed.push(entry);
            } else if (g2.favorite) {
                poolFavorites.push(entry);
            } else {
                poolOther.push(entry);
            }
        }

        poolPlayed.sort(function(a, b) { return b.score - a.score; });
        poolFavorites.sort(function(a, b) { return b.score - a.score; });
        poolOther.sort(function(a, b) { return b.score - a.score; });

        var result = [];
        var reasons = [];

        for (var pi = 0; pi < poolPlayed.length && result.length < 3; pi++) {
            result.push(poolPlayed[pi].game);
            reasons.push(poolPlayed[pi].reason);
        }

        var rest = poolOther.concat(poolFavorites);
        rest.sort(function(a, b) { return b.score - a.score; });

        var favUsed = 0;
        for (var ri = 0; ri < rest.length && result.length < 4; ri++) {
            var isUnplayedFav = !rest[ri].game.playCount && !rest[ri].game.playTime && rest[ri].game.favorite;
            if (isUnplayedFav) {
                if (favUsed >= 1) continue;
                favUsed++;
            }
            result.push(rest[ri].game);
            reasons.push(rest[ri].reason);
        }

        _recGames = result;
        _recReasons = reasons;
    }

    function resetFocus() {
        _strip.currentIndex = 0;
        _strip.forceActiveFocus();
    }

    Component.onCompleted: { _rebuildCache(); _buildRecommended(); _loadRARecent(); }
    Connections {
        target: _recentSrc
        function onCountChanged() { root._rebuildCache(); root._buildRecommended(); }
    }

    Timer {
        id: deferredInit
        interval: 100
        running: true
        onTriggered: {
            _rebuildCache();
            _buildRecommended();
            _loadRARecent();
        }
    }

    Image {
        id: _bgImg
        anchors.fill: parent
        source: root._bgSrc
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        visible: false
    }

    FastBlur {
        anchors.fill: _bgImg
        source: _bgImg
        radius: 60
        opacity: _bgImg.status === Image.Ready && _bgImg.source !== "" ? 1.0 : 0.0
        Behavior on opacity { NumberAnimation { duration: 400 } }
    }

    Rectangle { anchors.fill: parent; color: root.lightTheme ? "#dfe3e8" : "#0b1117"; z: -1; Behavior on color { ColorAnimation { duration: 400 } } }

    Rectangle {
        anchors.fill: parent
        color: root.lightTheme ? "#dfe3e8" : "#0b1117"
        opacity: root._bgSrc !== "" ? (root.lightTheme ? 0.72 : 0.55) : 1.0
        Behavior on color { ColorAnimation { duration: 400 } }
        Behavior on opacity { NumberAnimation { duration: 500 } }
    }

    Rectangle {
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: parent.height
        gradient: Gradient {
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.7; color: root.lightTheme ? "#dfe3e8" : "#0b1117" }
            GradientStop { position: 1.0; color: root.lightTheme ? "#dfe3e8" : "#0b1117" }
        }
    }

    Flickable {
        id: _scroller
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            topMargin: vpx(56)
            bottomMargin: vpx(48)
            leftMargin: vpx(40)
            rightMargin: vpx(40)
        }
        clip: false
        interactive: true
        flickableDirection: Flickable.VerticalFlick

        contentHeight: _content.implicitHeight

        Behavior on contentY { NumberAnimation { duration: 250; easing.type: Easing.OutQuad } }

        function ensureVisible(item) {
            var yTop = item.mapToItem(_content, 0, 0).y;
            var yBottom = yTop + item.height;
            var margin = vpx(20);
            if (yBottom + margin > contentY + height)
                contentY = yBottom + margin - height;
            else if (yTop - margin < contentY)
                contentY = Math.max(0, yTop - margin);
        }

        Connections {
            target: _recStrip
            function onActiveFocusChanged() {
                if (_recStrip.activeFocus)
                    _scroller.ensureVisible(_recStrip);
            }
        }
        Connections {
            target: _raStrip
            function onActiveFocusChanged() {
                if (_raStrip.activeFocus)
                    _scroller.ensureVisible(_raStrip);
            }
        }
        Connections {
            target: _strip
            function onActiveFocusChanged() {
                if (_strip.activeFocus && !root._returningFromRA)
                    _scroller.contentY = 0;
            }
        }

        Item {
            id: _content
            width: _scroller.width
            implicitHeight: {
                if (_raStrip.visible)
                    return _raStrip.y + _raStrip.height + vpx(20);
                if (_recStrip.visible)
                    return _recStrip.y + _recStrip.height + vpx(20);
                return _info.y + _info.height + vpx(20);
            }

            Text {
                id: _label
                anchors { top: parent.top; left: parent.left; topMargin: vpx(20) }
                text: "Recent Games"
                font.pixelSize: vpx(32)
                font.bold: true
                font.family: global.fonts.sans
                color: root.lightTheme ? "#0d1117" : "#ffffff"
                visible: _strip.currentIndex < Math.min(_recentSrc.count, 3)
                Behavior on color { ColorAnimation { duration: 400 } }
                Behavior on opacity { NumberAnimation { duration: 200 } }
                opacity: visible ? 0.9 : 0.0
            }

            ListView {
                id: _strip
                anchors {
                    top: _label.bottom
                    left: parent.left
                    right: parent.right
                    topMargin: vpx(14)
                }
                height: vpx(310)

                orientation: ListView.Horizontal
                spacing: vpx(16)
                clip: false
                focus: true
                interactive: false
                highlightMoveDuration: 0
                highlightRangeMode: ListView.NoHighlightRange
                Binding on contentX { value: 0 }

                model: root._totalSlots

                delegate: Item {
                    id: _cell

                    readonly property bool _isViewMore: index >= root._recentCount
                    readonly property bool isCurrent: ListView.isCurrentItem
                    readonly property var _game: root._getGame(index)
                    readonly property bool _isLarge: index === 0
                    readonly property real _cardW: _isLarge ? vpx(530) : vpx(210)

                    width: _cardW
                    height: _strip.height
                    scale: isCurrent && _strip.activeFocus ? 1.03 : 1.0
                    opacity: isCurrent ? 1.0 : (_strip.activeFocus ? 0.65 : 0.80)
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Image {
                        id: _art
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true
                        source: {
                            if (_cell._isViewMore) return "";
                            var g = _cell._game;
                            if (!g) return "";
                            if (_cell._isLarge)
                                return g.assets.background || g.assets.screenshot
                                || g.assets.banner || g.assets.steam
                                || g.assets.boxFront || "";
                            return g.assets.poster || g.assets.boxFront
                            || g.assets.screenshot || "";
                        }
                        Rectangle {
                            anchors.fill: parent
                            color: root.lightTheme ? "#c8cdd5" : "#1c2533"
                            visible: parent.status !== Image.Ready || _cell._isViewMore
                            Behavior on color { ColorAnimation { duration: 400 } }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: _cell.isCurrent && _strip.activeFocus
                        ? (root.lightTheme ? "#c5cad2" : "#16202b")
                        : (root.lightTheme ? "#d5dae2" : "#26282a")
                        visible: _cell._isViewMore
                        Behavior on color { ColorAnimation { duration: 200 } }
                        Column {
                            anchors.centerIn: parent
                            spacing: vpx(8)
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "View more\nin your\nLibrary"
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: vpx(22)
                                font.bold: true
                                font.family: global.fonts.sans
                                color: root.lightTheme ? "#0d1117" : "white"
                                lineHeight: 1.35
                                Behavior on color { ColorAnimation { duration: 400 } }
                            }
                        }
                    }

                    Item {
                        id: _glowSource
                        anchors.fill: parent
                        visible: false
                        Rectangle { anchors.fill: parent; color: _cell._isViewMore ? "#16202b" : "#1a1a1a" }
                        Image {
                            anchors.fill: parent; source: _art.source
                            fillMode: Image.PreserveAspectCrop; asynchronous: true; smooth: true
                            visible: !_cell._isViewMore
                        }
                    }

                    FastBlur {
                        anchors.fill: _glowSource
                        anchors.margins: vpx(-15)
                        source: _glowSource
                        radius: 75
                        transparentBorder: true
                        opacity: _cell.isCurrent && _strip.activeFocus ? 0.40 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }

                    Item {
                        anchors {
                            right: parent.right
                            top: parent.top
                            rightMargin: vpx(6)
                            topMargin: vpx(6)
                        }
                        width: vpx(26)
                        height: vpx(26)
                        visible: !_cell._isViewMore && (_cell._game ? _cell._game.favorite === true : false)

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            color: Qt.rgba(0, 0, 0, 0.70)
                        }
                        Image {
                            id: _favIcon
                            anchors.centerIn: parent
                            width: vpx(18); height: vpx(18)
                            source: "assets/icons/favorite.svg"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true; smooth: true
                            visible: false
                        }
                        ColorOverlay {
                            anchors.fill: _favIcon
                            source: _favIcon
                            color: "#00ff08"
                        }
                    }

                    Rectangle {
                        id: _selRect
                        anchors.fill: parent
                        property real borderExtra: 0
                        anchors.margins: vpx(-3.5) - borderExtra
                        border.width: vpx(1.5) + borderExtra
                        border.color: root.lightTheme ? "#05070a" : "#c7c7c7"

                        color: "transparent"
                        opacity: 0

                        SequentialAnimation on opacity {
                            running: _cell.isCurrent && _strip.activeFocus
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.8; duration: 600; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutQuad }
                            onStopped: _selRect.opacity = 0
                        }
                        SequentialAnimation on borderExtra {
                            id: _borderPulse; running: false
                            NumberAnimation { to: vpx(3.5); duration: 150; easing.type: Easing.OutQuad }
                            NumberAnimation { to: 0; duration: 250; easing.type: Easing.InQuad }
                        }
                    }

                    onIsCurrentChanged: { if (isCurrent && _strip.activeFocus) _borderPulse.restart(); }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: { _strip.currentIndex = index; _strip.forceActiveFocus(); }
                        onDoubleClicked: { if (_cell._isViewMore) root.goToLibrary(); else if (_cell._game) root.openHub(_cell._game); }
                    }
                }

                Keys.onLeftPressed: { if (currentIndex > 0) currentIndex--; event.accepted = true; }
                Keys.onRightPressed: { if (currentIndex < count - 1) currentIndex++; event.accepted = true; }
                Keys.onUpPressed: { event.accepted = true; root.focusSearchRequested(); }
                Keys.onDownPressed: {
                    event.accepted = true;
                    if (root._recGames.length > 0) _recStrip.forceActiveFocus();
                }

                Keys.onPressed: {
                    if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                        event.accepted = true;
                        if (root.onViewMore) root.goToLibrary();
                        else if (root.currentGame) root.openHub(root.currentGame);
                        return;
                    }
                    if (!event.isAutoRepeat && api.keys.isDetails(event)) {
                        event.accepted = true;
                        if (root.currentGame)
                            root.currentGame.favorite = !root.currentGame.favorite;
                        return;
                    }
                    if (api.keys.isNextPage(event)) {
                        event.accepted = true;
                        if (currentIndex < count - 1) currentIndex++;
                        return;
                    }
                    if (api.keys.isPrevPage(event)) {
                        event.accepted = true;
                        if (currentIndex > 0) currentIndex--;
                        return;
                    }
                    if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                        event.accepted = false
                    }
                }
            }

            Item {
                id: _info
                anchors { left: parent.left; top: _strip.bottom; topMargin: vpx(14) }
                width: vpx(460)
                height: vpx(52)

                Text {
                    id: _titleText
                    anchors { top: parent.top; left: parent.left }
                    text: root.onViewMore ? "Access your game library" : root.currentTitle
                    font.pixelSize: vpx(20)
                    font.bold: true
                    font.family: global.fonts.sans
                    color: root.lightTheme ? "#0d1117" : "#ffffff"
                    elide: Text.ElideRight
                    width: parent.width
                    Behavior on color { ColorAnimation { duration: 400 } }
                }

                Row {
                    anchors { top: _titleText.bottom; left: parent.left; topMargin: vpx(4) }
                    spacing: vpx(5)
                    visible: !root.onViewMore && (root.currentPlaytime !== "" || root.currentLastPlayed !== "")

                    Text {
                        text: "▶"; font.pixelSize: vpx(10); font.family: global.fonts.sans
                        color: root.lightTheme ? "#1a6b7a" : "#57cbde"
                        anchors.verticalCenter: parent.verticalCenter
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                    Text {
                        text: {
                            var lp = root.currentLastPlayed;
                            var pt = root.currentPlaytime;
                            if (lp !== "" && pt !== "") return lp + ": " + pt;
                            if (pt !== "") return "PLAYTIME: " + pt;
                            if (lp !== "") return lp;
                            return "";
                        }
                        font.pixelSize: vpx(12); font.bold: true
                        font.family: global.fonts.sans
                        color: root.lightTheme ? "#1a6b7a" : "#57cbde"
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                }
            }

            Text {
                id: _recLabel
                anchors { top: _info.bottom; left: parent.left; topMargin: vpx(28) }
                text: "Recommended"
                font.pixelSize: vpx(32)
                font.bold: true
                font.family: global.fonts.sans
                color: root.lightTheme ? "#0d1117" : "#ffffff"
                opacity: 0.95
                visible: root._recGames.length > 0
                Behavior on color { ColorAnimation { duration: 400 } }
            }

            ListView {
                id: _recStrip
                anchors {
                    top: _recLabel.bottom
                    left: parent.left
                    right: parent.right
                    topMargin: vpx(14)
                }
                height: vpx(260)
                visible: root._recGames.length > 0

                orientation: ListView.Horizontal
                spacing: vpx(16)
                clip: false
                focus: false
                interactive: false
                highlightMoveDuration: 0
                highlightRangeMode: ListView.NoHighlightRange
                Binding on contentX { value: 0 }

                model: root._recGames.length

                readonly property real cardW: (width - vpx(16) * 3) / 4
                readonly property real imgH: Math.round(height * 0.48)

                delegate: Item {
                    id: _rc

                    readonly property bool isCurrent: ListView.isCurrentItem
                    readonly property var _game: root._recGames[index] || null
                    readonly property string _reason: root._recReasons[index] || ""

                    width: _recStrip.cardW
                    height: _recStrip.height
                    scale: isCurrent && _recStrip.activeFocus ? 1.05 : 1.0
                    opacity: isCurrent ? 1.0 : (_recStrip.activeFocus ? 0.65 : 0.80)
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Item {
                        id: _rcImgArea
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: _recStrip.imgH
                        clip: false

                        Image {
                            id: _rcArt
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            smooth: true
                            source: {
                                var g = _rc._game;
                                if (!g) return "";
                                return g.assets.background || g.assets.screenshot
                                || g.assets.banner || g.assets.titlescreen || "";
                            }
                            Rectangle {
                                anchors.fill: parent; color: root.lightTheme ? "#c8cdd5" : "#1c2533"
                                visible: parent.status !== Image.Ready
                                Behavior on color { ColorAnimation { duration: 400 } }
                            }
                        }

                        Item {
                            anchors {
                                left: parent.left; right: parent.right; bottom: parent.bottom
                                leftMargin: vpx(8); rightMargin: vpx(8); bottomMargin: vpx(7)
                            }
                            height: vpx(36)

                            Image {
                                id: _rcLogo
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectFit
                                horizontalAlignment: Image.AlignLeft
                                verticalAlignment: Image.AlignVCenter
                                asynchronous: true
                                smooth: true
                                source: _rc._game ? (_rc._game.assets.logo || "") : ""
                                visible: status === Image.Ready && source !== ""
                            }

                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                text: _rc._game ? _rc._game.title : ""
                                font.pixelSize: vpx(12)
                                font.bold: true
                                font.family: global.fonts.sans
                                color: "#ffffff"
                                elide: Text.ElideRight
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                style: Text.Outline
                                styleColor: "#40000000"
                                visible: !_rcLogo.visible
                            }
                        }

                        Item {
                            anchors {
                                right: parent.right
                                top: parent.top
                                rightMargin: vpx(4)
                                topMargin: vpx(4)
                            }
                            width: vpx(26)
                            height: vpx(26)
                            visible: _rc._game ? (_rc._game.favorite === true) : false

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: Qt.rgba(0, 0, 0, 0.70)
                            }
                            Image {
                                id: _rcFavIcon
                                anchors.centerIn: parent
                                width: vpx(18); height: vpx(18)
                                source: "assets/icons/favorite.svg"
                                fillMode: Image.PreserveAspectFit
                                mipmap: true
                                visible: false
                            }
                            ColorOverlay {
                                anchors.fill: _rcFavIcon
                                source: _rcFavIcon
                                color: "#00ff08"
                            }
                        }
                    }

                    Rectangle {
                        id: _rcInfoPanel
                        anchors {
                            top: _rcImgArea.bottom
                            left: parent.left
                            right: parent.right
                            bottom: parent.bottom
                        }
                        color: root.lightTheme ? Qt.rgba(0.93, 0.95, 0.97, 0.97) : Qt.rgba(0.07, 0.10, 0.15, 0.96)
                        Behavior on color { ColorAnimation { duration: 400 } }

                        Column {
                            anchors {
                                left: parent.left
                                right: parent.right
                                top: parent.top
                                margins: vpx(8)
                                topMargin: vpx(6)
                            }
                            spacing: vpx(2)

                            Text {
                                width: parent.width
                                text: _rc._game ? _rc._game.title : ""
                                font.pixelSize: vpx(16)
                                font.bold: true
                                font.family: global.fonts.sans
                                color: root.lightTheme ? "#0d1117" : "#ffffff"
                                elide: Text.ElideRight
                                visible: _rcLogo.visible
                                Behavior on color { ColorAnimation { duration: 400 } }
                            }

                            Rectangle {
                                visible: _rc._reason !== ""
                                width: _reasonText.width + vpx(10)
                                height: vpx(17)
                                radius: vpx(3)
                                color: {
                                    var r = _rc._reason;
                                    if (root.lightTheme) {
                                        if (r === "In your favorites") return "#c8ecd4";
                                        if (r === "Based on your taste") return "#c8dce8";
                                        if (r === "Highly rated") return "#e8e0c0";
                                        return "#d4d8de";
                                    }
                                    if (r === "In your favorites") return "#1a3320";
                                    if (r === "Based on your taste") return "#1a2a3a";
                                    if (r === "Highly rated") return "#2a2010";
                                    return "#1a1f28";
                                }
                                Behavior on color { ColorAnimation { duration: 400 } }
                                Text {
                                    id: _reasonText
                                    anchors.centerIn: parent
                                    text: _rc._reason
                                    font.pixelSize: vpx(10)
                                    font.bold: true
                                    font.family: global.fonts.sans
                                    color: {
                                        var r = _rc._reason;
                                        if (r === "In your favorites") return "#00e676";
                                        if (r === "Based on your taste") return root.lightTheme ? "#1a6b7a" : "#57cbde";
                                        if (r === "Highly rated") return "#f5c518";
                                        return root.lightTheme ? "#5a6472" : "#7a8a94";
                                    }
                                    Behavior on color { ColorAnimation { duration: 400 } }
                                }
                            }

                            Text {
                                width: parent.width
                                text: _rc._game && _rc._game.developer !== "" ? _rc._game.developer : ""
                                font.pixelSize: vpx(12)
                                font.family: global.fonts.sans
                                color: root.lightTheme ? "#2a6080" : "#8ab4c8"
                                elide: Text.ElideRight
                                visible: text !== ""
                                Behavior on color { ColorAnimation { duration: 400 } }
                            }

                            Text {
                                width: parent.width
                                text: _rc._game && _rc._game.genre !== "" ? _rc._game.genre : ""
                                font.pixelSize: vpx(12)
                                font.family: global.fonts.sans
                                color: root.lightTheme ? "#5a6472" : "#7a8a94"
                                elide: Text.ElideRight
                                visible: text !== ""
                                Behavior on color { ColorAnimation { duration: 400 } }
                            }

                            Rectangle {
                                width: parent.width
                                height: vpx(1)
                                color: root.lightTheme ? "#22000000" : "#22ffffff"
                                Behavior on color { ColorAnimation { duration: 400 } }
                            }

                            Row {
                                width: parent.width
                                spacing: vpx(6)

                                Row {
                                    spacing: vpx(2)
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: _rc._game ? (_rc._game.rating > 0) : false

                                    Repeater {
                                        model: 5
                                        Item {
                                            width: vpx(16)
                                            height: vpx(16)
                                            anchors.verticalCenter: parent.verticalCenter

                                            Image {
                                                id: _starIcon
                                                anchors.fill: parent
                                                property real threshold: (index + 1) / 5
                                                property real r: _rc._game ? _rc._game.rating : 0
                                                property real half: threshold - 0.1
                                                source: r >= threshold ? "assets/icons/star1.png"
                                                : r >= half ? "assets/icons/star2.png"
                                                : "assets/icons/star0.png"
                                                fillMode: Image.PreserveAspectFit
                                                mipmap: true; smooth: true
                                                visible: false
                                            }

                                            ColorOverlay {
                                                anchors.fill: _starIcon
                                                source: _starIcon
                                                color: root.lightTheme ? "#05070a" : "#ffffff"
                                                Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
                                            }
                                        }
                                    }
                                }

                                Item { width: vpx(2); height: vpx(1) }

                                Row {
                                    spacing: vpx(3)
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: _rc._game ? (_rc._game.playCount > 0) : false

                                    Text {
                                        text: "▶"
                                        font.pixelSize: vpx(12)
                                        color: root.lightTheme ? "#1a6b7a" : "#57cbde"
                                        anchors.verticalCenter: parent.verticalCenter
                                        Behavior on color { ColorAnimation { duration: 400 } }
                                    }
                                    Text {
                                        text: _rc._game ? _rc._game.playCount + "×" : ""
                                        font.pixelSize: vpx(14)
                                        font.family: global.fonts.sans
                                        color: root.lightTheme ? "#1a6b7a" : "#57cbde"
                                        Behavior on color { ColorAnimation { duration: 400 } }
                                    }
                                }

                                Rectangle {
                                    width: _neverText.width + vpx(8)
                                    height: vpx(18)
                                    radius: vpx(3)
                                    color: root.lightTheme ? "#c0dce8" : "#1a3a4a"
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: _rc._game ? (_rc._game.playCount === 0) : false
                                    Behavior on color { ColorAnimation { duration: 400 } }

                                    Text {
                                        id: _neverText
                                        anchors.centerIn: parent
                                        text: "NEW"
                                        font.pixelSize: vpx(12)
                                        font.bold: true
                                        font.family: global.fonts.sans
                                        color: root.lightTheme ? "#1a6b7a" : "#57cbde"
                                        Behavior on color { ColorAnimation { duration: 400 } }
                                    }
                                }
                            }

                            Text {
                                width: parent.width
                                text: (_rc._game && _rc._game.collections.count > 0) ? _rc._game.collections.get(0).name : ""
                                font.pixelSize: vpx(12)
                                font.family: global.fonts.sans
                                color: root.lightTheme ? "#8090a0" : "#556677"
                                elide: Text.ElideRight
                                visible: text !== ""
                                Behavior on color { ColorAnimation { duration: 400 } }
                            }
                        }
                    }

                    Item {
                        id: _rcGlowSrc
                        anchors.fill: parent
                        visible: false
                        Rectangle { anchors.fill: parent; color: "#1a1a1a" }
                        Image {
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: _recStrip.imgH
                            source: _rcArt.source
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true; smooth: true
                        }
                    }

                    FastBlur {
                        anchors.fill: _rcGlowSrc
                        anchors.margins: vpx(-14)
                        source: _rcGlowSrc
                        radius: 70
                        transparentBorder: true
                        opacity: _rc.isCurrent && _recStrip.activeFocus ? 0.40 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }

                    Rectangle {
                        id: _rcSelRect
                        anchors.fill: parent
                        property real borderExtra: 0
                        anchors.margins: vpx(-3.5) - borderExtra
                        border.width: vpx(1.5) + borderExtra
                        border.color: root.lightTheme ? "#05070a" : "#c7c7c7"
                        color: "transparent"
                        opacity: 0

                        SequentialAnimation on opacity {
                            running: _rc.isCurrent && _recStrip.activeFocus
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.8; duration: 600; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutQuad }
                            onStopped: _rcSelRect.opacity = 0
                        }
                        SequentialAnimation on borderExtra {
                            id: _rcBorderPulse; running: false
                            NumberAnimation { to: vpx(3.5); duration: 150; easing.type: Easing.OutQuad }
                            NumberAnimation { to: 0; duration: 250; easing.type: Easing.InQuad }
                        }
                    }

                    onIsCurrentChanged: { if (isCurrent && _recStrip.activeFocus) _rcBorderPulse.restart(); }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: { _recStrip.currentIndex = index; _recStrip.forceActiveFocus(); }
                        onDoubleClicked: { if (_rc._game) root.openHub(_rc._game); }
                    }
                }

                Keys.onLeftPressed: { if (currentIndex > 0) currentIndex--; event.accepted = true; }
                Keys.onRightPressed: { if (currentIndex < count - 1) currentIndex++; event.accepted = true; }
                Keys.onUpPressed: { event.accepted = true; _strip.forceActiveFocus(); }
                Keys.onDownPressed: {
                    event.accepted = true;
                    if (root._raRecentGames.length > 0) _raStrip.forceActiveFocus();
                }

                Keys.onPressed: {
                    if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                        event.accepted = true;
                        var g = root._recGames[currentIndex];
                        if (g) root.openHub(g);
                        return;
                    }
                    if (!event.isAutoRepeat && api.keys.isDetails(event)) {
                        event.accepted = true;
                        var gd = root._recGames[currentIndex];
                        if (gd) gd.favorite = !gd.favorite;
                        return;
                    }
                    if (api.keys.isNextPage(event)) {
                        event.accepted = true;
                        if (currentIndex < count - 1) currentIndex++;
                        return;
                    }
                    if (api.keys.isPrevPage(event)) {
                        event.accepted = true;
                        if (currentIndex > 0) currentIndex--;
                        return;
                    }
                    if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                        event.accepted = true;
                        _strip.currentIndex = 0;
                        _strip.forceActiveFocus();
                    }
                }
            }

            Text {
                id: _raLabel
                anchors {
                    top: _recStrip.visible ? _recStrip.bottom : _info.bottom
                    left: parent.left
                    topMargin: vpx(28)
                }
                visible: root._raRecentGames.length > 0 || root._raLoading
                font.pixelSize: vpx(32)
                font.bold: true
                font.family: global.fonts.sans
                color: root.lightTheme ? "#0d1117" : "#ffffff"
                opacity: 0.95

                text: "RetroAchievements"
                Behavior on color { ColorAnimation { duration: 400 } }

                Rectangle {
                    anchors { left: parent.right; leftMargin: vpx(12); verticalCenter: parent.verticalCenter }
                    width: vpx(20); height: vpx(20); radius: vpx(10)
                    color: "transparent"
                    border.width: vpx(2)
                    border.color: root.lightTheme ? "#1a6b7a" : "#57cbde"
                    visible: root._raLoading
                    Behavior on border.color { ColorAnimation { duration: 400 } }
                    RotationAnimator on rotation {
                        running: root._raLoading
                        loops: Animation.Infinite; from: 0; to: 360; duration: 900
                    }
                }
            }

            ListView {
                id: _raStrip
                anchors {
                    top: _raLabel.bottom
                    left: parent.left
                    right: parent.right
                    topMargin: vpx(14)
                }
                height: vpx(220)
                visible: root._raRecentGames.length > 0

                orientation: ListView.Horizontal
                spacing: vpx(16)
                clip: false
                focus: false
                interactive: false
                highlightMoveDuration: 0
                highlightRangeMode: ListView.NoHighlightRange
                currentIndex: 0

                model: Math.min(root._raRecentGames.length, 4)

                readonly property real cardW: (width - vpx(16) * 3) / 4
                readonly property real imgH: vpx(160)

                delegate: Item {
                    id: _raCell

                    readonly property bool isCurrent: ListView.isCurrentItem
                    readonly property var _rg: root._raRecentGames[index] || {}

                    width: _raStrip.cardW
                    height: _raStrip.height
                    scale: isCurrent && _raStrip.activeFocus ? 1.05 : 1.0
                    opacity: isCurrent ? 1.0 : (_raStrip.activeFocus ? 1.0 : 0.98)
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Item {
                        id: _raImgArea
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: _raStrip.imgH
                        clip: false

                        Image {
                            id: _raArt
                            width: parent.width
                            height: parent.height * 1.2
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true; smooth: true
                            source: _raCell._rg.imgTitle || _raCell._rg.imgIcon || ""

                            Rectangle {
                                anchors.fill: parent; color: "#1c2533"
                                visible: parent.status !== Image.Ready
                            }
                        }
                    }

                    Rectangle {
                        id: _raInfoPanel
                        anchors {
                            top: _raImgArea.bottom
                            left: parent.left; right: parent.right; bottom: parent.bottom
                        }
                        color: root.lightTheme ? "#dde1e8" : "#121926"
                        Behavior on color { ColorAnimation { duration: 400 } }

                        Column {
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: vpx(8); rightMargin: vpx(8)
                            }
                            spacing: vpx(3)

                            Text {
                                width: parent.width
                                text: _raCell._rg.title || ""
                                font.pixelSize: vpx(12)
                                font.bold: true
                                font.family: global.fonts.sans
                                color: root.lightTheme ? "#0d1117" : "#ffffff"
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: 400 } }
                            }

                            Text {
                                width: parent.width
                                text: _raCell._rg.consoleName || ""
                                font.pixelSize: vpx(11)
                                font.family: global.fonts.sans
                                color: root.lightTheme ? "#1a6b7a" : "#57cbde"
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: 400 } }
                            }

                            Text {
                                width: parent.width
                                visible: (_raCell._rg.lastPlayed || "") !== ""
                                text: "Last played " + (_raCell._rg.lastPlayed || "")
                                font.pixelSize: vpx(10)
                                font.family: global.fonts.sans
                                color: root.lightTheme ? "#5a6472" : "#667788"
                                elide: Text.ElideRight
                                Behavior on color { ColorAnimation { duration: 400 } }
                            }
                        }
                    }

                    Item {
                        id: _raGlowSrc
                        anchors.fill: parent
                        visible: false
                        Rectangle { anchors.fill: parent; color: "#1a1a1a" }
                        Image {
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: _raStrip.imgH
                            source: _raArt.source
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true; smooth: true
                        }
                    }

                    FastBlur {
                        anchors.fill: _raGlowSrc
                        anchors.margins: vpx(-14)
                        source: _raGlowSrc
                        radius: 70
                        transparentBorder: true
                        opacity: _raCell.isCurrent && _raStrip.activeFocus ? 0.40 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }

                    Rectangle {
                        id: _raSelRect
                        anchors.fill: parent
                        property real borderExtra: 0
                        anchors.margins: vpx(-3.5) - borderExtra
                        border.width: vpx(1.5) + borderExtra
                        border.color: root.lightTheme ? "#05070a" : "#c7c7c7"
                        color: "transparent"
                        opacity: 0

                        SequentialAnimation on opacity {
                            running: _raCell.isCurrent && _raStrip.activeFocus
                            loops: Animation.Infinite
                            NumberAnimation { to: 0.8; duration: 600; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutQuad }
                            onStopped: _raSelRect.opacity = 0
                        }
                        SequentialAnimation on borderExtra {
                            id: _raBorderPulse; running: false
                            NumberAnimation { to: vpx(3.5); duration: 150; easing.type: Easing.OutQuad }
                            NumberAnimation { to: 0; duration: 250; easing.type: Easing.InQuad }
                        }
                    }

                    onIsCurrentChanged: { if (isCurrent && _raStrip.activeFocus) _raBorderPulse.restart(); }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: { _raStrip.currentIndex = index; _raStrip.forceActiveFocus(); }
                        onDoubleClicked: {
                            var rg = root._raRecentGames[index];
                            if (rg) { root.saveScrollForRA(); root.openRA(null, rg.raGameId); }
                        }
                    }
                }

                Keys.onLeftPressed: { if (currentIndex > 0) currentIndex--; event.accepted = true; }
                Keys.onRightPressed: { if (currentIndex < count - 1) currentIndex++; event.accepted = true; }
                Keys.onUpPressed: {
                    event.accepted = true;
                    if (root._recGames.length > 0) _recStrip.forceActiveFocus();
                    else _strip.forceActiveFocus();
                }
                Keys.onDownPressed: { event.accepted = true; }

                Keys.onPressed: {
                    if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                        event.accepted = true;
                        var rg = root._raRecentGames[currentIndex];
                        if (rg) { root.saveScrollForRA(); root.openRA(null, rg.raGameId); }
                        return;
                    }
                    if (api.keys.isNextPage(event)) {
                        event.accepted = true;
                        if (currentIndex < count - 1) currentIndex++;
                        return;
                    }
                    if (api.keys.isPrevPage(event)) {
                        event.accepted = true;
                        if (currentIndex > 0) currentIndex--;
                        return;
                    }
                    if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                        event.accepted = true;
                        _strip.currentIndex = 0;
                        _strip.forceActiveFocus();
                    }
                }
            }
        }
    }

    onFocusChanged: { if (focus) _strip.forceActiveFocus(); }
}
