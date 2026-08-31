// BigScreenFE Theme
// Copyright (C) 2026 Gonzalo Abbate
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/

import QtQuick 2.15
import QtGraphicalEffects 1.15
import SortFilterProxyModel 0.2

import QtQuick 2.15
import QtGraphicalEffects 1.15
import SortFilterProxyModel 0.2

FocusScope {
    id: root
    focus: true

    function vpx(value) { return value * (width / 1280); }

    property string currentScreen: "home"
    property bool _homeReady: false

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

    property real _homeScale: 1.0
    property real _homeOpacity: 1.0
    property real _hubScale: 1.0
    property real _hubOpacity: 0.0
    property bool _suppressTransition: false

    Behavior on _homeScale { enabled: !root._suppressTransition; NumberAnimation { duration: 360; easing.type: Easing.InOutCubic } }
    Behavior on _homeOpacity { enabled: !root._suppressTransition; NumberAnimation { duration: 260; easing.type: Easing.InOutCubic } }
    Behavior on _hubScale { enabled: !root._suppressTransition; NumberAnimation { duration: 400; easing.type: Easing.OutCubic } }
    Behavior on _hubOpacity { enabled: !root._suppressTransition; NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

    function _startHubEnterAnim() {
        _suppressTransition = true;
        _hubScale = 0.92; _hubOpacity = 0.0;
        _suppressTransition = false;
        _hubEnterTimer.restart();
    }
    function _startHubExitAnim() {
        _suppressTransition = true;
        _homeScale = 0.95; _homeOpacity = 0.0;
        _suppressTransition = false;
        _homeEnterTimer.restart();
    }

    Timer { id: _hubEnterTimer; interval: 16; repeat: false
        onTriggered: { _homeScale = 1.08; _homeOpacity = 0.0; _hubScale = 1.0; _hubOpacity = 1.0 }
    }
    Timer { id: _homeEnterTimer; interval: 16; repeat: false
        onTriggered: { _hubScale = 1.07; _hubOpacity = 0.0; _homeScale = 1.0; _homeOpacity = 1.0 }
    }
    Timer { id: _hubExitCleanupTimer; interval: 430; repeat: false
        onTriggered: { hubLoader.active = false; hubLoader.game = null }
    }

    function goHome() {
        if (currentScreen === "library") {
            _searchFromHub = false;
            _suppressTransition = true;
            _homeScale = 0.95; _homeOpacity = 0.0;
            _suppressTransition = false;
            currentScreen = "home";
            _libraryToHomeTimer.restart();
            _focusHomeTimer.start();
            return;
        }
        _closeHub();
        _searchFromHub = false;
        currentScreen = "home";
        if (homeLoader.item) homeLoader.item.forceActiveFocus();
    }

    Timer { id: _libraryToHomeTimer; interval: 16; repeat: false
        onTriggered: { _homeScale = 1.0; _homeOpacity = 1.0 }
    }

    function goLibrary() {
        _closeHub();
        _searchFromHub = false;
        _searchOrigin = "home";
        currentScreen = "library";
        _focusGridTimer.start();
    }

    function goLibraryKeepFocus() {
        if (currentScreen === "hub") { _searchOrigin = "hub"; _searchFromHub = true; }
        else if (currentScreen === "home") { _searchOrigin = "home"; }
        else { _searchOrigin = "library"; }
        currentScreen = "library";
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
            currentScreen = "home"; _focusHomeTimer.start();
        } else if (_searchOrigin === "home") {
            currentScreen = "home";
            if (homeLoader.item) homeLoader.item.forceActiveFocus();
        } else {
            currentScreen = "home"; _focusHomeTimer.start();
        }
    }

    function _returnToSearchOrigin() { _clearSearch(); _goToSearchOrigin() }

    function openHub(game) {
        hubLoader._prevScreen = currentScreen;
        hubLoader.game = game;
        hubLoader.active = true;
        currentScreen = "hub";
        _startHubEnterAnim();
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
        if (_searchOrigin === "hub")
            _searchOrigin = (prev === "home") ? "home" : "library";
        if (prev === "home") {
            _startHubExitAnim();
            _hubExitCleanupTimer.restart();
        } else {
            _suppressTransition = true;
            _hubScale = 1.0; _hubOpacity = 0.0;
            _homeScale = 1.0; _homeOpacity = 1.0;
            _suppressTransition = false;
            hubLoader.active = false;
            hubLoader.game = null;
        }
    }

    Timer { id: _focusGridTimer; interval: 0; repeat: false
        onTriggered: {
            if (collecBar.currentIsCollections && !_inCollectionGames)
                collectionsGrid.forceActiveFocus()
                else
                    gamesGrid.forceActiveFocus()
        }
    }
    Timer { id: _focusHomeTimer; interval: 0; repeat: false; onTriggered: { if (homeLoader.item) homeLoader.item.forceActiveFocus() } }
    Timer { id: _restoreSearchFocusTimer; interval: 0; repeat: false; onTriggered: searchBar.activate() }
    Timer { id: _focusHubTimer; interval: 0; repeat: false; onTriggered: { if (hubLoader.item) hubLoader.item.forceActiveFocus() } }
    Timer { id: _focusCollecTimer; interval: 0; repeat: false; onTriggered: { collecBar.focus = true } }
    Timer { id: _focusRATimer; interval: 0; repeat: false; onTriggered: { if (raLoader.item) raLoader.item.forceActiveFocus() } }

    Timer {
        id: _logoSplashTimer
        interval: 3000; repeat: false
        onTriggered: splashScreen.hide()
    }

    function _restoreFocusAfterHub() {
        if (hubLoader._prevScreen === "library") _focusGridTimer.start()
            else _focusHomeTimer.start()
    }

    property bool _inCollectionGames: false
    property var _activeColGames: null
    property string _activeColName: ""

    Connections {
        target: collecBar
        function onCurrentIsCollectionsChanged() {
            if (!collecBar.currentIsCollections) {
                root._inCollectionGames = false
                root._activeColGames = null
                root._activeColName = ""
            }
        }
    }

    readonly property string _bottomActiveView: {
        if (onRA) return "ra"
            if (onHub) return "hub"
                if (searchBar.credentialsOpen)
                    return searchBar.credentialsButtonFocused ? "search_creds_btn" : "search_creds"
                    if (searchBar.themeFocused) return "search_theme"
                        if (onHome) {
                            if (homeLoader.item && homeLoader.item.onViewMoreFocused) return "home_viewmore"
                                if (homeLoader.item && homeLoader.item.raStripFocused) return "home_ra"
                                    if (searchBar.raFocused) return "search_ra"
                                        if (searchBar.hasFocus) return "search"
                                            return "grid"
                        }
                        if (searchBar.raFocused) return "search_ra"
                            if (searchBar.hasFocus) return "search"
                                if (collecBar.activeFocus) return "collec"
                                    if (onLibrary && collecBar.currentIsCollections && !_inCollectionGames) return "collections"
                                        return "grid"
    }

    readonly property var _bottomGame: {
        if (onHub && hubLoader.item) {
            var hubItem = hubLoader.item
            if (hubItem._activeTab > 0 && hubItem.currentGridGame) return hubItem.currentGridGame
                return hubLoader.game
        }
        if (onHome && homeLoader.item) {
            var rec = homeLoader.item.recCurrentGame
            if (rec) return rec
                return homeLoader.item.currentGame
        }
        if (onLibrary && !collecBar.currentIsCollections || _inCollectionGames)
            return gamesGrid.currentEntry
            return null
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
                var q = searchBar.searchQuery
                if (!q) return true
                    var fields = [
                        (model.title || "").toLowerCase(),
                        (model.developer || "").toLowerCase(),
                        (model.publisher || "").toLowerCase(),
                        (model.genre || "").toLowerCase()
                    ]
                    for (var i = 0; i < fields.length; i++)
                        if (fields[i].indexOf(q) !== -1) return true
                            return false
            }
        }
    }

    property var sharedCollectionCoverCache: ({})

    Item {
        id: contentRoot
        anchors.fill: parent
        z: 0

        Item {
            id: _homeSceneWrapper
            anchors.fill: parent
            z: 1
            visible: root.onHome || root.onLibrary || root._homeOpacity > 0.01
            opacity: root._homeOpacity
            transform: Scale {
                origin.x: _homeSceneWrapper.width / 2
                origin.y: _homeSceneWrapper.height / 2
                xScale: root._homeScale
                yScale: root._homeScale
            }

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
                    visible: (root.onHome || (!root.onLibrary && root._homeOpacity > 0.01)) && status === Loader.Ready

                    sourceComponent: HomeView {
                        lightTheme: root.lightTheme
                        onGoToLibrary: root.goLibrary()
                        onFocusSearchRequested: searchBar.activate()
                        onOpenHub: root.openHub(game)
                        onOpenRA: root.openRA(game, raGameId)
                        onReadyToShow: {
                            splashScreen.hide()
                            root._homeReady = true
                        }
                        Component.onCompleted: {
                            console.log("HomeView instanciado")
                            resetFocus()
                        }
                    }
                    onStatusChanged: {
                        if (status === Loader.Ready)
                            console.log("HomeLoader listo — esperando readyToShow de HomeView")
                    }
                }

                Rectangle {
                    id: collecBarBg
                    anchors { left: parent.left; right: parent.right }
                    y: searchBar.height
                    height: collecBar.height + vpx(3)
                    z: 1000
                    color: root.theme_barBg
                    opacity: root.onLibrary && (
                        (collecBar.currentIsCollections && !root._inCollectionGames
                        ? collectionsGrid.contentY
                        : gamesGrid.contentY) > vpx(10)
                    ) ? 0.97 : 0.0
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
                    anchors { left: parent.left; right: parent.right; leftMargin: vpx(72); rightMargin: vpx(72) }
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
                            searchBar.clearSearchImmediate()
                            _focusCollecTimer.start()
                        } else if (_searchFromHub && !hubLoader.active) {
                            _searchFromHub = false; collecBar.focus = false; root.goHome()
                        } else if (_searchOrigin === "home") {
                            collecBar.focus = false; root.goHome()
                        } else {
                            collecBar.focus = false; root._goToSearchOrigin()
                        }
                    }
                    onFocusUpRequested: { collecBar.focus = false; searchBar.activate() }
                    Keys.onDownPressed: {
                        collecBar.focus = false
                        _focusGridTimer.start()
                    }
                }

                CollectionsGridView {
                    id: collectionsGrid
                    anchors {
                        top: collecBar.bottom; left: parent.left; right: parent.right
                        leftMargin: vpx(50); rightMargin: vpx(50); topMargin: vpx(12)
                    }
                    height: parent.height - (collecBar.y + collecBar.height + vpx(12)) - bottomBar.height

                    visible: root.onLibrary
                    && collecBar.currentIsCollections
                    && !root._inCollectionGames
                    && !searchBar.isSearching
                    focus: visible

                    lightTheme: root.lightTheme
                    collectionCoverCache: root.sharedCollectionCoverCache
                    preloadEnabled: root._homeReady

                    onCollectionSelected: function(col) {
                        if (!col.games || col.games.count === 0) return
                            api.memory.set("gridIndex_collections", collectionsGrid.currentIndex)
                            root._activeColName = col.name
                            root._activeColGames = col.games
                            root._inCollectionGames = true
                            var saved = api.memory.get("gridIndex_" + col.name)
                            gamesGrid.restoreTabIndex(saved !== undefined ? saved : 0)
                            gamesGrid.forceActiveFocus()
                    }
                    onExitRequested: { focus = false; collecBar.focus = true }
                    onPrevTabRequested: { collecBar.prevTab(); _focusGridTimer.start() }
                    onNextTabRequested: { collecBar.nextTab(); _focusGridTimer.start() }

                    Keys.onUpPressed: { focus = false; collecBar.focus = true }

                    MouseArea {
                        anchors.fill: parent; propagateComposedEvents: true
                        onClicked: { parent.forceActiveFocus(); mouse.accepted = false }
                        onPressed: mouse.accepted = false
                    }
                }

                GamesGridView {
                    id: gamesGrid
                    anchors {
                        top: collecBar.bottom; left: parent.left; right: parent.right
                        leftMargin: vpx(50); rightMargin: vpx(50); topMargin: vpx(12)
                    }
                    height: parent.height - (collecBar.y + collecBar.height + vpx(12)) - bottomBar.height

                    visible: root.onLibrary && (
                        searchBar.isSearching
                        || !collecBar.currentIsCollections
                        || root._inCollectionGames
                    )
                    focus: visible

                    lightTheme: root.lightTheme
                    gamesModel: {
                        if (searchBar.isSearching) return searchResultModel
                            if (root._inCollectionGames) return root._activeColGames
                                return collecBar.currentGames
                    }
                    isCollections: false
                    inCollectionGames: root._inCollectionGames
                    activeCollectionName: root._activeColName
                    currentSortId: sortMenu.activeSortId
                    preserveSourceOrder: collecBar.currentShortName === "lastplayed"

                    onPrevTabRequested: { collecBar.prevTab(); _focusGridTimer.start() }
                    onNextTabRequested: { collecBar.nextTab(); _focusGridTimer.start() }
                    onExitRequested: {
                        if (root._inCollectionGames) {
                            api.memory.set("gridIndex_" + root._activeColName, gamesGrid.currentIndex)
                            root._inCollectionGames = false
                            root._activeColGames = null
                            root._activeColName = ""
                            collectionsGrid.restoreIndex()
                            collectionsGrid.forceActiveFocus()
                        } else {
                            focus = false
                            collecBar.focus = true
                        }
                    }
                    onSortMenuRequested: if (collecBar.currentShortName !== "lastplayed") sortMenu.open()
                    onOpenHub: root.openHub(game)

                    Keys.onUpPressed: { focus = false; collecBar.focus = true }

                    MouseArea {
                        anchors.fill: parent; propagateComposedEvents: true
                        onClicked: { parent.forceActiveFocus(); mouse.accepted = false }
                        onPressed: mouse.accepted = false
                    }
                }
            }
        }

        SearchBar {
            id: searchBar
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: vpx(48)
            gameGridContentY: root.onLibrary
            ? (collecBar.currentIsCollections && !root._inCollectionGames
            ? collectionsGrid.contentY
            : gamesGrid.contentY)
            : vpx(11)
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
            onBackToGridRequested: root._returnToSearchOrigin()
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
                    var g = root._bottomGame
                    if (g) g.favorite = !g.favorite
                } else if (root.onHome && homeLoader.item) {
                    var g = homeLoader.item.recCurrentGame || homeLoader.item.currentGame
                    if (g) g.favorite = !g.favorite
                } else if (root.onLibrary && !collecBar.currentIsCollections || root._inCollectionGames) {
                    gamesGrid.toggleFavorite()
                }
            }

            onSelectClicked: {
                if (root._bottomActiveView === "search_theme") { root.toggleTheme(); return }
                var game = root._bottomGame
                if (!game) return
                    root.openHub(game)
            }
            onPlayClicked: {
                if (root.onHub && hubLoader.game) hubLoader.game.launch()
            }

            onBackClicked: {
                if (searchBar.keyboardOpen) { searchBar.closeKeyboard(); return }
                if (root.onHub) {
                    if (hubLoader.item) hubLoader.item.smartBack()
                } else if (root.onHome) {
                    Qt.quit()
                } else {
                    if (root._bottomActiveView === "search") {
                        if (searchBar.isSearching) searchBar.backspaceOne()
                            else root._returnToSearchOrigin()
                    } else if (root._bottomActiveView === "collec") {
                        collecBar.focus = false; _focusGridTimer.start()
                    } else if (root._bottomActiveView === "collections") {
                        collectionsGrid.focus = false; collecBar.focus = true
                    } else {
                        root.goHome()
                    }
                }
            }
        }

        Item {
            id: _hubWrapper
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: parent.height - bottomBar.height
            z: 500
            visible: root.onHub || root._hubOpacity > 0.01
            opacity: root._hubOpacity
            transform: Scale {
                origin.x: _hubWrapper.width / 2
                origin.y: _hubWrapper.height / 2
                xScale: root._hubScale
                yScale: root._hubScale
            }

            Loader {
                id: hubLoader
                anchors.fill: parent
                active: false
                visible: status === Loader.Ready

                property var game: null
                property string _prevScreen: "home"

                sourceComponent: GameHubView {
                    game: hubLoader.game
                    searchBarHeight: searchBar.height
                    lightTheme: root.lightTheme
                    onCloseRequested: {
                        console.log("[closeHub] prev=", hubLoader._prevScreen)
                        root._closeHub()
                        root._restoreFocusAfterHub()
                    }
                    onPlayRequested: { if (hubLoader.game) hubLoader.game.launch() }
                    onFocusSearchRequested: searchBar.activate()
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
        onMenuClosed: { _focusGridTimer.start() }
    }

    SplashScreen {
        id: splashScreen
        anchors.fill: parent
        z: 3000
        lightTheme: root.lightTheme
    }

    Component.onCompleted: {
        var cache = root.sharedCollectionCoverCache
        var total = api.collections.count || 0
        for (var c = 0; c < total; c++) {
            var col = api.collections.get(c)
            if (!col || !col.games) continue
                var key = col.shortName || col.name || ""
                if (cache[key] !== undefined) continue
                    var gm = col.games
                    var colUrls = []
                    var scanLimit = Math.min(gm.count || 0, 24)
                    for (var g = 0; g < scanLimit && colUrls.length < 4; g++) {
                        var game = gm.get(g)
                        if (game && game.assets && game.assets.boxFront)
                            colUrls.push(game.assets.boxFront)
                    }
                    cache[key] = colUrls
        }
        console.log("sharedCollectionCoverCache: " + total + " colecciones indexadas")
        loadTimer.start()
    }

    Timer {
        id: loadTimer
        interval: 100
        onTriggered: { console.log("Iniciando carga de HomeView"); homeLoader.active = true }
    }
}
