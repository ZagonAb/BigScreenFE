// BigScreenFE Theme
// Copyright (C) 2026 Gonzalo
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/

import QtQuick 2.15
import "Utils.js" as Utils

FocusScope {
    id: root

    property var currentGames: api.allGames
    property bool currentIsCollections: false
    property string currentShortName: ""
    property bool isSearching: false
    property bool lightTheme: false

    signal focusUpRequested()
    signal cancelRequested()

    readonly property color _textActive: lightTheme ? "#040608" : "#ffffff"
    readonly property color _textInactive: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _badgeActive: lightTheme ? "#040608" : "#7e848c"
    readonly property color _badgeInactive: lightTheme ? "#5a6472" : "#7e848c"
    readonly property color _bgActive: lightTheme ? "#ffffff" : "#292b2d"
    readonly property color _bgInactive: "transparent"
    readonly property color _bgHover: lightTheme ? "#e2e8f0" : "#292b2d"
    readonly property color _bgFocus: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _textFocus: lightTheme ? "#ffffff" : "#040608"
    readonly property color _badgeFocus: lightTheme ? "#ffffff" : "#040608"

    CollecListModel { id: collecModel }

    function prevTab() {
        if (listView.currentIndex > 0)
            listView.currentIndex--;
    }

    function nextTab() {
        if (listView.currentIndex < listView.model.count - 1)
            listView.currentIndex++;
    }

    function updateCurrent(index) {
        if (collecModel.model.count === 0) return;
        var entry = collecModel.model.get(index);
        if (!entry) return;
        currentIsCollections = entry.isCollections;
        currentShortName = entry.shortName || "";
        if (!entry.isCollections)
            currentGames = entry.games;
    }

    implicitHeight: listView.height

    ListView {
        id: listView

        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(contentWidth, parent.width)
        height: vpx(56)

        interactive: false

        model: collecModel.model
        orientation: ListView.Horizontal
        spacing: 0
        clip: false
        focus: true

        delegate: Item {
            id: tabItem

            property bool active: ListView.isCurrentItem
            property bool hasFocus: listView.activeFocus
            property bool hovered: hoverArea.containsMouse

            readonly property int badgeCount: {
                switch (model.shortName) {
                    case "allgames": return collecModel.allGamesCount;
                    case "favorites": return collecModel.favoritesModel.count;
                    case "collections": return api.collections.count;
                    case "lastplayed": return collecModel.lastPlayedModel.count;
                    default: return 0;
                }
            }

            width: tabRow.implicitWidth + vpx(48)
            height: listView.height

            Rectangle {
                anchors.centerIn: parent
                width: tabRow.implicitWidth + vpx(40)
                height: vpx(40)
                radius: vpx(20)
                color: {
                    if (active && hasFocus) return _bgFocus
                        if (active) return _bgActive
                            if (hovered) return _bgHover
                                return _bgInactive
                }
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Row {
                id: tabRow
                anchors.centerIn: parent
                spacing: vpx(7)

                Text {
                    id: tabLabel
                    anchors.verticalCenter: parent.verticalCenter
                    text: model.name.toUpperCase()
                    color: {
                        if (active && hasFocus) return _textFocus
                            if (active) return _textActive
                                return _textInactive
                    }
                    font.family: global.fonts.sans
                    font.pixelSize: vpx(18)
                    font.bold: active
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Text {
                    id: badgeNum
                    anchors.verticalCenter: parent.verticalCenter
                    text: tabItem.badgeCount
                    font.family: global.fonts.sans
                    font.pixelSize: vpx(18)
                    font.bold: true
                    color: {
                        if (active && hasFocus) return _badgeFocus
                            if (active) return _badgeActive
                                return _badgeInactive
                    }
                    Behavior on color { ColorAnimation { duration: 150 } }
                }
            }

            MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    listView.currentIndex = index;
                    listView.forceActiveFocus();
                }
            }
        }

        Keys.onLeftPressed: if (currentIndex > 0) currentIndex--
        Keys.onRightPressed: if (currentIndex < model.count - 1) currentIndex++

        Keys.onUpPressed: {
            root.focusUpRequested();
            event.accepted = true;
        }

        onCurrentIndexChanged: root.updateCurrent(currentIndex)
    }

    Keys.onPressed: {
        if (!event.isAutoRepeat && api.keys.isCancel(event)) {
            event.accepted = true;
            root.cancelRequested();
        }
    }

    Component.onCompleted: {
        var saved = api.memory.get("selectedTab");
        if (saved !== undefined && saved < collecModel.model.count)
            listView.currentIndex = saved;
        else
            root.updateCurrent(0);
    }

    Component.onDestruction: {
        api.memory.set("selectedTab", listView.currentIndex);
    }
}
