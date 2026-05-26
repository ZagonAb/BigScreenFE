// BigScreenFE Theme
// Copyright (C) 2026 Gonzalo
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/

import QtQuick 2.15

FocusScope {
    id: root

    anchors.fill: parent
    visible: false

    property string activeSortId: "alpha_asc"
    property bool lightTheme: false

    signal sortSelected(string sortId)
    signal menuClosed()

    readonly property color _overlayBg: lightTheme ? Qt.rgba(0,0,0,0.30) : "#000000"
    readonly property color _panelBg: lightTheme ? "#f8f9fa" : "#23262e"
    readonly property color _separator: lightTheme ? "#cbd5e1" : "#05070a"
    readonly property color _itemBgCurrent: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _itemBgHover: lightTheme ? "#e2e8f0" : "#3d4450"
    readonly property color _itemBgNormal: "transparent"
    readonly property color _textCurrent: lightTheme ? "#ffffff" : "#23262e"
    readonly property color _textNormal: lightTheme ? "#0d1117" : "#c6d4df"

    function open() {
        for (var i = 0; i < sortItems.count; i++) {
            if (sortItems.get(i).sortId === root.activeSortId) {
                menuList.currentIndex = i;
                break;
            }
        }
        root.visible = true;
        root.forceActiveFocus();
        openAnim.restart();
    }

    function close() {
        closeAnim.restart();
    }

    ListModel {
        id: sortItems
        ListElement { label: "Alphabetical  A → Z";  sortId: "alpha_asc"     }
        ListElement { label: "Alphabetical  Z → A";  sortId: "alpha_desc"    }
        ListElement { label: "Highest Rated First";  sortId: "rating_desc"   }
        ListElement { label: "Lowest Rated First";   sortId: "rating_asc"    }
        ListElement { label: "Most Played First";    sortId: "playtime_desc" }
        ListElement { label: "Least Played First";   sortId: "playtime_asc"  }
        ListElement { label: "Newest Release First"; sortId: "release_desc"  }
        ListElement { label: "Oldest Release First"; sortId: "release_asc"   }
        ListElement { label: "Most Players First";   sortId: "players_desc"  }
        ListElement { label: "Cancel";               sortId: "__cancel__"    }
    }

    Rectangle {
        anchors.fill: parent
        color: _overlayBg
        opacity: 0.55
        Behavior on color { ColorAnimation { duration: 200 } }

        MouseArea {
            anchors.fill: parent
            onClicked: root.close()
        }
    }

    Rectangle {
        id: panel

        anchors.centerIn: parent
        width: vpx(320)
        height: menuList.contentHeight
        color: _panelBg
        opacity: 0
        Behavior on color { ColorAnimation { duration: 200 } }

        ListView {
            id: menuList

            anchors.fill: parent
            model: sortItems
            clip: true
            focus: true
            interactive: false

            delegate: Item {
                id: row
                width: menuList.width
                height: vpx(56)

                readonly property bool isCurrent: ListView.isCurrentItem
                readonly property bool isHovered: rowArea.containsMouse
                readonly property bool isCancel: model.sortId === "__cancel__"

                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top }
                    height: vpx(2)
                    color: _separator
                    visible: row.isCancel
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Rectangle {
                    anchors.fill: parent
                    color: {
                        if (row.isCurrent) return _itemBgCurrent
                            if (row.isHovered) return _itemBgHover
                                return _itemBgNormal
                    }
                    Behavior on color { ColorAnimation { duration: 80 } }
                }

                Text {
                    anchors {
                        left: parent.left
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                        leftMargin: vpx(24)
                        rightMargin: vpx(24)
                    }

                    text: model.label
                    color: row.isCurrent ? _textCurrent : _textNormal
                    font.pixelSize: vpx(14)
                    font.family: global.fonts.sans
                    Behavior on color { ColorAnimation { duration: 80 } }
                }

                MouseArea {
                    id: rowArea
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    preventStealing: true

                    onClicked: {
                        menuList.currentIndex = index
                        root._activate(index)
                    }
                }
            }

            Keys.onPressed: {
                if (api.keys.isAccept(event)) {
                    event.accepted = true
                    root._activate(menuList.currentIndex)
                    return
                }

                if (api.keys.isCancel(event) || api.keys.isFilters(event)) {
                    event.accepted = true
                    root.close()
                    return
                }
            }

            Keys.onUpPressed: {
                menuList.currentIndex = (menuList.currentIndex - 1 + menuList.count) % menuList.count
                event.accepted = true
            }

            Keys.onDownPressed: {
                menuList.currentIndex = (menuList.currentIndex + 1) % menuList.count
                event.accepted = true
            }
        }
    }

    NumberAnimation {
        id: openAnim
        target: panel
        property: "opacity"
        from: 0
        to: 1
        duration: 160
        easing.type: Easing.OutQuad
    }

    SequentialAnimation {
        id: closeAnim

        NumberAnimation {
            target: panel
            property: "opacity"
            from: 1
            to: 0
            duration: 120
            easing.type: Easing.InQuad
        }

        ScriptAction {
            script: {
                root.visible = false
                root.menuClosed()
            }
        }
    }

    function _activate(index) {
        var item = sortItems.get(index)
        if (!item)
            return

            if (item.sortId === "__cancel__") {
                root.close()
                return
            }

            root.activeSortId = item.sortId
            root.sortSelected(item.sortId)
            root.close()
    }
}
