// BigScreenFE Theme
// Copyright (C) 2026 Gonzalo
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/
import QtQuick 2.15
import QtGraphicalEffects 1.15

Rectangle {
    id: bottomBar
    width: parent.width
    height: vpx(48)
    z: 1002

    property bool lightTheme: false
    property string activeView: "grid"
    property var currentGame: null
    property bool searchHasText: false
    property bool isRootGrid: false

    signal favoriteClicked()
    signal selectClicked()
    signal playClicked()
    signal backClicked()
    signal filterClicked()
    signal logoClicked()

    property bool showFilter: false
    property int hubActiveTab: 0
    property bool hubPlayFocus: false
    property bool hubGridFocus: false
    property bool hubRaGridFocus: false
    property bool raGamesTab: false
    property bool credsHasText: false
    property bool hubMediaTab: false
    property bool hubMediaView: false
    property bool keyboardOpen: false

    readonly property color _bgColor: lightTheme ? "#dfe3e8" : "#0b1117"
    readonly property color _textColor: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _mutedText: lightTheme ? "#5a6472" : "#aaaaaa"
    readonly property color _buttonHover: lightTheme ? "#000000" : "#ffffff"
    readonly property color _logoPillBg: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _logoPillText: lightTheme ? "#ffffff" : "#0b1117"
    readonly property color _logoLabel: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _separator: lightTheme ? "#aab0b8" : "#555555"

    color: _bgColor
    Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }

    readonly property bool showFavorite: !keyboardOpen
    && (activeView === "grid"
    || (activeView === "hub" && hubGridFocus && !hubRaGridFocus))
    && activeView !== "ra"
    && activeView !== "home_ra"
    && activeView !== "search"
    && activeView !== "search_ra"
    && activeView !== "search_creds"
    && activeView !== "search_theme"
    && !hubMediaTab
    && !hubMediaView
    readonly property bool showSelect: !keyboardOpen
    && !hubMediaView
    && (activeView === "grid"
    || activeView === "collections"
    || activeView === "home"
    || activeView === "home_ra"
    || activeView === "search_ra"
    || activeView === "search_creds_btn"
    || activeView === "search_theme"
    || (activeView === "hub" && (hubPlayFocus || (hubActiveTab > 0 && !hubRaGridFocus)))
    || (activeView === "ra" && raGamesTab))
    readonly property bool showBack: activeView !== "search_creds"
    || credsHasText
    readonly property bool isFav: currentGame ? (currentGame.favorite === true) : false

    readonly property string bLabel: {
        if (keyboardOpen) return "BACK";
        if (activeView === "search" && searchHasText) return "BACKSPACE";
        if (activeView === "search_ra" && searchHasText) return "BACKSPACE";
        if (activeView === "search_creds" && credsHasText) return "BACKSPACE";
        if (activeView === "search_creds_btn") return "BACK";
        if (activeView === "grid" && isRootGrid) return "EXIT";
        if (activeView === "home_viewmore") return "EXIT";
        if (activeView === "hub") return "BACK";
        if (activeView === "ra") return "BACK";
        return "BACK";
    }

    readonly property string aLabel: {
        if (activeView === "collections") return "OK";
        if (activeView === "hub") return hubPlayFocus ? "PLAY" : "SELECT";
        if (activeView === "search_creds_btn") return "SELECT";
        if (activeView === "search_ra") return "RA SETUP";
        if (activeView === "search_theme") return "TOGGLE THEME";
        return "SELECT";
    }

    Item {
        id: logoWidget
        anchors {
            left: parent.left
            leftMargin: vpx(14)
            verticalCenter: parent.verticalCenter
        }
        width: logoRow.implicitWidth + vpx(10)
        height: vpx(36)

        Rectangle {
            anchors.fill: parent
            color: _buttonHover
            opacity: logoHover.containsMouse ? (lightTheme ? 0.10 : 0.06) : 0.0
            radius: vpx(4)
            Behavior on opacity { NumberAnimation { duration: 130 } }
        }

        Row {
            id: logoRow
            anchors.verticalCenter: parent.verticalCenter
            spacing: vpx(10)

            Rectangle {
                id: logoPill
                anchors.verticalCenter: parent.verticalCenter
                height: vpx(28)
                width: pegasusLabel.implicitWidth + vpx(18)
                radius: height / 2
                color: _logoPillBg
                Behavior on color { ColorAnimation { duration: 150 } }

                Text {
                    id: pegasusLabel
                    anchors.centerIn: parent
                    text: "PEGASUS-FE"
                    color: _logoPillText
                    font.family: global.fonts.sans
                    font.pixelSize: vpx(11)
                    font.bold: true
                    font.letterSpacing: vpx(0.8)
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            Text {
                id: menuLabel
                anchors.verticalCenter: parent.verticalCenter
                text: "BigScreenFE"
                color: _logoLabel
                font.family: global.fonts.sans
                font.pixelSize: vpx(13)
                font.bold: true
                font.letterSpacing: vpx(0.8)
                Behavior on color { ColorAnimation { duration: 150 } }
            }
        }

        MouseArea {
            id: logoHover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: bottomBar.logoClicked()
        }
    }

    Row {
        id: btnRow
        anchors {
            right: parent.right
            rightMargin: vpx(20)
            verticalCenter: parent.verticalCenter
        }
        spacing: vpx(8)

        Item {
            id: btnFav
            visible: bottomBar.showFavorite
            height: vpx(36)
            width: favInner.implicitWidth + vpx(20)

            Rectangle {
                anchors.fill: parent
                color: _buttonHover
                opacity: favHover.containsMouse ? (lightTheme ? 0.10 : 0.07) : 0.0
                radius: vpx(4)
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            Row {
                id: favInner
                anchors.centerIn: parent
                spacing: vpx(7)

                Image {
                    width: vpx(35); height: vpx(35)
                    anchors.verticalCenter: parent.verticalCenter
                    source: "assets/icons/x.png"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true; smooth: true
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: bottomBar.isFav ? "REMOVE FAVORITE" : "ADD FAVORITE"
                    color: _textColor
                    font.family: global.fonts.sans
                    font.pixelSize: vpx(13)
                    font.bold: true
                    font.letterSpacing: vpx(0.6)
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
            MouseArea {
                id: favHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: bottomBar.favoriteClicked()
            }
        }

        Item {
            id: btnSelect
            visible: bottomBar.showSelect
            height: vpx(36)
            width: selectInner.implicitWidth + vpx(20)

            Rectangle {
                anchors.fill: parent
                color: _buttonHover
                opacity: selectHover.containsMouse ? (lightTheme ? 0.10 : 0.07) : 0.0
                radius: vpx(4)
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            Row {
                id: selectInner
                anchors.centerIn: parent
                spacing: vpx(7)

                Image {
                    width: vpx(35); height: vpx(35)
                    anchors.verticalCenter: parent.verticalCenter
                    source: "assets/icons/a.png"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true; smooth: true
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: bottomBar.aLabel
                    color: _textColor
                    font.family: global.fonts.sans
                    font.pixelSize: vpx(13)
                    font.bold: true
                    font.letterSpacing: vpx(0.6)
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            MouseArea {
                id: selectHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (bottomBar.activeView === "hub")
                        bottomBar.playClicked();
                    else
                        bottomBar.selectClicked();
                }
            }
        }

        Item {
            id: btnFilter
            visible: bottomBar.showFilter
            height: vpx(36)
            width: filterInner.implicitWidth + vpx(20)

            Rectangle {
                anchors.fill: parent
                color: _buttonHover
                opacity: filterHover.containsMouse ? (lightTheme ? 0.10 : 0.07) : 0.0
                radius: vpx(4)
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            Row {
                id: filterInner
                anchors.centerIn: parent
                spacing: vpx(7)

                Image {
                    width: vpx(35); height: vpx(35)
                    anchors.verticalCenter: parent.verticalCenter
                    source: "assets/icons/y.png"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true; smooth: true
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "SORT BY"
                    color: _textColor
                    font.family: global.fonts.sans
                    font.pixelSize: vpx(13)
                    font.bold: true
                    font.letterSpacing: vpx(0.6)
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }
            MouseArea {
                id: filterHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: bottomBar.filterClicked()
            }
        }

        Item {
            id: btnBack
            visible: bottomBar.showBack
            height: vpx(36)
            width: backInner.implicitWidth + vpx(20)

            Rectangle {
                anchors.fill: parent
                color: _buttonHover
                opacity: backHover.containsMouse ? (lightTheme ? 0.10 : 0.07) : 0.0
                radius: vpx(4)
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            Row {
                id: backInner
                anchors.centerIn: parent
                spacing: vpx(7)

                Image {
                    width: vpx(35); height: vpx(35)
                    anchors.verticalCenter: parent.verticalCenter
                    source: "assets/icons/b.png"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true; smooth: true
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: bottomBar.bLabel
                    color: _textColor
                    font.family: global.fonts.sans
                    font.pixelSize: vpx(13)
                    font.bold: true
                    font.letterSpacing: vpx(0.6)
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            MouseArea {
                id: backHover
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: bottomBar.backClicked()
            }
        }
    }
}
