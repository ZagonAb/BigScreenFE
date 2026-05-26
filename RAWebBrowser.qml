// BigScreenFE Theme
// Copyright (C) 2026 Gonzalo
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/

import QtQuick 2.15
import QtGraphicalEffects 1.15

FocusScope {
    id: root

    property var game: null
    property string raGameId: ""
    property bool lightTheme: false

    signal closeRequested()

    readonly property color _bgMain: lightTheme ? "#dfe3e8" : "#08111a"
    readonly property color _bgOverlay: lightTheme ? "#f8f9fa" : "#050d14"
    readonly property color _bgHeader: lightTheme ? "#f8f9fa" : "#050d14"
    readonly property color _bgCard: lightTheme ? "#ffffff" : "#121926"
    readonly property color _bgTooltip: lightTheme ? "#f1f5f9" : "#050d14"
    readonly property color _textPrimary: lightTheme ? "#0d1117" : "#f0f4f8"
    readonly property color _textSecondary: lightTheme ? "#5a6472" : "#8eaabb"
    readonly property color _textAccent: lightTheme ? "#1a6b7a" : "#57cbde"
    readonly property color _textMuted: lightTheme ? "#8b929a" : "#445566"
    readonly property color _textHighlight: lightTheme ? "#0d1117" : "#f5c518"
    readonly property color _textGold: "#f5c518"
    readonly property color _textSuccess: "#2ecc71"
    readonly property color _textError: "#c0392b"
    readonly property color _separator: lightTheme ? "#cbd5e1" : "#1e3045"
    readonly property color _tabBgActive: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _tabTextActive: lightTheme ? "#ffffff" : "#050d14"
    readonly property color _tabBgInactive: "transparent"
    readonly property color _tabTextInactive: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _tabHoverBg: lightTheme ? "#e2e8f0" : "#292b2d"
    readonly property color _badgeBg: lightTheme ? "#e2e8f0" : "#1c2e3e"
    readonly property color _badgeGold: lightTheme ? "#fef9c3" : "#7a5500"
    readonly property color _borderLight: lightTheme ? "#cbd5e1" : "#1e3045"
    readonly property color _borderSelection: lightTheme ? "#0d1117" : "#c7c7c7"
    readonly property color _progressBg: lightTheme ? "#d1d5db" : "#1c2e3e"
    readonly property color _progressFill: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _progressFull: lightTheme ? "#0d9488" : "#f5c518"
    readonly property color _iconColor: lightTheme ? "#0d1117" : "#ffffff"

    property string _apiKey: api.memory.has("ra_api_key") ? api.memory.get("ra_api_key") : ""
    property string _apiUser: api.memory.has("ra_api_user") ? api.memory.get("ra_api_user") : ""
    readonly property string _base: "https://retroachievements.org/API/"
    readonly property string _media: "https://media.retroachievements.org"

    property bool _loading: false
    property string _errorMsg: ""
    property string _resolvedId: raGameId

    property string _raTitle: ""
    property string _raConsole: ""
    property string _raImgIcon: ""
    property string _raImgTitle: ""
    property string _raImgIngame: ""
    property string _raImgBox: ""
    property int _raNumAch: 0
    property int _raPoints: 0
    property string _raGenre: ""
    property string _raDev: ""
    property string _raPublisher: ""
    property string _raReleased: ""
    property string _raLastPlayed: ""

    property int _numEarned: 0
    property var _achievements: []

    property string _activeTab: "achievements"
    readonly property bool onGamesTab: _activeTab === "games"
    property int _selIdx: 0

    property var _gamesList: []
    property bool _gamesLoading: false
    property int _gamesSelIdx: 0

    function _apiUrl(endpoint, params) {
        var url = _base + endpoint + "?y=" + _apiKey;
        for (var k in params) url += "&" + k + "=" + encodeURIComponent(params[k]);
        return url;
    }

    function _get(url, cb) {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status === 200) {
                try { cb(null, JSON.parse(xhr.responseText)); }
                catch(e) { cb("JSON parse: " + e, null); }
            } else { cb("HTTP " + xhr.status, null); }
        };
        xhr.send();
    }

    function load() {
        _apiKey = api.memory.has("ra_api_key") ? api.memory.get("ra_api_key") : ""
        _apiUser = api.memory.has("ra_api_user") ? api.memory.get("ra_api_user") : ""

        _loading = true;
        _errorMsg = "";
        _raLastPlayed = "";
        _achievements = [];
        _pegasusDescription = "";
        _raTitle = ""; _raConsole = ""; _raImgIcon = ""; _raImgTitle = "";
        _raImgIngame = ""; _raImgBox = ""; _raGenre = ""; _raDev = "";
        _raPublisher = ""; _raReleased = "";
        _raNumAch = 0; _raPoints = 0; _numEarned = 0; _selIdx = 0;

        if (_resolvedId !== "") {
            _fetchGameProgress(_resolvedId);
        } else {
            _loading = false;
            _errorMsg = "No RetroAchievements ID configured for this game.";
        }
    }

    function _fetchGameProgress(gid) {
        var url = _apiUrl("API_GetGameInfoAndUserProgress.php", { u: _apiUser, g: gid });
        _get(url, function(err, data) {
            if (err || !data) { _loading = false; _errorMsg = err || "empty"; return; }
            _raTitle = data.Title || "";
            _raConsole = data.ConsoleName || "";
            _raImgIcon = data.ImageIcon ? (_media + data.ImageIcon) : "";
            _raImgTitle = data.ImageTitle ? (_media + data.ImageTitle) : "";
            _raImgIngame = data.ImageIngame ? (_media + data.ImageIngame) : "";
            _raImgBox = data.ImageBoxArt ? (_media + data.ImageBoxArt) : "";
            _raNumAch = parseInt(data.NumAchievements) || 0;
            _raPoints = parseInt(data.Points) || 0;
            _numEarned = parseInt(data.NumAwardedToUser) || 0;
            _raGenre = data.Genre || "";
            _raDev = data.Developer || "";
            _raPublisher = data.Publisher || "";
            _raReleased = data.Released || "";
            var ach = [];
            var achMap = data.Achievements || {};
            for (var id in achMap) {
                var a = achMap[id];
                var earned = (a.DateEarned && a.DateEarned !== "");
                ach.push({
                    id: id,
                    title: a.Title || "",
                    description: a.Description || "",
                    points: parseInt(a.Points) || 0,
                         badgeUrl: a.BadgeName ? (_media + "/Badge/" + a.BadgeName + ".png") : "",
                         badgeLocked: a.BadgeName ? (_media + "/Badge/" + a.BadgeName + "_lock.png") : "",
                         earned: earned,
                         dateEarned: earned ? a.DateEarned : "",
                         numAwarded: parseInt(a.NumAwarded) || 0
                });
            }
            ach.sort(function(a, b) {
                if (a.earned !== b.earned) return a.earned ? -1 : 1;
                return b.points - a.points;
            });
            _achievements = ach;
            _loading = false;
            Qt.callLater(_findPegasusDescription);

            var lpUrl = _apiUrl("API_GetUserRecentlyPlayedGames.php", { u: _apiUser, c: 50 });
            _get(lpUrl, function(lpErr, lpData) {
                if (lpErr || !Array.isArray(lpData)) return;
                for (var li = 0; li < lpData.length; li++) {
                    if (String(lpData[li].GameID) === String(gid)) {
                        _raLastPlayed = lpData[li].LastPlayed || "";
                        return;
                    }
                }
            });
        });
    }

    function _loadGames() {
        if (_gamesList.length > 0 || _gamesLoading) return;
        _gamesLoading = true;
        var url = _apiUrl("API_GetUserCompletionProgress.php", { u: _apiUser, c: 100, o: 0 });
        _get(url, function(err, data) {
            _gamesLoading = false;
            if (err || !data) return;
            var list = data.Results || (Array.isArray(data) ? data : []);
            var result = [];
            for (var j = 0; j < list.length; j++) {
                var g = list[j];
                var earned = parseInt(g.NumAwarded) || 0;
                var numAch = parseInt(g.MaxPossible || g.NumAchievements) || 0;
                result.push({
                    id: String(g.GameID || ""),
                            title: g.Title || "",
                            consoleName: g.ConsoleName || "",
                            imgIcon: g.ImageIcon ? (_media + g.ImageIcon) : "",
                            imgIngame: g.ImageIngame ? (_media + g.ImageIngame) : "",
                            imgTitle: g.ImageTitle ? (_media + g.ImageTitle) : "",
                            numAch: numAch,
                            earned: earned,
                            pct: numAch > 0 ? Math.round(earned * 100 / numAch) : 0
                });
            }
            result.sort(function(a, b) {
                if (b.pct !== a.pct) return b.pct - a.pct;
                return a.title.localeCompare(b.title);
            });
            _gamesList = result;
        });
    }

    Component.onCompleted: {
        if (_resolvedId === "" && game) {
            var tryId = "";
            if (typeof game.extraData !== "undefined" && game.extraData)
                tryId = game.extraData["ra_id"] || game.extraData["ra_game_id"] || "";
            if (tryId !== "") _resolvedId = tryId;
        }
        load();
        if (visible) _achGrid.forceActiveFocus();
    }

    onGameChanged: { _resolvedId = raGameId; if (visible) load(); Qt.callLater(_findPegasusDescription); }
    onRaGameIdChanged: { _resolvedId = raGameId; }
    onVisibleChanged: {
        if (visible) { load(); _achGrid.forceActiveFocus(); }
    }
    on_ActiveTabChanged: {
        if (_activeTab === "achievements") _achGrid.forceActiveFocus();
        if (_activeTab === "info") _infoFlick.forceActiveFocus();
        if (_activeTab === "games") { _loadGames(); _gamesGrid.forceActiveFocus(); }
    }

    Rectangle {
        anchors.fill: parent
        color: _bgMain
        Behavior on color { ColorAnimation { duration: 300 } }
    }

    Image {
        id: _bgImg; anchors.fill: parent
        source: root._raImgTitle !== "" ? root._raImgTitle
        : (root.game ? (root.game.assets.background || root.game.assets.screenshot || "") : "")
        fillMode: Image.PreserveAspectCrop; asynchronous: true; visible: false
    }
    FastBlur {
        anchors.fill: _bgImg; source: _bgImg; radius: 80
        opacity: _bgImg.status === Image.Ready ? 0.15 : 0.0
        Behavior on opacity { NumberAnimation { duration: 500 } }
    }
    Rectangle {
        anchors.fill: parent
        color: _bgMain
        opacity: 0.80
        Behavior on color { ColorAnimation { duration: 300 } }
    }

    Item {
        id: _header
        anchors { top: _tabBar.bottom; left: parent.left; right: parent.right }
        height: (root._activeTab === "info" || root._activeTab === "games") ? 0 : vpx(110)
        clip: true
        z: 9
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.InOutQuad } }

        Rectangle {
            anchors.fill: parent
            color: _bgOverlay
            opacity: 0.97
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: vpx(1); color: _separator
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Rectangle {
            id: _raBadge
            anchors { right: parent.right; rightMargin: vpx(20); verticalCenter: parent.verticalCenter }
            width: vpx(125); height: vpx(28); radius: vpx(5)
            color: lightTheme ? "#0d1117" : "#ffffff"
            Text {
                anchors.centerIn: parent
                text: "¡%$#@!-Library RA"
                font.pixelSize: vpx(14); font.bold: true
                font.family: global.fonts.sans
                color: lightTheme ? "#ffffff" : "#050d14"
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        Image {
            id: _gameIcon
            anchors { left: parent.left; leftMargin: vpx(20); verticalCenter: parent.verticalCenter }
            width: vpx(64); height: vpx(64)
            source: root._raImgIcon
            fillMode: Image.PreserveAspectFit; asynchronous: true; smooth: true
            Rectangle {
                anchors.fill: parent; radius: vpx(6)
                color: _badgeBg
                visible: parent.status !== Image.Ready
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }

        Column {
            anchors {
                left: _gameIcon.right; leftMargin: vpx(14)
                right: _raBadge.left; rightMargin: vpx(16)
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(6)

            Text {
                text: root._raTitle !== "" ? root._raTitle
                : (root.game ? root.game.title : "RetroAchievements")
                font.pixelSize: vpx(22); font.bold: true
                font.family: global.fonts.sans; color: _textPrimary
                elide: Text.ElideRight; width: parent.width
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            Row {
                spacing: vpx(0)
                visible: root._raPoints > 0 || root._raConsole !== ""

                Text {
                    text: "Points: "; font.pixelSize: vpx(13); font.bold: true
                    font.family: global.fonts.sans; color: _textPrimary
                    visible: root._raPoints > 0
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: root._raPoints + "  "; font.pixelSize: vpx(13)
                    font.family: global.fonts.sans; color: _textPrimary
                    visible: root._raPoints > 0
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: "│  "; font.pixelSize: vpx(13)
                    font.family: global.fonts.sans; color: _separator
                    visible: root._raPoints > 0 && root._raConsole !== ""
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: root._raConsole; font.pixelSize: vpx(13)
                    font.family: global.fonts.sans; color: _textAccent
                    visible: root._raConsole !== ""
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: "  │  " + root._numEarned + " / " + root._raNumAch + " achievements"
                    font.pixelSize: vpx(13); font.family: global.fonts.sans; color: _textSecondary
                    visible: root._raNumAch > 0
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Item {
                width: parent.width; height: vpx(8)
                visible: root._raNumAch > 0
                Rectangle {
                    anchors.fill: parent; radius: vpx(4)
                    color: _progressBg
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    radius: vpx(4)
                    color: root._numEarned === root._raNumAch ? _progressFull : _progressFill
                    width: root._raNumAch > 0 ? parent.width * root._numEarned / root._raNumAch : 0
                    Behavior on width { NumberAnimation { duration: 700; easing.type: Easing.OutQuad } }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }
    }

    function _prevTab() {
        var tabs = ["achievements", "info", "games"];
        var i = tabs.indexOf(root._activeTab);
        var next = (i - 1 + tabs.length) % tabs.length;
        root._activeTab = tabs[next];
        if (tabs[next] === "games") _loadGames();
    }
    function _nextTab() {
        var tabs = ["achievements", "info", "games"];
        var i = tabs.indexOf(root._activeTab);
        var next = (i + 1) % tabs.length;
        root._activeTab = tabs[next];
        if (tabs[next] === "games") _loadGames();
    }

    Item {
        id: _tabBar
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: vpx(52)
        z: 10

        Rectangle {
            anchors.fill: parent
            color: _bgOverlay
            opacity: 0.98
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: vpx(1); color: _separator
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        NavButton {
            id: _btnL1
            label: "L1"; side: "left"
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: vpx(55) }
            width: vpx(40); height: vpx(28)
            lightTheme: root.lightTheme
            onClicked: root._prevTab()
        }

        ListView {
            id: _tabList
            anchors.centerIn: parent
            width: contentWidth
            height: vpx(36)
            orientation: ListView.Horizontal
            interactive: false
            spacing: vpx(6)
            model: ["ACHIEVEMENTS", "GAME INFO", "GAMES"]

            delegate: Item {
                id: _tabDelegate
                readonly property bool _active:
                (index === 0 && root._activeTab === "achievements") ||
                (index === 1 && root._activeTab === "info") ||
                (index === 2 && root._activeTab === "games")

                width: Math.min(_tabLbl.implicitWidth, vpx(160)) + vpx(28)
                height: _tabList.height

                Rectangle {
                    anchors.fill: parent; radius: vpx(18)
                    color: _active ? _tabBgActive : (_tabHover.containsMouse ? _tabHoverBg : _tabBgInactive)
                    Behavior on color { ColorAnimation { duration: 180 } }
                }
                Text {
                    id: _tabLbl
                    anchors.centerIn: parent
                    text: modelData
                    color: _active ? _tabTextActive : _tabTextInactive
                    font.family: global.fonts.sans
                    font.pixelSize: vpx(13); font.bold: _active
                    width: Math.min(implicitWidth, vpx(160)); elide: Text.ElideRight
                    Behavior on color { ColorAnimation { duration: 180 } }
                }
                MouseArea {
                    id: _tabHover
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (index === 0) root._activeTab = "achievements";
                        else if (index === 1) root._activeTab = "info";
                        else { root._activeTab = "games"; _loadGames(); }
                    }
                }
            }
        }

        NavButton {
            id: _btnR1
            label: "R1"; side: "right"
            anchors { verticalCenter: parent.verticalCenter; right: parent.right; rightMargin: vpx(55) }
            width: vpx(40); height: vpx(28)
            lightTheme: root.lightTheme
            onClicked: root._nextTab()
        }
    }

    Item {
        anchors { top: _header.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: root._loading
        Column {
            anchors.centerIn: parent; spacing: vpx(14)
            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: vpx(48); height: vpx(48)
                Image {
                    id: _loadingIconSrc
                    anchors.fill: parent
                    source: "assets/icons/icon_0.png"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true; smooth: true
                    visible: false
                }
                ColorOverlay {
                    anchors.fill: parent
                    source: _loadingIconSrc
                    color: _iconColor
                    SequentialAnimation on scale {
                        running: root._loading; loops: Animation.Infinite
                        NumberAnimation { to: 1.25; duration: 350; easing.type: Easing.InOutQuad }
                        NumberAnimation { to: 0.80; duration: 350; easing.type: Easing.InOutQuad }
                    }
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Loading…"; font.pixelSize: vpx(14)
                font.family: global.fonts.sans; color: _textPrimary
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }

    Item {
        anchors { top: _header.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
        visible: !root._loading && root._errorMsg !== ""
        Column {
            anchors.centerIn: parent; spacing: vpx(12); width: parent.width * 0.6
            Text { anchors.horizontalCenter: parent.horizontalCenter; text: "⚠"; font.pixelSize: vpx(32); color: _textAccent }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter; text: root._errorMsg
                font.pixelSize: vpx(14); font.family: global.fonts.sans; color: _textSecondary
                horizontalAlignment: Text.AlignHCenter; wrapMode: Text.WordWrap; width: parent.width
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }

    GridView {
        id: _achGrid
        anchors {
            top: _header.bottom; topMargin: vpx(10)
            left: parent.left; leftMargin: vpx(20)
            right: parent.right; rightMargin: vpx(20)
            bottom: _achTooltip.top
        }
        visible: !root._loading && root._errorMsg === "" && root._activeTab === "achievements"
        focus: root.visible && root._activeTab === "achievements"
        clip: true
        model: root._achievements.length
        currentIndex: root._selIdx

        readonly property int _cols: Math.max(4, Math.floor(width / vpx(84)))
        readonly property real _cellSz: Math.floor(width / _cols)
        cellWidth: _cellSz
        cellHeight: _cellSz

        delegate: Item {
            id: _achItem
            width: _achGrid._cellSz
            height: _achGrid._cellSz
            readonly property bool _sel: index === root._selIdx
            readonly property var _a: root._achievements[index] || {}
            readonly property bool _earned: _a.earned || false

            Item {
                id: _achGlowSource
                anchors.fill: _badge
                visible: false
                Image {
                    anchors.fill: parent
                    source: _achItem._earned ? _achItem._a.badgeUrl : _achItem._a.badgeLocked
                    fillMode: Image.PreserveAspectFit; asynchronous: true; smooth: true
                }
            }
            FastBlur {
                anchors.fill: _achGlowSource
                anchors.margins: vpx(-15)
                source: _achGlowSource; radius: 75; transparentBorder: true
                opacity: _achItem._sel && _achGrid.activeFocus ? 0.40 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            Image {
                id: _badge
                anchors.centerIn: parent
                width: vpx(64); height: vpx(64)
                source: _achItem._earned ? _achItem._a.badgeUrl : _achItem._a.badgeLocked
                fillMode: Image.PreserveAspectFit; asynchronous: true; smooth: true
                layer.enabled: !_achItem._earned
                layer.effect: Desaturate { desaturation: 0.88 }
                Rectangle {
                    anchors.fill: parent; radius: vpx(6)
                    color: _badgeBg
                    visible: parent.status !== Image.Ready
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Rectangle {
                id: _achSelRect
                anchors.fill: _badge
                property real borderExtra: 0
                anchors.margins: vpx(-3.5) - borderExtra
                border.width: vpx(1.5) + borderExtra
                border.color: _borderSelection
                color: "transparent"
                radius: 0
                opacity: 0
                Behavior on border.color { ColorAnimation { duration: 200 } }

                SequentialAnimation on opacity {
                    running: _achItem._sel && _achGrid.activeFocus
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.8; duration: 600; easing.type: Easing.InOutQuad }
                    NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutQuad }
                    onStopped: _achSelRect.opacity = 0
                }
                SequentialAnimation on borderExtra {
                    id: _achBorderPulse; running: false
                    NumberAnimation { to: vpx(3.5); duration: 150; easing.type: Easing.OutQuad }
                    NumberAnimation { to: 0; duration: 250; easing.type: Easing.InQuad }
                }
            }

            scale: _achItem._sel && _achGrid.activeFocus ? 1.05 : 1.0
            Behavior on scale { NumberAnimation { duration: 120 } }

            GridView.onIsCurrentItemChanged: {
                if (_achItem._sel && _achGrid.activeFocus) _achBorderPulse.restart()
            }

            Connections {
                target: root
                function on_SelIdxChanged() {
                    if (_achItem._sel && _achGrid.activeFocus) _achBorderPulse.restart()
                }
            }

            Rectangle {
                anchors { right: _badge.right; bottom: _badge.bottom; margins: vpx(-2) }
                width: _ptsTxt.width + vpx(6); height: vpx(16); radius: vpx(3)
                color: _achItem._earned ? _badgeGold : _badgeBg
                visible: (_achItem._a.points || 0) > 0
                Behavior on color { ColorAnimation { duration: 200 } }
                Text {
                    id: _ptsTxt
                    anchors.centerIn: parent
                    text: _achItem._a.points || 0
                    font.pixelSize: vpx(10); font.bold: true
                    font.family: global.fonts.sans
                    color: _achItem._earned ? _textGold : _textMuted
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: { root._selIdx = index; _achGrid.forceActiveFocus(); }
            }
        }

        Keys.onUpPressed: {
            event.accepted = true;
            if (root._selIdx >= _achGrid._cols) root._selIdx -= _achGrid._cols;
            _achGrid.positionViewAtIndex(root._selIdx, GridView.Contain);
        }
        Keys.onDownPressed: {
            event.accepted = true;
            if (root._selIdx + _achGrid._cols < root._achievements.length)
                root._selIdx += _achGrid._cols;
            _achGrid.positionViewAtIndex(root._selIdx, GridView.Contain);
        }
        Keys.onLeftPressed: {
            event.accepted = true;
            if (root._selIdx > 0) root._selIdx--;
            _achGrid.positionViewAtIndex(root._selIdx, GridView.Contain);
        }
        Keys.onRightPressed: {
            event.accepted = true;
            if (root._selIdx < root._achievements.length - 1) root._selIdx++;
            _achGrid.positionViewAtIndex(root._selIdx, GridView.Contain);
        }
        Keys.onPressed: {
            if (api.keys.isCancel(event) || event.key === Qt.Key_Escape) {
                event.accepted = true; root.closeRequested(); return;
            }
            if (api.keys.isNextPage(event)) { event.accepted = true; root._activeTab = "info"; return; }
            if (api.keys.isPrevPage(event)) { event.accepted = true; root._activeTab = "games"; return; }
        }
    }

    Rectangle {
        id: _achTooltip
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: vpx(76)
        color: _bgTooltip
        opacity: root._activeTab === "achievements" && root._achievements.length > 0 ? 0.97 : 0.0
        visible: opacity > 0.0
        Behavior on opacity { NumberAnimation { duration: 200 } }
        Behavior on color { ColorAnimation { duration: 200 } }

        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: vpx(1); color: _separator
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        readonly property var _a: root._achievements[root._selIdx] || {}

        Row {
            anchors {
                left: parent.left; leftMargin: vpx(20)
                right: parent.right; rightMargin: vpx(20)
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(14)

            Image {
                anchors.verticalCenter: parent.verticalCenter
                width: vpx(48); height: vpx(48)
                source: (_achTooltip._a.earned || false) ? (_achTooltip._a.badgeUrl || "") : (_achTooltip._a.badgeLocked || "")
                fillMode: Image.PreserveAspectFit; asynchronous: true; smooth: true
                layer.enabled: !(_achTooltip._a.earned || false)
                layer.effect: Desaturate { desaturation: 0.88 }
                Rectangle {
                    anchors.fill: parent; radius: vpx(6)
                    color: _badgeBg
                    visible: parent.status !== Image.Ready
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: vpx(4)
                width: parent.width * 0.52

                Text {
                    text: _achTooltip._a.title || ""
                    font.pixelSize: vpx(14); font.bold: true
                    font.family: global.fonts.sans; color: _textPrimary
                    elide: Text.ElideRight; width: parent.width
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: _achTooltip._a.description || ""
                    font.pixelSize: vpx(12); font.family: global.fonts.sans
                    color: _textSecondary; elide: Text.ElideRight; width: parent.width
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: vpx(4)

                Text {
                    text: (_achTooltip._a.earned || false) ? "✔ UNLOCKED" : "✘  LOCKED"
                    font.pixelSize: vpx(16); font.bold: true; font.family: global.fonts.sans
                    color: (_achTooltip._a.earned || false) ? _textSuccess : _textError
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
                Text {
                    text: (_achTooltip._a.points || 0) + " PTS"
                    font.pixelSize: vpx(16); font.bold: true; font.family: global.fonts.sans
                    color: (_achTooltip._a.earned || false) ? _textGold : _textMuted
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: (_achTooltip._a.earned || false) && (_achTooltip._a.dateEarned || "") !== ""
                text: "UNLOCKED: " + (_achTooltip._a.dateEarned || "")
                font.pixelSize: vpx(14); font.family: global.fonts.sans; color: _textAccent
                Behavior on color { ColorAnimation { duration: 200 } }
            }
        }
    }

    property string _pegasusDescription: ""

    function _normTitle(t) {
        return (t || "").toLowerCase()
        .replace(/^(the|a|an)\s+/, "")
        .replace(/[^a-z0-9]/g, "");
    }

    function _collectionMatchesConsole(col) {
        var cons = (root._raConsole || "").toLowerCase();
        if (cons === "") return false;
        var colName = (col.name || "").toLowerCase();
        var colShortName = (col.shortName || "").toLowerCase();
        if (colShortName !== "" && (cons.indexOf(colShortName) !== -1 || colShortName.indexOf(cons) !== -1)) return true;
        if (colName !== "" && (cons.indexOf(colName) !== -1 || colName.indexOf(cons) !== -1)) return true;
        return false;
    }

    function _searchInGames(games, raNorm, raYear) {
        for (var i = 0; i < games.count; i++) {
            var g = games.get(i);
            if (!g) continue;
            if (_normTitle(g.title) !== raNorm) continue;
            if (raYear > 0 && g.releaseYear > 0 && Math.abs(g.releaseYear - raYear) > 1) continue;
            var desc = g.description || g.summary || "";
            if (desc !== "") return desc;
        }
        return "";
    }

    function _findPegasusDescription() {
        if (!root.game) { _pegasusDescription = ""; return; }
        var raYear = 0;
        if (root._raReleased && root._raReleased !== "") {
            var m = root._raReleased.match(/\b(\d{4})\b/);
            if (m) raYear = parseInt(m[1]);
        }
        var raNorm = _normTitle(root._raTitle !== "" ? root._raTitle : root.game.title);
        var found = "";
        if (root._raConsole !== "") {
            for (var c = 0; c < api.collections.count; c++) {
                var col = api.collections.get(c);
                if (!col || !_collectionMatchesConsole(col)) continue;
                found = _searchInGames(col.games, raNorm, raYear);
                if (found !== "") { _pegasusDescription = found; return; }
            }
        }
        var ownCols = root.game.collections;
        for (var oc = 0; oc < ownCols.count; oc++) {
            found = _searchInGames(ownCols.get(oc).games, raNorm, raYear);
            if (found !== "") { _pegasusDescription = found; return; }
        }
        found = _searchInGames(api.allGames, raNorm, raYear);
        _pegasusDescription = found;
    }

    Flickable {
        id: _infoFlick
        anchors {
            top: _header.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        visible: !root._loading && root._errorMsg === "" && root._activeTab === "info"
        focus: root.visible && root._activeTab === "info"
        clip: true
        contentHeight: _bigPictureRoot.height
        flickableDirection: Flickable.VerticalFlick

        Item {
            id: _bigPictureRoot
            width: parent.width
            height: _heroImg.height + _infoStrip.height

            Image {
                id: _heroImg
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: Math.round(width * 1 / 4) - vpx(40)
                source: root._raImgIngame !== "" ? root._raImgIngame
                : (root.game ? (root.game.assets.background
                || root.game.assets.titlescreen
                || root.game.assets.screenshot || "") : "")
                fillMode: Image.PreserveAspectFit
                asynchronous: true

                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: vpx(80)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: _bgMain }
                    }
                }

                Rectangle {
                    anchors.fill: parent; color: _bgCard
                    visible: _heroImg.status !== Image.Ready
                    Behavior on color { ColorAnimation { duration: 200 } }
                    Text {
                        anchors.centerIn: parent; text: root._raTitle || ""
                        font.pixelSize: vpx(22); font.bold: true
                        font.family: global.fonts.sans; color: _textMuted
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap; width: parent.width * 0.8
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
            }

            Item {
                id: _infoStrip
                anchors { top: _heroImg.bottom; left: parent.left; right: parent.right }
                height: _infoCol.height + vpx(48)

                Column {
                    id: _infoCol
                    anchors {
                        top: parent.top; topMargin: vpx(16)
                        left: parent.left; leftMargin: vpx(28)
                        right: parent.right; rightMargin: vpx(28)
                    }
                    spacing: vpx(0)

                    Text {
                        width: parent.width
                        text: root._raTitle !== "" ? root._raTitle : (root.game ? root.game.title : "")
                        font.pixelSize: vpx(28); font.bold: true
                        font.family: global.fonts.sans; color: _textPrimary
                        wrapMode: Text.WordWrap
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Item { width: parent.width; height: vpx(6) }

                    Rectangle { width: parent.width; height: vpx(1); color: _separator; Behavior on color { ColorAnimation { duration: 200 } } }

                    Item { width: parent.width; height: vpx(10) }

                    Row {
                        width: parent.width
                        spacing: vpx(20)

                        Item {
                            width: vpx(310); height: vpx(260)
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 0; verticalOffset: vpx(8)
                                radius: 24; samples: 25; color: "#cc000000"
                            }
                            Image {
                                id: _boxartImg
                                anchors.fill: parent
                                source: root._raImgBox !== "" ? root._raImgBox
                                : (root.game ? (root.game.assets.boxFront
                                || root.game.assets.poster || "") : "")
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true; smooth: true
                                Rectangle {
                                    anchors.fill: parent; radius: vpx(8)
                                    color: _badgeBg
                                    visible: _boxartImg.status !== Image.Ready
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                            }
                        }

                        Item {
                            width: vpx(220); height: vpx(260)
                            visible: root._raImgTitle !== ""
                            layer.enabled: true
                            layer.effect: DropShadow {
                                horizontalOffset: 0; verticalOffset: vpx(8)
                                radius: 24; samples: 25; color: "#cc000000"
                            }
                            Image {
                                id: _titleImg
                                anchors.fill: parent
                                source: root._raImgTitle
                                fillMode: Image.PreserveAspectFit
                                asynchronous: true; smooth: true
                                Rectangle {
                                    anchors.fill: parent; radius: vpx(6)
                                    color: _badgeBg
                                    visible: _titleImg.status !== Image.Ready
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                            }
                        }

                        Item {
                            width: parent.width - vpx(310) - vpx(20) - (root._raImgTitle !== "" ? vpx(220) + vpx(20) : 0)
                            height: vpx(260)

                            Row {
                                id: _metaGrid
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.leftMargin: vpx(26)
                                anchors.right: parent.right
                                spacing: vpx(0)

                                Column {
                                    spacing: vpx(18)
                                    width: parent.width / 2

                                    Column {
                                        spacing: vpx(3); width: parent.width
                                        Text { text: "Console"; font.pixelSize: vpx(13); font.bold: true; font.family: global.fonts.sans; color: _textAccent; Behavior on color { ColorAnimation { duration: 200 } } }
                                        Text { text: root._raConsole; font.pixelSize: vpx(18); font.family: global.fonts.sans; color: _textPrimary; wrapMode: Text.WordWrap; width: parent.width; visible: root._raConsole !== ""; Behavior on color { ColorAnimation { duration: 200 } } }
                                    }
                                    Column {
                                        spacing: vpx(3); width: parent.width
                                        Text { text: "Developer"; font.pixelSize: vpx(13); font.bold: true; font.family: global.fonts.sans; color: _textAccent; Behavior on color { ColorAnimation { duration: 200 } } }
                                        Text { text: root._raDev; font.pixelSize: vpx(18); font.family: global.fonts.sans; color: _textPrimary; wrapMode: Text.WordWrap; width: parent.width; visible: root._raDev !== ""; Behavior on color { ColorAnimation { duration: 200 } } }
                                    }
                                    Column {
                                        spacing: vpx(3); width: parent.width
                                        Text { text: "Released"; font.pixelSize: vpx(13); font.bold: true; font.family: global.fonts.sans; color: _textAccent; Behavior on color { ColorAnimation { duration: 200 } } }
                                        Text { text: root._raReleased; font.pixelSize: vpx(18); font.family: global.fonts.sans; color: _textPrimary; wrapMode: Text.WordWrap; width: parent.width; visible: root._raReleased !== ""; Behavior on color { ColorAnimation { duration: 200 } } }
                                    }
                                }

                                Column {
                                    spacing: vpx(18)
                                    width: parent.width / 2

                                    Column {
                                        spacing: vpx(3); width: parent.width
                                        Text { text: "Genre"; font.pixelSize: vpx(13); font.bold: true; font.family: global.fonts.sans; color: _textAccent; Behavior on color { ColorAnimation { duration: 200 } } }
                                        Text { text: root._raGenre; font.pixelSize: vpx(18); font.family: global.fonts.sans; color: _textPrimary; wrapMode: Text.WordWrap; width: parent.width; visible: root._raGenre !== ""; Behavior on color { ColorAnimation { duration: 200 } } }
                                    }
                                    Column {
                                        spacing: vpx(3); width: parent.width
                                        Text { text: "Publisher"; font.pixelSize: vpx(13); font.bold: true; font.family: global.fonts.sans; color: _textAccent; Behavior on color { ColorAnimation { duration: 200 } } }
                                        Text { text: root._raPublisher; font.pixelSize: vpx(18); font.family: global.fonts.sans; color: _textPrimary; wrapMode: Text.WordWrap; width: parent.width; visible: root._raPublisher !== ""; Behavior on color { ColorAnimation { duration: 200 } } }
                                    }
                                    Column {
                                        spacing: vpx(3); width: parent.width
                                        Text { text: "Last Played"; font.pixelSize: vpx(13); font.bold: true; font.family: global.fonts.sans; color: _textAccent; Behavior on color { ColorAnimation { duration: 200 } } }
                                        Text { text: root._raLastPlayed; font.pixelSize: vpx(18); font.family: global.fonts.sans; color: _textPrimary; wrapMode: Text.WordWrap; width: parent.width; visible: root._raLastPlayed !== ""; Behavior on color { ColorAnimation { duration: 200 } } }
                                    }
                                }
                            }
                        }
                    }

                    Item { width: parent.width; height: vpx(24) }
                }
            }
        }

        Keys.onPressed: {
            if (api.keys.isCancel(event) || event.key === Qt.Key_Escape) { event.accepted = true; root.closeRequested(); return; }
            if (api.keys.isNextPage(event)) { event.accepted = true; root._activeTab = "games"; return; }
            if (api.keys.isPrevPage(event)) { event.accepted = true; root._activeTab = "achievements"; return; }
        }
        Keys.onUpPressed: { event.accepted = true; contentY = Math.max(0, contentY - vpx(40)); }
        Keys.onDownPressed: { event.accepted = true; contentY = Math.min(Math.max(0, contentHeight - height), contentY + vpx(40)); }
    }

    Item {
        id: _gamesTabRoot
        anchors {
            top: _tabBar.bottom
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        visible: !root._loading && root._errorMsg === "" && root._activeTab === "games"
        z: 2

        Rectangle {
            anchors.fill: parent
            color: _bgMain
            Behavior on color { ColorAnimation { duration: 200 } }
        }

        Item {
            anchors.centerIn: parent
            visible: root._gamesLoading
            Column {
                anchors.centerIn: parent; spacing: vpx(12)
                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: vpx(44); height: vpx(44)
                    Image {
                        id: _gamesLoadingIconSrc
                        anchors.fill: parent
                        source: "assets/icons/icon_0.png"
                        fillMode: Image.PreserveAspectFit
                        mipmap: true; smooth: true
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: parent
                        source: _gamesLoadingIconSrc
                        color: _iconColor
                        SequentialAnimation on scale {
                            running: root._gamesLoading; loops: Animation.Infinite
                            NumberAnimation { to: 1.25; duration: 350; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 0.80; duration: 350; easing.type: Easing.InOutQuad }
                        }
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Loading games…"
                    font.pixelSize: vpx(13); font.family: global.fonts.sans; color: _textPrimary
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
        }

        GridView {
            id: _gamesGrid
            anchors {
                fill: parent
                topMargin: vpx(24)
                bottomMargin: vpx(24)
                leftMargin: vpx(24)
                rightMargin: vpx(24)
            }
            visible: !root._gamesLoading && root._gamesList.length > 0
            focus: root.visible && root._activeTab === "games"
            clip: false
            model: root._gamesList.length
            currentIndex: root._gamesSelIdx

            readonly property real cardW: Math.floor((width - vpx(16) * 4) / 5)
            readonly property real imgH: Math.round(cardW * 0.45)
            readonly property real infoH: vpx(52)
            readonly property real cardH: imgH + infoH
            readonly property int _cols: 5

            cellWidth: Math.floor(width / _cols)
            cellHeight: cardH + vpx(10)
            height: Math.ceil(root._gamesList.length / _cols) * cellHeight - vpx(10)

            delegate: Item {
                id: _gameCell

                readonly property bool isCurrent: index === root._gamesSelIdx
                readonly property var _g: root._gamesList[index] || {}
                readonly property bool _complete: (_g.pct || 0) === 100
                readonly property string _thumb: {
                    if (_g.imgIngame && _g.imgIngame !== "") return _g.imgIngame;
                    if (_g.imgTitle && _g.imgTitle !== "") return _g.imgTitle;
                    return _g.imgIcon || "";
                }

                width: _gamesGrid.cellWidth
                height: _gamesGrid.cellHeight

                Item {
                    id: _card
                    width: _gamesGrid.cardW
                    height: _gamesGrid.cardH
                    anchors { left: parent.left; top: parent.top }

                    scale: _gameCell.isCurrent && _gamesGrid.activeFocus ? 1.05 : 1.0
                    opacity: _gameCell.isCurrent ? 1.0 : (_gamesGrid.activeFocus ? 0.65 : 0.80)
                    Behavior on scale { NumberAnimation { duration: 120 } }
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    Item {
                        id: _imgArea
                        anchors { top: parent.top; left: parent.left; right: parent.right }
                        height: _gamesGrid.imgH
                        clip: true

                        Image {
                            id: _gameArt
                            width: parent.width
                            height: parent.height * 1.15
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true; smooth: true
                            source: _gameCell._thumb

                            Rectangle {
                                anchors.fill: parent
                                color: _badgeBg
                                visible: parent.status !== Image.Ready
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        Rectangle {
                            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                            height: parent.height * 0.55
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 1.0; color: lightTheme ? "#ccdfe3e8" : "#dd000000" }
                            }
                        }
                    }

                    Rectangle {
                        id: _infoPanel
                        anchors {
                            top: _imgArea.bottom
                            left: parent.left; right: parent.right; bottom: parent.bottom
                        }
                        color: _bgCard
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Column {
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: vpx(8); rightMargin: vpx(8); topMargin: vpx(2)
                            }
                            spacing: vpx(2)

                            Text {
                                width: parent.width
                                text: _gameCell._g.title || ""
                                font.pixelSize: vpx(12); font.bold: true
                                font.family: global.fonts.sans
                                color: _textPrimary
                                elide: Text.ElideRight
                                wrapMode: Text.WordWrap; maximumLineCount: 2
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            Text {
                                width: parent.width
                                text: _gameCell._g.consoleName || ""
                                font.pixelSize: vpx(14); font.family: global.fonts.sans
                                color: _textAccent; elide: Text.ElideRight
                                visible: (_gameCell._g.consoleName || "") !== ""
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            Row {
                                spacing: vpx(4)
                                visible: (_gameCell._g.numAch || 0) > 0
                                Text {
                                    text: (_gameCell._g.earned || 0) + "/" + (_gameCell._g.numAch || 0)
                                    font.pixelSize: vpx(12); font.family: global.fonts.sans
                                    color: _gameCell._complete ? _textGold : _textSecondary
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                                Text {
                                    text: "·  " + (_gameCell._g.pct || 0) + "%" + (_gameCell._complete ? "  ★" : "")
                                    font.pixelSize: vpx(12); font.family: global.fonts.sans
                                    color: _gameCell._complete ? _textGold : _textMuted
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }
                            }
                        }
                    }

                    Item {
                        id: _glowSrc
                        anchors.fill: parent; visible: false
                        Rectangle { anchors.fill: parent; color: "#1a1a1a" }
                        Image {
                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: _gamesGrid.imgH
                            source: _gameArt.source
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true; smooth: true
                        }
                    }
                    FastBlur {
                        anchors.fill: _glowSrc
                        anchors.margins: vpx(-16)
                        source: _glowSrc; radius: 72
                        transparentBorder: true
                        opacity: _gameCell.isCurrent && _gamesGrid.activeFocus ? 0.32 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }

                    Rectangle {
                        id: _selRect
                        anchors.fill: parent
                        property real borderExtra: 0
                        anchors.margins: vpx(-3.5) - borderExtra
                        border.width: vpx(1.5) + borderExtra
                        border.color: _borderSelection
                        color: "transparent"
                        opacity: 0
                        Behavior on border.color { ColorAnimation { duration: 200 } }

                        SequentialAnimation on opacity {
                            running: _gameCell.isCurrent && _gamesGrid.activeFocus
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
                }

                onIsCurrentChanged: {
                    if (isCurrent && _gamesGrid.activeFocus) _borderPulse.restart()
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: { root._gamesSelIdx = index; _gamesGrid.forceActiveFocus(); }
                }
            }

            Keys.onUpPressed: {
                event.accepted = true;
                if (root._gamesSelIdx >= _gamesGrid._cols) root._gamesSelIdx -= _gamesGrid._cols;
                _gamesGrid.positionViewAtIndex(root._gamesSelIdx, GridView.Contain);
            }
            Keys.onDownPressed: {
                event.accepted = true;
                if (root._gamesSelIdx + _gamesGrid._cols < root._gamesList.length)
                    root._gamesSelIdx += _gamesGrid._cols;
                _gamesGrid.positionViewAtIndex(root._gamesSelIdx, GridView.Contain);
            }
            Keys.onLeftPressed: {
                event.accepted = true;
                if (root._gamesSelIdx > 0) root._gamesSelIdx--;
                _gamesGrid.positionViewAtIndex(root._gamesSelIdx, GridView.Contain);
            }
            Keys.onRightPressed: {
                event.accepted = true;
                if (root._gamesSelIdx < root._gamesList.length - 1) root._gamesSelIdx++;
                _gamesGrid.positionViewAtIndex(root._gamesSelIdx, GridView.Contain);
            }
            Keys.onPressed: {
                if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                    event.accepted = true;
                    var g = root._gamesList[root._gamesSelIdx];
                    if (g && g.id !== "") {
                        root._resolvedId = g.id;
                        root._gamesList = [];
                        root._activeTab = "achievements";
                        root.load();
                    }
                    return;
                }
                if (api.keys.isCancel(event) || event.key === Qt.Key_Escape) {
                    event.accepted = true; root.closeRequested(); return;
                }
                if (api.keys.isNextPage(event)) { event.accepted = true; root._activeTab = "achievements"; return; }
                if (api.keys.isPrevPage(event)) { event.accepted = true; root._activeTab = "info"; return; }
            }
        }
    }

    Keys.onPressed: {
        if (api.keys.isCancel(event) || event.key === Qt.Key_Escape) {
            event.accepted = true; root.closeRequested();
        }
    }
}
