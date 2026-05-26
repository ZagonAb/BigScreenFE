// BigScreenFE Theme
// Copyright (C) 2026 Gonzalo
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/

import QtQuick 2.15
import QtGraphicalEffects 1.15
import "Utils.js" as Utils

FocusScope {
    id: root

    property var game: null
    property bool lightTheme: false

    signal closeRequested()
    signal playRequested()
    signal focusSearchRequested()

    readonly property color _hubBg: lightTheme ? "#dfe3e8" : "#1c222b"
    readonly property color _cardBg: lightTheme ? "#ffffff" : "#2a3447"
    readonly property color _textPrimary: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _textSecondary: lightTheme ? "#5a6472" : "#a0aab5"
    readonly property color _textMuted: lightTheme ? "#8b929a" : "#607d8b"
    readonly property color _accent: lightTheme ? "#1a6b7a" : "#3db54a"
    readonly property color _buttonBg: lightTheme ? "#cfd4d9" : "#43525e"
    readonly property color _buttonHover: lightTheme ? "#b0b5ba" : "#55585f"
    readonly property color _separator: lightTheme ? "#c8cdd3" : "#253040"
    readonly property color _tabActiveBg: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _tabActiveText: lightTheme ? "#ffffff" : "#0d1117"
    readonly property color _tabInactiveText: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _tabInactiveBg: "transparent"
    readonly property color _tabFocusedBg: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _tabFocusedText: lightTheme ? "#ffffff" : "#0d1117"
    readonly property color _ratingLow: "#c0392b"
    readonly property color _ratingMed: "#e0a020"
    readonly property color _ratingHigh: "#3db54a"

    function smartBack() {
        if (_mediaViewLoader.active) {
            _mediaViewLoader.active = false
            var secMV = root._activeSlot === 0 ? _loaderA.item : _loaderB.item
            if (secMV && secMV.hasGrid) secMV.gridFocusAtZero()
                return
        }
        if (_tabList.activeFocus) {
            _flick.contentY = 0;
            _playBtn.forceActiveFocus();
        } else if (root.gridHasFocus) {
            _flick.contentY = _heroZone.height + _actionBar.height - root.searchBarHeight;
            _tabList.forceActiveFocus();
        } else {
            root._navigateBack();
        }
    }

    property real searchBarHeight: 0
    readonly property bool playHasFocus: _playBtn.activeFocus
    readonly property bool tabHasFocus: _tabList.activeFocus
    readonly property bool gridHasFocus: {
        if (_activeTab === 0) return false;
        var sec = _activeSlot === 0 ? _loaderA.item : _loaderB.item;
        return sec ? sec.gridActiveFocus : false;
    }

    readonly property bool raGridHasFocus: gridHasFocus && (_activeTab === _raTabIndex)
    readonly property bool mediaViewOpen: _mediaViewLoader.active

    readonly property var currentGridGame: {
        if (_activeTab === 0) return null;
        var sec = _activeSlot === 0 ? _loaderA.item : _loaderB.item;
        return (sec && sec.currentGame) ? sec.currentGame : null;
    }

    readonly property string _bgSrc: {
        if (!game) return "";
        return game.assets.background || game.assets.screenshot || "";
    }

    readonly property string _logoSrc: {
        if (!game) return "";
        return game.assets.logo || "";
    }

    readonly property string _lastPlayed: game ? Utils.formatDate(game.lastPlayed) : ""
    readonly property bool _hasLastPlayed: _lastPlayed !== ""
    readonly property string _playTime: game ? Utils.formatPlayTime(game.playTime) : ""
    readonly property bool _hasPlayTime: game && game.playTime > 0
    readonly property bool _hasRating: game && game.rating > 0
    readonly property int _ratingInt: game ? Math.round(game.rating * 100) : 0

    readonly property string _publisherName: {
        if (!game) return "";
        if (game.publisherList && game.publisherList.length > 0) return game.publisherList[0];
        if (game.publisher && game.publisher !== "") return game.publisher.split(",")[0].trim();
        return "";
    }

    readonly property string _genreName: game ? Utils.getFirstGenre(game) : ""

    readonly property var _tabs: {
        var t = ["GAME INFO"];
        t.push("MEDIA");
        if (_publisherName !== "") t.push("MORE BY " + _publisherName.toUpperCase());
        if (_genreName !== "") t.push("MORE " + _genreName.toUpperCase());
        t.push("YOUR STUFF");
        return t;
    }

    readonly property int _raTabIndex: _tabs.length - 1
    readonly property int _mediaTabIndex: 1

    property int _activeTab: 0

    Rectangle {
        anchors.fill: parent
        color: _hubBg
        Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
    }

    Flickable {
        id: _flick
        anchors.fill: parent
        clip: true
        interactive: true
        flickableDirection: Flickable.VerticalFlick
        contentHeight: _mainCol.implicitHeight + vpx(40)

        Behavior on contentY {
            enabled: !root._suppressFlickAnim
            NumberAnimation { duration: 280; easing.type: Easing.InOutQuad }
        }

        Column {
            id: _mainCol
            width: _flick.width
            spacing: 0

            Item {
                id: _heroZone
                width: parent.width
                height: Math.max(vpx(120), root.height * 0.45) + root.searchBarHeight

                Image {
                    id: _heroImg
                    width: parent.width
                    height: parent.height * 1.3
                    source: root._bgSrc
                    fillMode: Image.PreserveAspectCrop
                    verticalAlignment: Image.AlignVCenter
                    asynchronous: true
                    smooth: true
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: vpx(80)
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 1.0; color: root._hubBg }
                    }
                }

                Item {
                    anchors {
                        left: parent.left
                        bottom: parent.bottom
                        leftMargin: vpx(48)
                        bottomMargin: vpx(18)
                    }
                    width: vpx(320)
                    height: vpx(100)

                    Image {
                        id: _logoImg
                        anchors.fill: parent
                        source: root._logoSrc
                        fillMode: Image.PreserveAspectFit
                        horizontalAlignment: Image.AlignLeft
                        verticalAlignment: Image.AlignBottom
                        asynchronous: true
                        smooth: true
                        mipmap: true
                        visible: status === Image.Ready && source !== ""
                    }

                    Text {
                        anchors { left: parent.left; bottom: parent.bottom }
                        width: parent.width
                        visible: !_logoImg.visible
                        text: root.game ? root.game.title : ""
                        color: root._textPrimary
                        font.family: global.fonts.sans
                        font.pixelSize: vpx(38)
                        font.bold: true
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                        style: Text.Outline
                        styleColor: root.lightTheme ? "#ffffff" : "#000000"
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: _actionBar.height + _sepTop.height + _tabBarItem.height + _sepBottom.height + _sectionItem.height
                color: _hubBg
                Behavior on color { ColorAnimation { duration: 400 } }

                Column {
                    width: parent.width
                    spacing: 0

                    Item {
                        id: _actionBar
                        width: parent.width
                        height: vpx(72)

                        Item {
                            id: _playBtn
                            anchors {
                                left: parent.left
                                leftMargin: vpx(48)
                                verticalCenter: parent.verticalCenter
                            }
                            width: vpx(200)
                            height: vpx(44)
                            focus: true

                            readonly property bool _focused: activeFocus

                            Rectangle {
                                anchors.fill: parent
                                radius: vpx(4)
                                color: _playBtn._focused ? root._accent : root._buttonBg
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }

                            Row {
                                anchors {
                                    left: parent.left
                                    leftMargin: vpx(16)
                                    verticalCenter: parent.verticalCenter
                                }
                                spacing: vpx(10)

                                Item {
                                    width: vpx(22)
                                    height: vpx(22)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Image {
                                        id: _playIcon
                                        anchors.fill: parent
                                        source: "assets/icons/play.svg"
                                        fillMode: Image.PreserveAspectFit
                                        mipmap: true
                                        visible: false
                                    }

                                    ColorOverlay {
                                        anchors.fill: _playIcon
                                        source: _playIcon
                                        color: "#ffffff"
                                    }
                                }

                                Text {
                                    text: "Play"
                                    color: "#ffffff"
                                    font.family: global.fonts.sans
                                    font.pixelSize: vpx(16)
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Keys.onPressed: {
                                if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                                    event.accepted = true;
                                    if (root.game) root.game.launch();
                                    return;
                                }
                                if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                                    event.accepted = true;
                                    root._navigateBack();
                                    return;
                                }
                                if (!event.isAutoRepeat && event.key === Qt.Key_Up) {
                                    event.accepted = true;
                                    root.focusSearchRequested();
                                    return;
                                }
                                if (!event.isAutoRepeat && event.key === Qt.Key_Down) {
                                    event.accepted = true;
                                    _flick.contentY = _heroZone.height + _actionBar.height - root.searchBarHeight;
                                    _tabList.forceActiveFocus();
                                    return;
                                }
                                if (!event.isAutoRepeat && api.keys.isNextPage(event)) {
                                    event.accepted = true;
                                    if (root._activeTab < root._tabs.length - 1) root._activeTab++;
                                    return;
                                }
                                if (!event.isAutoRepeat && api.keys.isPrevPage(event)) {
                                    event.accepted = true;
                                    if (root._activeTab > 0) root._activeTab--;
                                    return;
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: { _playBtn.forceActiveFocus(); if (root.game) root.game.launch(); }
                            }
                        }

                        Column {
                            id: _lastPlayedCol
                            anchors {
                                left: _playBtn.right
                                leftMargin: vpx(28)
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: vpx(3)
                            visible: root._hasLastPlayed

                            Text {
                                text: "LAST PLAYED"
                                color: root._textMuted
                                font.family: global.fonts.sans
                                font.pixelSize: vpx(10)
                                font.bold: true
                                font.letterSpacing: vpx(0.8)
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            Text {
                                text: root._lastPlayed
                                color: root._textPrimary
                                font.family: global.fonts.sans
                                font.pixelSize: vpx(15)
                                font.bold: true
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        Column {
                            id: _playTimeCol
                            anchors {
                                left: root._hasLastPlayed ? _lastPlayedCol.right : _playBtn.right
                                leftMargin: vpx(28)
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: vpx(3)
                            visible: root._hasPlayTime

                            Text {
                                text: "PLAY TIME"
                                color: root._textMuted
                                font.family: global.fonts.sans
                                font.pixelSize: vpx(10)
                                font.bold: true
                                font.letterSpacing: vpx(0.8)
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                            Text {
                                text: root._playTime
                                color: root._textPrimary
                                font.family: global.fonts.sans
                                font.pixelSize: vpx(15)
                                font.bold: true
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        Column {
                            anchors {
                                left: {
                                    if (root._hasPlayTime) return _playTimeCol.right;
                                    if (root._hasLastPlayed) return _lastPlayedCol.right;
                                    return _playBtn.right;
                                }
                                leftMargin: vpx(28)
                                verticalCenter: parent.verticalCenter
                            }
                            spacing: vpx(4)
                            visible: root._hasRating

                            Text {
                                text: "RATING"
                                color: root._textMuted
                                font.family: global.fonts.sans
                                font.pixelSize: vpx(10)
                                font.bold: true
                                font.letterSpacing: vpx(0.8)
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            Row {
                                spacing: vpx(10)

                                Text {
                                    text: root._ratingInt + " / 100"
                                    color: root._textPrimary
                                    font.family: global.fonts.sans
                                    font.pixelSize: vpx(15)
                                    font.bold: true
                                    anchors.verticalCenter: parent.verticalCenter
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                }

                                Item {
                                    width: vpx(110)
                                    height: vpx(4)
                                    anchors.verticalCenter: parent.verticalCenter

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: vpx(2)
                                        color: root._separator
                                        Behavior on color { ColorAnimation { duration: 200 } }
                                    }
                                    Rectangle {
                                        width: parent.width * (root.game ? root.game.rating : 0)
                                        height: parent.height
                                        radius: vpx(2)
                                        color: {
                                            var r = root.game ? root.game.rating : 0;
                                            if (r >= 0.75) return root._ratingHigh;
                                            if (r >= 0.5) return root._ratingMed;
                                            return root._ratingLow;
                                        }
                                        Behavior on width { NumberAnimation { duration: 500; easing.type: Easing.OutQuad } }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: _sepTop
                        width: parent.width - vpx(96)
                        x: vpx(48)
                        height: vpx(1)
                        color: root._separator
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Item {
                        id: _tabBarItem
                        width: parent.width
                        height: vpx(52)

                        ListView {
                            id: _tabList
                            anchors {
                                horizontalCenter: parent.horizontalCenter
                                verticalCenter: parent.verticalCenter
                            }
                            width: contentWidth
                            height: vpx(36)
                            orientation: ListView.Horizontal
                            interactive: false
                            spacing: vpx(6)
                            model: root._tabs

                            Keys.onPressed: {
                                if (!event.isAutoRepeat && event.key === Qt.Key_Up) {
                                    event.accepted = true;
                                    _flick.contentY = 0;
                                    _playBtn.forceActiveFocus();
                                    return;
                                }
                                if (!event.isAutoRepeat && event.key === Qt.Key_Down) {
                                    event.accepted = true;
                                    var sec = root._activeSlot === 0 ? _loaderA.item : _loaderB.item;
                                    if (sec && sec.hasGrid) sec.gridFocusAtZero();
                                    return;
                                }
                                if (!event.isAutoRepeat && event.key === Qt.Key_Left) {
                                    event.accepted = true;
                                    if (root._activeTab > 0) root._activeTab--;
                                    return;
                                }
                                if (!event.isAutoRepeat && event.key === Qt.Key_Right) {
                                    event.accepted = true;
                                    if (root._activeTab < root._tabs.length - 1) root._activeTab++;
                                    return;
                                }
                                if (!event.isAutoRepeat && api.keys.isNextPage(event)) {
                                    event.accepted = true;
                                    if (root._activeTab < root._tabs.length - 1) root._activeTab++;
                                    return;
                                }
                                if (!event.isAutoRepeat && api.keys.isPrevPage(event)) {
                                    event.accepted = true;
                                    if (root._activeTab > 0) root._activeTab--;
                                    return;
                                }
                                if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                                    event.accepted = true;
                                    if (root._activeTab > 0) {
                                        var secA = root._activeSlot === 0 ? _loaderA.item : _loaderB.item;
                                        if (secA && secA.hasGrid) secA.gridFocusAtZero();
                                    }
                                    return;
                                }
                                if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                                    event.accepted = true;
                                    _flick.contentY = 0;
                                    _playBtn.forceActiveFocus();
                                    return;
                                }
                            }

                            delegate: Item {
                                width: Math.min(_tabTxt.implicitWidth, vpx(160)) + vpx(28)
                                height: _tabList.height

                                readonly property bool _active: root._activeTab === index
                                readonly property bool _focused: _tabList.activeFocus && _active
                                readonly property bool _playMode: root.playHasFocus

                                readonly property bool _isRA: index === root._raTabIndex

                                Rectangle {
                                    anchors.fill: parent
                                    radius: vpx(18)
                                    color: {
                                        if (_focused) return root._tabFocusedBg
                                            if (_active) return root.lightTheme ? Qt.rgba(0,0,0,0.08) : Qt.rgba(1,1,1,0.12)
                                                return "transparent"
                                    }
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }

                                Text {
                                    id: _tabTxt
                                    anchors.centerIn: parent
                                    text: modelData
                                    color: {
                                        if (_focused) return root._tabFocusedText
                                            if (_active) return root._textPrimary
                                                return root._textSecondary
                                    }
                                    font.family: global.fonts.sans
                                    font.pixelSize: vpx(13)
                                    font.bold: _active || _focused
                                    font.letterSpacing: vpx(0.7)
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                    width: Math.min(implicitWidth, vpx(160))
                                    elide: Text.ElideRight
                                }

                                MouseArea {
                                    id: _tabHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    onClicked: {
                                        root._activeTab = index;
                                        _flick.contentY = _heroZone.height + _actionBar.height - root.searchBarHeight;
                                        _tabList.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        id: _sepBottom
                        width: parent.width - vpx(96)
                        x: vpx(48)
                        height: vpx(1)
                        color: root._separator
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Item {
                        id: _sectionItem
                        width: parent.width
                        height: {
                            var sec = _activeSlot === 0 ? _loaderA.item : _loaderB.item;
                            if (sec && (root._activeTab === root._raTabIndex || root._activeTab === root._mediaTabIndex))
                                return Math.max(vpx(420), sec.implicitHeight + vpx(48));
                            return vpx(420);
                        }

                        Loader {
                            id: _loaderA
                            anchors {
                                top: parent.top; left: parent.left; right: parent.right
                                topMargin: vpx(24); leftMargin: vpx(48); rightMargin: vpx(48)
                            }
                            width: parent.width - vpx(96)
                            active: root._activeSlot === 0
                            visible: active
                            sourceComponent: root._slotComp(0)
                            onItemChanged: root._connectSection(item)
                        }

                        Loader {
                            id: _loaderB
                            anchors {
                                top: parent.top; left: parent.left; right: parent.right
                                topMargin: vpx(24); leftMargin: vpx(48); rightMargin: vpx(48)
                            }
                            width: parent.width - vpx(96)
                            active: root._activeSlot === 1
                            visible: active
                            sourceComponent: root._slotComp(1)
                            onItemChanged: root._connectSection(item)
                        }
                    }
                }
            }
        }
    }

    Component {
        id: _gameInfoComp
        GameInfoSection {
            width: parent ? parent.width : 0
            game: root.game
            lightTheme: root.lightTheme
        }
    }

    Component {
        id: _publisherComp
        MoreByPublisherSection {
            width: parent ? parent.width : 0
            game: root.game
            lightTheme: root.lightTheme
        }
    }

    Component {
        id: _genreComp
        MoreByGenreSection {
            width: parent ? parent.width : 0
            game: root.game
            lightTheme: root.lightTheme
        }
    }

    Component {
        id: _raInfoComp
        RAGameInfoSection {
            width: parent ? parent.width : 0
            game: root.game
            lightTheme: root.lightTheme
        }
    }

    Component {
        id: _mediaComp
        GameMediaSection {
            width: parent ? parent.width : 0
            game: root.game
            lightTheme: root.lightTheme
        }
    }

    property int _activeSlot: 0
    property int _slot0Tab: 0
    property int _slot1Tab: -1
    property var _gameStack: []
    property bool _isNavigating: false

    function _navigateToGame(newGame) {
        _isNavigating = true;
        var stack = _gameStack.slice();
        stack.push(game);
        _gameStack = stack;
        game = newGame;
        _isNavigating = false;
        _flick.contentY = 0;
        _restoreScrollTimer.savedY = 0;
        _playBtn.forceActiveFocus();
    }

    function _navigateBack() {
        if (_gameStack.length > 0) {
            _isNavigating = true;
            var stack = _gameStack.slice();
            var prev = stack.pop();
            _gameStack = stack;
            game = prev;
            _isNavigating = false;
            _flick.contentY = 0;
            _restoreScrollTimer.savedY = 0;
            _playBtn.forceActiveFocus();
        } else {
            root.closeRequested();
        }
    }

    function _compForTab(tab) {
        if (tab === root._raTabIndex) return _raInfoComp;
        if (tab === root._mediaTabIndex) return _mediaComp;

        switch (tab) {
            case 0: return _gameInfoComp;
            case 2: return _publisherName !== "" ? _publisherComp : _genreComp;
            case 3: return _genreName !== "" ? _genreComp : null;
            default: return null;
        }
    }

    function _slotComp(slot) {
        var tab = (slot === 0) ? _slot0Tab : _slot1Tab;
        return tab >= 0 ? _compForTab(tab) : null;
    }

    function _connectSection(item) {
        if (item && typeof item.tabFocusRequested !== "undefined") {
            item.tabFocusRequested.connect(function() {
                _tabList.currentIndex = root._activeTab;
                _tabList.forceActiveFocus();
            });
        }
        if (item && typeof item.gameSelected !== "undefined") {
            item.gameSelected.connect(function(newGame) {
                root._navigateToGame(newGame);
            });
        }
        if (item && typeof item.mediaViewRequested !== "undefined") {
            item.mediaViewRequested.connect(function(mediaList, startIndex) {
                _mediaViewLoader.mediaList = mediaList;
                _mediaViewLoader.startIndex = startIndex;
                _mediaViewLoader.active = true;
                _focusMediaViewTimer.start();
            });
        }
    }

    on_ActiveTabChanged: {
        var savedY = _flick.contentY;
        if (_activeSlot === 0) {
            _slot1Tab = _activeTab;
            _activeSlot = 1;
        } else {
            _slot0Tab = _activeTab;
            _activeSlot = 0;
        }
        _suppressFlickAnim = true;
        _restoreScrollTimer.savedY = savedY;
        _restoreScrollTimer.restart();
    }

    property bool _suppressFlickAnim: false

    Timer {
        id: _restoreScrollTimer
        property real savedY: 0
        interval: 48
        repeat: false
        onTriggered: {
            _flick.contentY = savedY;
            root._suppressFlickAnim = false;
        }
    }

    Loader {
        id: _mediaViewLoader
        anchors {
            top: parent.top
            bottom: parent.bottom
            left: parent.left
            right: parent.right
            topMargin: -root.searchBarHeight
        }
        z: 900
        active: false
        visible: active

        property var mediaList: []
        property int startIndex: 0

        sourceComponent: Component {
            GameMediaView {
                mediaList: _mediaViewLoader.mediaList
                startIndex: _mediaViewLoader.startIndex
                lightTheme: root.lightTheme
                onCloseRequested: {
                    _mediaViewLoader.active = false
                    var sec = root._activeSlot === 0 ? _loaderA.item : _loaderB.item
                    if (sec && sec.hasGrid) sec.gridFocusAtZero()
                }
            }
        }
    }

    Timer {
        id: _focusMediaViewTimer
        interval: 0
        repeat: false
        onTriggered: { if (_mediaViewLoader.item) _mediaViewLoader.item.forceActiveFocus() }
    }

    onGameChanged: {
        _activeTab = 0; _slot0Tab = 0; _slot1Tab = -1; _activeSlot = 0;
        if (!_isNavigating) _gameStack = [];
        _mediaViewLoader.active = false;
    }
    onFocusChanged: { if (focus) _playBtn.forceActiveFocus(); }

    Keys.onPressed: {
        if (!event.isAutoRepeat && api.keys.isCancel(event)) {
            event.accepted = true;
            root._navigateBack();
        }
    }
}
