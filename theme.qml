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

FocusScope {
    id: root
    focus: true

    function vpx(value) {
        return value * (width / 1280);
    }

    property string currentScreen: "home"

    property bool lightTheme: api.memory.has("light_theme")
    ? api.memory.get("light_theme") === "true"
    : false

    function toggleTheme() {
        lightTheme = !lightTheme;
        api.memory.set("light_theme", lightTheme ? "true" : "false");
    }

    readonly property color theme_bgPrimary: lightTheme ? "#dfe3e8" : "#05070a"
    readonly property color theme_bgSecondary: lightTheme ? "#ffffff" : "#121926"
    readonly property color theme_bgCard: lightTheme ? "#e8ecf0" : "#1c2533"
    readonly property color theme_textPrimary: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color theme_textMuted: lightTheme ? "#5a6472" : "#667788"
    readonly property color theme_textAccent: lightTheme ? "#1a6b7a" : "#57cbde"
    readonly property color theme_clockText: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color theme_iconColor: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color theme_separator: lightTheme ? "#aab0b8" : "#555555"
    readonly property color theme_searchBgIdle: lightTheme ? "#dfe3e8" : "#05070a"
    readonly property color theme_searchBgActive: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color theme_barBg: lightTheme ? "#c8cdd3" : "#05070a"

    readonly property bool onHome: currentScreen === "home"
    readonly property bool onLibrary: currentScreen === "library"
    readonly property bool onHub: currentScreen === "hub"
    readonly property bool onRA: currentScreen === "ra"

    property string _raGameId: ""

    property string _searchOrigin: "home"
    property bool _searchFromHub: false

    function goHome() {
        _closeHub();
        _searchFromHub = false;
        currentScreen = "home";
        if (homeLoader.item) homeLoader.item.forceActiveFocus();
    }

    function goLibrary() {
        _closeHub();
        _searchFromHub = false;
        _searchOrigin = "home";
        currentScreen = "library";
        gameGridLoader.active = true;
        _focusGridTimer.start();
    }

    function goLibraryKeepFocus() {
        if (currentScreen === "hub") { _searchOrigin = "hub"; _searchFromHub = true; }
        else if (currentScreen === "home") _searchOrigin = "home";
        else _searchOrigin = "library";
        currentScreen = "library";
        gameGridLoader.active = true;
        _restoreSearchFocusTimer.start();
    }

    function _clearSearch() {
        searchBar.clearSearchImmediate();
        searchBar.focus = false;
        _searchFromHub = false;
    }

    function _goToSearchOrigin() {
        if (_searchOrigin === "hub" && hubLoader.active && hubLoader.item) {
            currentScreen = "hub";
            hubLoader.item.forceActiveFocus();
        } else if (_searchOrigin === "hub") {
            currentScreen = "home";
            _focusHomeTimer.start();
        } else if (_searchOrigin === "home") {
            currentScreen = "home";
            if (homeLoader.item) homeLoader.item.forceActiveFocus();
        } else {
            currentScreen = "home";
            _focusHomeTimer.start();
        }
    }

    function _returnToSearchOrigin() {
        _clearSearch();
        _goToSearchOrigin();
    }

    function openHub(game) {
        hubLoader._prevScreen = currentScreen;
        hubLoader.game = game;
        hubLoader.active = true;
        currentScreen = "hub";
        _focusHubTimer.start();
    }

    function openRA(game, raGameId) {
        raLoader._prevScreen = currentScreen;
        raLoader.game = game;
        root._raGameId = raGameId || "";
        raLoader.active = true;
        currentScreen = "ra";
        _focusRATimer.start();
    }

    function _closeRA() {
        var prev = raLoader._prevScreen;
        currentScreen = prev;
        raLoader.active = false;
        raLoader.game = null;
        root._raGameId = "";
        if (prev === "home" && homeLoader.item) {
            homeLoader.item.restoreScrollFromRA();
        } else if (prev === "hub") {
            _focusHubTimer.start();
        } else {
            _focusGridTimer.start();
        }
    }

    function _closeHub() {
        var prev = hubLoader._prevScreen;
        currentScreen = prev;
        hubLoader.active = false;
        hubLoader.game = null;
        if (_searchOrigin === "hub")
            _searchOrigin = (prev === "home") ? "home" : "library";
    }

    Timer { id: _focusGridTimer; interval: 0; repeat: false; onTriggered: { if (gameGridLoader.item) gameGridLoader.item.forceActiveFocus() } }
    Timer { id: _focusHomeTimer; interval: 0; repeat: false; onTriggered: { if (homeLoader.item) homeLoader.item.forceActiveFocus() } }
    Timer { id: _restoreSearchFocusTimer; interval: 0; repeat: false; onTriggered: searchBar.activate() }
    Timer { id: _focusHubTimer; interval: 0; repeat: false; onTriggered: { if (hubLoader.item) hubLoader.item.forceActiveFocus() } }
    Timer { id: _focusCollecTimer; interval: 0; repeat: false; onTriggered: { collecBar.focus = true } }
    Timer { id: _focusRATimer; interval: 0; repeat: false; onTriggered: { if (raLoader.item) raLoader.item.forceActiveFocus() } }

    Timer {
        id: _logoSplashTimer
        interval: 3000
        repeat: false
        onTriggered: splashScreen.hide()
    }

    function _restoreFocusAfterHub() {
        if (hubLoader._prevScreen === "library") {
            _focusGridTimer.start();
        } else {
            _focusHomeTimer.start();
        }
    }

    readonly property string _bottomActiveView: {
        if (onRA) return "ra";
        if (onHub) return "hub";
        if (searchBar.credentialsOpen) {
            return searchBar.credentialsButtonFocused ? "search_creds_btn" : "search_creds";
        }
        if (searchBar.themeFocused) return "search_theme";
        if (onHome) {
            if (homeLoader.item && homeLoader.item.onViewMoreFocused) return "home_viewmore";
            if (homeLoader.item && homeLoader.item.raStripFocused) return "home_ra";
            if (searchBar.raFocused) return "search_ra";
            if (searchBar.hasFocus) return "search";
            return "grid";
        }
        if (searchBar.raFocused) return "search_ra";
        if (searchBar.hasFocus) return "search";
        if (collecBar.activeFocus) return "collec";
        var gridItem = gameGridLoader.item;
        if (gridItem && gridItem.isCollections && !gridItem.inCollectionGames) return "collections";
        return "grid";
    }

    readonly property var _bottomGame: {
        if (onHub && hubLoader.item) {
            var hubItem = hubLoader.item;
            if (hubItem._activeTab > 0 && hubItem.currentGridGame)
                return hubItem.currentGridGame;
            return hubLoader.game;
        }
        if (onHome && homeLoader.item) {
            var rec = homeLoader.item.recCurrentGame;
            if (rec) return rec;
            return homeLoader.item.currentGame;
        }
        if (onLibrary && gameGridLoader.item) return gameGridLoader.item.currentEntry;
        return null;
    }

    readonly property bool _bottomIsRoot: onHome
    readonly property string activeView: _bottomActiveView

    SortFilterProxyModel {
        id: searchResultModel
        sourceModel: api.allGames
        sorters: RoleSorter { roleName: "sortBy"; sortOrder: Qt.AscendingOrder }
        filters: ExpressionFilter {
            id: searchFilter
            enabled: searchBar.isSearching
            expression: {
                var q = searchBar.searchQuery;
                if (!q) return true;
                var fields = [
                    (model.title || "").toLowerCase(),
                    (model.developer || "").toLowerCase(),
                    (model.publisher || "").toLowerCase(),
                    (model.genre || "").toLowerCase()
                ];
                for (var i = 0; i < fields.length; i++) {
                    if (fields[i].indexOf(q) !== -1) return true;
                }
                return false;
            }
        }
    }

    Item {
        id: contentRoot
        anchors.fill: parent
        z: 0

        Item {
            id: blurableLayer
            anchors.fill: parent

            property real _blurRadius: searchBar.credentialsOpen ? 48 : 0
            Behavior on _blurRadius { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
            layer.enabled: searchBar.credentialsOpen || _blurRadius > 0.5
            layer.effect: FastBlur { radius: blurableLayer._blurRadius }

            Rectangle {
                anchors.fill: parent
                color: root.lightTheme ? "#dfe3e8" : "#0b1117"
                opacity: root.onHub && hubLoader.item && hubLoader.item.playHasFocus ? 0.0 : 1.0
                Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
                Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
            }

            Loader {
                id: homeLoader
                anchors.fill: parent
                active: false
                visible: root.onHome && status === Loader.Ready
                z: 1

                sourceComponent: HomeView {
                    lightTheme: root.lightTheme
                    onGoToLibrary: root.goLibrary()
                    onFocusSearchRequested: searchBar.activate()
                    onOpenHub: root.openHub(game)
                    onOpenRA: root.openRA(game, raGameId)

                    Component.onCompleted: {
                        console.log("HomeView cargado completamente");
                        Qt.callLater(function() { splashScreen.opacity = 0; resetFocus(); });
                    }
                }
                onStatusChanged: { if (status === Loader.Ready) console.log("HomeLoader listo") }
            }

            Rectangle {
                id: collecBarBg
                anchors { left: parent.left; right: parent.right }
                y: searchBar.height
                height: collecBar.height + vpx(3)
                z: 1000
                color: root.theme_barBg
                opacity: root.onLibrary && gameGridLoader.item && gameGridLoader.item.contentY > vpx(10) ? 0.97 : 0.0
                Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
                Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
            }

            NavButton {
                id: btnL1; label: "L1"; side: "left"
                anchors { verticalCenter: collecBar.verticalCenter; left: parent.left; leftMargin: vpx(55) }
                width: vpx(40); height: vpx(30); z: 1001
                visible: root.onLibrary
                onClicked: collecBar.prevTab()
                lightTheme: root.lightTheme
            }

            NavButton {
                id: btnR1; label: "R1"; side: "right"
                anchors { verticalCenter: collecBar.verticalCenter; right: parent.right; rightMargin: vpx(55) }
                width: vpx(40); height: vpx(30); z: 1001
                visible: root.onLibrary
                onClicked: collecBar.nextTab()
                lightTheme: root.lightTheme
            }

            CollecListView {
                id: collecBar
                anchors {
                    left: parent.left; right: parent.right
                    leftMargin: vpx(72); rightMargin: vpx(72)
                }
                y: searchBar.height
                height: vpx(56)
                z: 1000
                visible: root.onLibrary
                enabled: root.onLibrary
                isSearching: searchBar.isSearching
                lightTheme: root.lightTheme

                Keys.onPressed: {
                    if (api.keys.isPrevPage(event)) { event.accepted = true; collecBar.prevTab() }
                    if (api.keys.isNextPage(event)) { event.accepted = true; collecBar.nextTab() }
                }
                onCancelRequested: {
                    if (searchBar.hasText || searchBar.isSearching) {
                        searchBar.clearSearchImmediate();
                        _focusCollecTimer.start();
                    } else if (_searchFromHub && !hubLoader.active) {
                        _searchFromHub = false;
                        collecBar.focus = false;
                        root.goHome();
                    } else {
                        collecBar.focus = false;
                        root._goToSearchOrigin();
                    }
                }
                onFocusUpRequested: { collecBar.focus = false; searchBar.activate() }
                Keys.onDownPressed: {
                    if (gameGridLoader.item) gameGridLoader.item.forceActiveFocus()
                        collecBar.focus = false
                }
            }

            Loader {
                id: gameGridLoader
                anchors {
                    top: collecBar.bottom; left: parent.left; right: parent.right
                    leftMargin: vpx(50); rightMargin: vpx(50); topMargin: vpx(12)
                }
                height: parent.height - (collecBar.y + collecBar.height + vpx(12)) - bottomBar.height
                z: 0
                active: false
                visible: root.onLibrary && status === Loader.Ready

                sourceComponent: GamesGridView {
                    id: gameGrid

                    focus: root.onLibrary

                    lightTheme: root.lightTheme
                    gamesModel: searchBar.isSearching ? searchResultModel : collecBar.currentGames
                    isCollections: searchBar.isSearching ? false : collecBar.currentIsCollections
                    currentSortId: sortMenu.activeSortId
                    preserveSourceOrder: collecBar.currentShortName === "lastplayed"

                    onPrevTabRequested: collecBar.prevTab()
                    onNextTabRequested: collecBar.nextTab()
                    onExitRequested: {
                        focus = false
                        collecBar.focus = true
                    }
                    onSortMenuRequested: if (collecBar.currentShortName !== "lastplayed") sortMenu.open()
                    onOpenHub: root.openHub(game)

                    Keys.onUpPressed: {
                        if (!isCollections || !inCollectionGames) {
                            focus = false
                            collecBar.focus = true
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        propagateComposedEvents: true
                        onClicked: { parent.forceActiveFocus(); mouse.accepted = false }
                        onPressed: mouse.accepted = false
                    }
                }
                onStatusChanged: { if (status === Loader.Ready) console.log("GameGridLoader listo") }
            }

            Loader {
                id: hubLoader
                anchors {
                    top: parent.top
                    left: parent.left
                    right: parent.right
                }
                height: parent.height - bottomBar.height
                z: 500
                active: false
                visible: root.onHub && status === Loader.Ready

                property var game: null
                property string _prevScreen: "home"

                sourceComponent: GameHubView {
                    game: hubLoader.game
                    searchBarHeight: searchBar.height
                    lightTheme: root.lightTheme
                    onCloseRequested: {
                        console.log("[closeHub] prev=", hubLoader._prevScreen);
                        root._closeHub();
                        root._restoreFocusAfterHub();
                    }
                    onPlayRequested: {
                        if (hubLoader.game) hubLoader.game.launch();
                    }
                    onFocusSearchRequested: {
                        searchBar.activate();
                    }
                }
            }

            Loader {
                id: raLoader
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: parent.height - bottomBar.height
                z: 600
                active: false
                visible: root.onRA && status === Loader.Ready

                property var game: null
                property string _prevScreen: "home"

                sourceComponent: RAWebBrowser {
                    game: raLoader.game
                    raGameId: root._raGameId
                    lightTheme: root.lightTheme
                    onCloseRequested: root._closeRA()
                }
            }
        }

        SearchBar {
            id: searchBar
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: vpx(48)
            gameGridContentY: root.onLibrary && gameGridLoader.item ? gameGridLoader.item.contentY : vpx(11)
            z: 1002

            lightTheme: root.lightTheme
            onThemeToggleRequested: root.toggleTheme()

            hidden: root.onRA
            || (root.onHub && hubLoader.item && hubLoader.item.mediaViewOpen)

            semiTransparent: root.onHub && hubLoader.item ? hubLoader.item.playHasFocus : false
            solidInHub: root.onHub && hubLoader.item ? hubLoader.item.tabHasFocus : false

            onFocusDownRequested: {
                searchBar.focus = false
                if (root.onHub) { if (hubLoader.item) hubLoader.item.forceActiveFocus() }
                else if (root.onLibrary) { collecBar.focus = true }
                else if (homeLoader.item) homeLoader.item.forceActiveFocus()
            }
            onBackToGridRequested: {
                root._returnToSearchOrigin()
            }
        }

        Connections {
            target: searchBar
            function onIsSearchingChanged() {
                if (searchBar.isSearching && root.onHome) root.goLibraryKeepFocus()
                    if (searchBar.isSearching && root.onHub) root.goLibraryKeepFocus()
            }
            function onHasTextChanged() {
                if (searchBar.hasText && root.onHome) root.goLibraryKeepFocus()
                    if (searchBar.hasText && root.onHub) root.goLibraryKeepFocus()
            }
        }

        BottomBar {
            id: bottomBar
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: vpx(48)
            z: 1002
            lightTheme: root.lightTheme

            activeView: root._bottomActiveView
            currentGame: root._bottomGame
            searchHasText: searchBar.hasText
            isRootGrid: root._bottomIsRoot
            showFilter: !root.onRA
            && root._bottomActiveView === "grid"
            && !root._bottomIsRoot
            && collecBar.currentShortName !== "lastplayed"
            && !searchBar.keyboardOpen

            hubActiveTab: root.onHub && hubLoader.item ? hubLoader.item._activeTab : 0
            hubPlayFocus: root.onHub && hubLoader.item ? hubLoader.item.playHasFocus : false
            hubGridFocus: root.onHub && hubLoader.item ? hubLoader.item.gridHasFocus : false
            hubRaGridFocus: root.onHub && hubLoader.item ? hubLoader.item.raGridHasFocus : false
            raGamesTab: root.onRA && raLoader.item ? raLoader.item.onGamesTab : false
            credsHasText: searchBar.credentialsHasText
            hubMediaTab: root.onHub && hubLoader.item ? hubLoader.item._activeTab === hubLoader.item._mediaTabIndex : false
            hubMediaView: root.onHub && hubLoader.item ? hubLoader.item.mediaViewOpen : false
            keyboardOpen: searchBar.keyboardOpen

            onFilterClicked: sortMenu.open()

            onLogoClicked: {
                _logoSplashTimer.stop()
                splashScreen.opacity = 1.0
                _logoSplashTimer.start()
            }

            onFavoriteClicked: {
                if (root.onHub) {
                    var g = root._bottomGame;
                    if (g) g.favorite = !g.favorite;
                } else if (root.onHome && homeLoader.item) {
                    var g = homeLoader.item.recCurrentGame || homeLoader.item.currentGame
                    if (g) g.favorite = !g.favorite
                } else if (root.onLibrary && gameGridLoader.item) {
                    gameGridLoader.item.toggleFavorite()
                }
            }

            onSelectClicked: {
                if (root._bottomActiveView === "search_theme") {
                    root.toggleTheme();
                    return;
                }
                var game = root._bottomGame;
                if (!game) return;
                root.openHub(game);
            }
            onPlayClicked: {
                if (root.onHub && hubLoader.game) hubLoader.game.launch();
            }

            onBackClicked: {
                if (searchBar.keyboardOpen) {
                    searchBar.closeKeyboard()
                    return
                }
                if (root.onHub) {
                    if (hubLoader.item) hubLoader.item.smartBack();
                } else if (root.onHome) {
                    Qt.quit()
                } else {
                    if (root._bottomActiveView === "search") {
                        if (searchBar.isSearching) {
                            searchBar.backspaceOne()
                        } else {
                            root._returnToSearchOrigin()
                        }
                    } else if (root._bottomActiveView === "collec") {
                        collecBar.focus = false; if (gameGridLoader.item) gameGridLoader.item.forceActiveFocus()
                    } else if (root._bottomActiveView === "collections") {
                        if (gameGridLoader.item) gameGridLoader.item.focus = false; collecBar.focus = true
                    } else {
                        root.goHome()
                    }
                }
            }
        }
    }

    FastBlur {
        anchors.fill: contentRoot
        source: contentRoot
        radius: sortMenu.visible ? 48 : 0
        z: 1999
        Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }
    }

    SortMenu {
        id: sortMenu
        z: 2000
        lightTheme: root.lightTheme
        onMenuClosed: {
            if (gameGridLoader.item) gameGridLoader.item.forceActiveFocus()
        }
    }

    SplashScreen {
        id: splashScreen
        anchors.fill: parent
        z: 3000
        lightTheme: root.lightTheme
    }

    Component.onCompleted: { loadTimer.start() }

    Timer {
        id: loadTimer
        interval: 100
        onTriggered: { console.log("Iniciando carga de HomeView"); homeLoader.active = true }
    }
}
