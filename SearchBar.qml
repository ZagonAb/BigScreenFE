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

Item {
    id: root

    property real gameGridContentY: 0
    readonly property string searchQuery: committedQuery
    readonly property bool isSearching: committedQuery.length > 0

    signal focusDownRequested()
    signal backToGridRequested()

    property bool keyboardOpen: false
    property bool _vkbTyping: false

    property bool _raVkbMode: false
    property string _raActiveField: "user"
    property bool _raVkbSuppressReopen: false

    property bool semiTransparent: false
    property bool solidInHub: false
    property bool hidden: false

    property bool lightTheme: false
    signal themeToggleRequested()

    opacity: hidden ? 0.0 : 1.0
    visible: opacity > 0.0
    Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.InOutQuad } }

    property string committedQuery: ""
    readonly property bool isActive: inputField.activeFocus || inputField.text.length > 0
    readonly property bool hasFocus: inputField.activeFocus
    readonly property bool hasText: inputField.text.length > 0
    readonly property bool credentialsOpen: credentialsPopup.isOpen
    readonly property bool credentialsHasText: credentialsPopup.isOpen && credentialsPopup.credentialsHasText
    readonly property bool credentialsButtonFocused: credentialsPopup.isOpen && credentialsPopup.buttonFocused
    readonly property bool raFocused: raBtn.activeFocus
    readonly property color _bgDark: "#05070a"
    readonly property color _bgLight: "#ffffff"
    readonly property color _iconIdle: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _iconActive: lightTheme ? "#ffffff" : "#c6d4df"
    readonly property color _textColor: lightTheme ? "#0d1117" : "#c6d4df"
    readonly property color _placeholder: lightTheme ? "#5a6472" : "#8b929a"
    readonly property color _clockColor: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _currentIconColor: isActive ? (lightTheme ? "#ffffff" : "#000000") : _iconIdle
    readonly property color _currentTextColor: isActive ? (lightTheme ? "#ffffff" : "#000000") : _textColor
    readonly property color _currentPlaceholder: isActive ? (lightTheme ? "#aaaaaa" : "#000000") : _placeholder
    readonly property color _searchBgActive: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _barBgIdle: lightTheme ? "#dfe3e8" : "#05070a"
    property bool batteryCharging: api.device.batteryCharging
    property real batteryPercent: api.device.batteryPercent
    property int batteryLevel: isNaN(batteryPercent) ? -1 : Math.round(batteryPercent * 100)
    property bool hasBattery: !isNaN(api.device.batteryPercent)
    property string _raUser: api.memory.has("ra_api_user") ? api.memory.get("ra_api_user") : ""
    property bool themeFocused: themeToggleBtn.activeFocus

    Timer {
        id: batteryTimer
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            root.batteryCharging = api.device.batteryCharging
            root.batteryPercent = api.device.batteryPercent
            root.batteryLevel = isNaN(root.batteryPercent) ? -1 : Math.round(root.batteryPercent * 100)
            root.hasBattery = !isNaN(api.device.batteryPercent)
        }
    }

    Timer {
        id: debounceTimer
        interval: 300
        repeat: false
        onTriggered: root.committedQuery = Utils.normalizeForSearch(inputField.text)
    }

    Timer {
        id: vkbDebounceTimer
        interval: 500
        repeat: false
        onTriggered: root.committedQuery = Utils.normalizeForSearch(inputField.text)
    }

    Timer {
        id: _raVkbSuppressTimer
        interval: 300
        repeat: false
        onTriggered: root._raVkbSuppressReopen = false
    }

    Item {
        id: searchZone
        anchors { top: parent.top; bottom: parent.bottom; left: parent.left }
        width: parent.width * 0.72

        MouseArea {
            id: searchZoneHover
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }

        Rectangle {
            id: searchBarBg
            anchors.fill: parent
            z: -1

            color: root.isActive
            ? root._searchBgActive
            : (searchZoneHover.containsMouse ? (root.lightTheme ? "#c0c5cb" : "#505153") : root._barBgIdle)

            opacity: root.isActive
            ? 1.0
            : (searchZoneHover.containsMouse
            ? 1.0
            : (root.solidInHub ? 1.0
            : (root.semiTransparent ? 0.75
            : (root.gameGridContentY > vpx(10) ? 0.97 : 0.0))))

            Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.InOutQuad } }
            Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
        }

        Item {
            id: searchIconWrapper
            anchors {
                left: parent.left
                leftMargin: vpx(28)
                verticalCenter: parent.verticalCenter
            }
            width: vpx(20)
            height: vpx(20)
            visible: searchIconImg.status === Image.Ready

            Image {
                id: searchIconImg
                anchors.fill: parent
                source: "assets/icons/search.svg"
                fillMode: Image.PreserveAspectFit
                mipmap: true
                visible: false
            }

            ColorOverlay {
                anchors.fill: searchIconImg
                source: searchIconImg
                color: root._currentIconColor
                Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.InOutQuad } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onDoubleClicked: root._activateSearch()
            }
        }

        Text {
            id: iconFallback
            anchors {
                left: parent.left
                leftMargin: vpx(28)
                verticalCenter: parent.verticalCenter
            }
            visible: searchIconImg.status !== Image.Ready
            text: "\u2315"
            font.pixelSize: vpx(20)
            font.family: global.fonts.sans
            color: root._currentIconColor
            Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.InOutQuad } }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onDoubleClicked: root._activateSearch()
            }
        }

        TextInput {
            id: inputField

            readonly property real _iconRight: searchIconWrapper.visible
            ? searchIconWrapper.x + searchIconWrapper.width
            : iconFallback.x + iconFallback.width

            anchors {
                left: parent.left
                leftMargin: _iconRight + vpx(10)
                right: clearBtn.visible ? clearBtn.left : parent.right
                rightMargin: vpx(12)
                verticalCenter: parent.verticalCenter
            }

            color: root._currentTextColor
            Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.InOutQuad } }

            font.pixelSize: vpx(17)
            font.family: global.fonts.sans
            clip: true
            maximumLength: 80
            selectionColor: "#2a6496"
            selectedTextColor: "#ffffff"
            activeFocusOnPress: false
            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhSensitiveData

            Text {
                anchors.fill: parent
                text: "Search for games..."
                color: root._currentPlaceholder
                font: inputField.font
                visible: inputField.text.length === 0
                elide: Text.ElideRight
                Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.InOutQuad } }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.IBeamCursor
                onClicked: inputField.forceActiveFocus()
                onDoubleClicked: root._activateSearch()
            }

            onTextChanged: {
                if (!root._vkbTyping) {
                    vkbDebounceTimer.stop()
                    debounceTimer.restart()
                }
            }

            Keys.onEscapePressed: {
                inputField.text = "";
                root.keyboardOpen = false;
                vkb.hide();
                root.focusDownRequested();
                event.accepted = true;
            }

            Keys.onDownPressed: {
                root.focusDownRequested();
                event.accepted = true;
            }

            Keys.onUpPressed: { event.accepted = true; }

            Keys.onPressed: {
                if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                    event.accepted = true
                    root.keyboardOpen = true
                    vkb.show()
                    return
                }

                if (event.key === Qt.Key_Right) {
                    if (inputField.text.length === 0 ||
                        inputField.cursorPosition === inputField.text.length) {
                        event.accepted = true
                        raBtn.forceActiveFocus()
                        }
                        return
                }

                if (api.keys.isCancel(event)) {
                    event.accepted = true;
                    if (inputField.text.length > 0) {
                        inputField.text = inputField.text.slice(0, -1);
                    } else {
                        root.backToGridRequested();
                    }
                }
            }
        }

        Item {
            id: clearBtn
            anchors {
                right: parent.right
                rightMargin: vpx(14)
                verticalCenter: parent.verticalCenter
            }
            width: vpx(18)
            height: vpx(18)
            visible: inputField.text.length > 0
            opacity: clearMouse.containsMouse ? 1.0 : 0.55
            Behavior on opacity { NumberAnimation { duration: 120 } }

            Image {
                id: closeIconImg
                anchors.fill: parent
                source: "assets/icons/close.svg"
                fillMode: Image.PreserveAspectFit
                mipmap: true
                visible: false
            }

            ColorOverlay {
                anchors.fill: closeIconImg
                source: closeIconImg
                color: root._currentIconColor
                Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                visible: closeIconImg.status === Image.Ready
            }

            Text {
                anchors.centerIn: parent
                visible: closeIconImg.status !== Image.Ready
                text: "\u2715"
                font.pixelSize: vpx(13)
                font.family: global.fonts.sans
                color: root._currentIconColor
                Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.InOutQuad } }
            }

            MouseArea {
                id: clearMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    inputField.text = "";
                    inputField.forceActiveFocus();
                }
            }
        }
    }

    Rectangle {
        id: clockZone
        color: root.isActive ? root._barBgIdle : "transparent"

        anchors {
            top: parent.top
            bottom: parent.bottom
            left: searchZone.right
            right: parent.right
        }

        Rectangle {
            id: clockBg
            anchors.fill: parent
            z: -1
            color: root._barBgIdle
            opacity: root.solidInHub ? 1.0
            : root.semiTransparent ? 0.75
            : (root.gameGridContentY > vpx(10) ? 0.97 : 0.0)
            Behavior on color { ColorAnimation { duration: 400; easing.type: Easing.InOutQuad } }
            Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
        }

        Timer {
            id: clockTimer
            interval: 1000
            repeat: true
            running: true
            triggeredOnStart: true
            onTriggered: {
                var now = new Date();
                var h = now.getHours();
                var m = ("0" + now.getMinutes()).slice(-2);
                var ampm = h >= 12 ? "p.\u202fm." : "a.\u202fm.";
                h = h % 12;
                if (h === 0) h = 12;
                clockLabel.text = h + ":" + m + " " + ampm;
            }
        }

        Row {
            id: clockRow
            anchors {
                right: parent.right
                rightMargin: vpx(10)
                verticalCenter: parent.verticalCenter
            }
            spacing: vpx(12)
            layoutDirection: Qt.RightToLeft

            Item {
                id: raUserAvatar
                width: vpx(26)
                height: vpx(26)
                anchors.verticalCenter: parent.verticalCenter
                visible: root._raUser !== ""

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: root.lightTheme ? "#c0c8d8" : "#2a3447"
                    Behavior on color { ColorAnimation { duration: 400 } }
                }

                Text {
                    anchors.centerIn: parent
                    visible: _raAvatarImg.status !== Image.Ready
                    text: root._raUser.length > 0 ? root._raUser.charAt(0).toUpperCase() : ""
                    font.pixelSize: vpx(12)
                    font.bold: true
                    font.family: global.fonts.sans
                    color: "#ffffff"
                }

                Rectangle {
                    id: _raAvatarMask
                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                }

                Image {
                    id: _raAvatarImg
                    anchors.fill: parent
                    source: root._raUser !== ""
                    ? "https://media.retroachievements.org/UserPic/" + root._raUser + ".png"
                    : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    mipmap: true
                    smooth: true
                    visible: status === Image.Ready
                    layer.enabled: status === Image.Ready
                    layer.effect: OpacityMask {
                        maskSource: _raAvatarMask
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    border.width: vpx(1.5)
                    border.color: Qt.rgba(1, 1, 1, 0.30)
                }
            }

            Rectangle {
                width: vpx(1)
                height: vpx(18)
                color: root.lightTheme ? "#aab0b8" : "#555555"
                opacity: 0.7
                anchors.verticalCenter: parent.verticalCenter
                visible: root._raUser !== ""
            }

            Text {
                id: clockLabel
                anchors.verticalCenter: parent.verticalCenter
                color: root._clockColor
                font.pixelSize: vpx(17)
                font.family: global.fonts.sans
                font.bold: true
                text: "--:--"
                opacity: root.semiTransparent ? 1.0 : 1.0
                Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
            }

            Row {
                id: batteryIndicator
                spacing: vpx(2)
                anchors.verticalCenter: parent.verticalCenter
                visible: true

                Item {
                    id: batteryIconContainer
                    width: vpx(26)
                    height: vpx(17)
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        id: batteryIcon
                        anchors.fill: parent
                        source: {
                            if (!root.hasBattery) return "assets/icons/no_battery.svg"
                                if (root.batteryCharging) return "assets/icons/battery_charging.svg"
                                    if (root.batteryLevel <= 9) return "assets/icons/battery_0.svg"
                                        if (root.batteryLevel <= 34) return "assets/icons/battery_1.svg"
                                            if (root.batteryLevel <= 59) return "assets/icons/battery_2.svg"
                                                if (root.batteryLevel <= 84) return "assets/icons/battery_3.svg"
                                                    return "assets/icons/battery_4.svg"
                        }
                        fillMode: Image.PreserveAspectFit
                        mipmap: true
                        visible: false
                    }

                    ColorOverlay {
                        anchors.fill: batteryIcon
                        source: batteryIcon
                        color: {
                            if (!root.hasBattery) return root._clockColor
                                if (root.batteryCharging) return "#4CAF50"
                                    if (root.batteryLevel <= 15) return "#F44336"
                                        if (root.batteryLevel <= 30) return "#FF9800"
                                            return root._clockColor
                        }
                        Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                    }
                }

                Text {
                    id: batteryText
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if (!root.hasBattery) return "AC"
                            if (root.batteryCharging) return "⚡" + root.batteryLevel + "%"
                                return root.batteryLevel + "%"
                    }
                    color: {
                        if (!root.hasBattery) return root.lightTheme ? Qt.rgba(0, 0, 0, 0.85) : Qt.rgba(1, 1, 1, 0.55)
                            if (root.batteryCharging) return "#4CAF50"
                                if (root.batteryLevel <= 15) return "#F44336"
                                    if (root.batteryLevel <= 30) return "#FF9800"
                                        return root._clockColor
                    }
                    Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                    font.pixelSize: vpx(14)
                    font.family: global.fonts.sans
                    font.bold: true
                }
            }

            Rectangle {
                width: vpx(1)
                height: vpx(18)
                color: root.lightTheme ? "#aab0b8" : "#555555"
                opacity: 0.7
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                id: themeToggleBtn
                width: vpx(26)
                height: vpx(26)
                anchors.verticalCenter: parent.verticalCenter
                activeFocusOnTab: true

                Rectangle {
                    anchors {
                        fill: parent
                        margins: vpx(-5)
                    }
                    radius: vpx(5)
                    color: themeToggleBtn.activeFocus ? "#f5a623" : "transparent"
                    opacity: themeToggleBtn.activeFocus ? 0.18 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Rectangle {
                    anchors {
                        fill: parent
                        margins: vpx(-5)
                    }
                    radius: vpx(5)
                    color: themeBtnMouse.containsMouse ? (root.lightTheme ? "#0d1117" : "#ffffff") : "transparent"
                    opacity: themeBtnMouse.containsMouse ? 0.12 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Image {
                    id: _themeIcon
                    anchors.fill: parent
                    source: root.lightTheme ? "assets/icons/dark.svg" : "assets/icons/light.svg"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    visible: false
                }
                ColorOverlay {
                    anchors.fill: _themeIcon
                    source: _themeIcon
                    color: root._clockColor
                    visible: _themeIcon.status === Image.Ready
                    Behavior on color { ColorAnimation { duration: 600; easing.type: Easing.InOutQuad } }
                }
                Text {
                    anchors.centerIn: parent
                    visible: _themeIcon.status !== Image.Ready
                    text: root.lightTheme ? "\u263d" : "\u2600"
                    font.pixelSize: vpx(14)
                    font.family: global.fonts.sans
                    color: root._clockColor
                    Behavior on color { ColorAnimation { duration: 400 } }
                }

                Keys.onLeftPressed: {
                    event.accepted = true;
                    raBtn.forceActiveFocus();
                }
                Keys.onRightPressed: {
                    event.accepted = true;
                }
                Keys.onDownPressed: {
                    event.accepted = true;
                    root.focusDownRequested();
                }
                Keys.onPressed: {
                    if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                        event.accepted = true;
                        root.themeToggleRequested();
                    }
                }

                MouseArea {
                    id: themeBtnMouse
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: root.themeToggleRequested()
                }
            }

            Rectangle {
                width: vpx(1)
                height: vpx(18)
                color: root.lightTheme ? "#aab0b8" : "#555555"
                opacity: 0.7
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 400 } }
            }

            Item {
                id: raBtn
                width: vpx(26)
                height: vpx(26)
                anchors.verticalCenter: parent.verticalCenter
                activeFocusOnTab: true

                Rectangle {
                    anchors {
                        fill: parent
                        margins: vpx(-5)
                    }
                    radius: vpx(5)
                    color: raBtn.activeFocus ? "#f5a623" : "transparent"
                    opacity: raBtn.activeFocus ? 0.18 : 0.0
                    Behavior on opacity { NumberAnimation { duration: 150 } }
                }

                Image {
                    id: _raIcon
                    anchors.fill: parent
                    source: "assets/icons/retroachievements.svg"
                    fillMode: Image.PreserveAspectFit
                    mipmap: true
                    visible: false
                }

                ColorOverlay {
                    anchors.fill: _raIcon
                    source: _raIcon
                    color: raBtn.activeFocus ? "#f5a623" : root._clockColor
                    visible: _raIcon.status === Image.Ready
                    Behavior on color { ColorAnimation { duration: 200; easing.type: Easing.InOutQuad } }
                }

                Text {
                    anchors.centerIn: parent
                    visible: _raIcon.status !== Image.Ready
                    text: "RA"
                    font.pixelSize: vpx(11)
                    font.bold: true
                    font.family: global.fonts.sans
                    color: raBtn.activeFocus ? "#f5a623" : root._clockColor
                    Behavior on color { ColorAnimation { duration: 200 } }
                }

                Keys.onLeftPressed: {
                    event.accepted = true;
                    inputField.forceActiveFocus();
                    inputField.cursorPosition = inputField.text.length;
                }
                Keys.onRightPressed: {
                    event.accepted = true;
                    themeToggleBtn.forceActiveFocus();
                }
                Keys.onDownPressed: {
                    event.accepted = true;
                    root.focusDownRequested();
                }
                Keys.onPressed: {
                    if (api.keys.isCancel(event)) {
                        event.accepted = true;
                        inputField.forceActiveFocus();
                        inputField.cursorPosition = inputField.text.length;
                        return;
                    }
                    if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                        event.accepted = true;
                        credentialsPopup.open();
                        return;
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: {
                        if (credentialsPopup.isOpen)
                            credentialsPopup.close();
                        else
                            credentialsPopup.open();
                    }
                }
            }
        }
    }

    Rectangle {
        anchors { bottom: parent.bottom; left: parent.left }
        width: parent.width * 0.72
        height: vpx(1)
        color: root.isActive ? (root.lightTheme ? Qt.rgba(1,1,1,0.18) : Qt.rgba(0,0,0,0.12)) : "transparent"
        opacity: root.isActive ? 1.0 : (root.gameGridContentY > vpx(10) ? 0.97 : 0.0)
        Behavior on color { ColorAnimation { duration: 300 } }
        Behavior on opacity { NumberAnimation { duration: 450; easing.type: Easing.InOutQuad } }
    }

    RACredentialsPopup {
        id: credentialsPopup

        anchors {
            top: parent.bottom
            horizontalCenter: parent.horizontalCenter
        }

        width: parent.width
        height: vpx(260)

        lightTheme: root.lightTheme

        onUserInputActivated: {
            root._raVkbMode = true
            root._raActiveField = "user"
            if (!root._raVkbSuppressReopen) {
                root.keyboardOpen = true
                vkb.show()
            }
        }

        onKeyInputActivated: {
            root._raVkbMode = true
            root._raActiveField = "key"
            if (!root._raVkbSuppressReopen) {
                root.keyboardOpen = true
                vkb.show()
            }
        }

        onCredentialsSaved: {
            root._raVkbMode = false
            root._raVkbSuppressReopen = false
            _raVkbSuppressTimer.stop()
            root.keyboardOpen = false
            vkb.hide()
            raBtn.forceActiveFocus()
            root._raUser = api.memory.has("ra_api_user") ? api.memory.get("ra_api_user") : ""
        }

        onPopupClosed: {
            root._raVkbMode = false
            root._raVkbSuppressReopen = false
            _raVkbSuppressTimer.stop()
            root.keyboardOpen = false
            vkb.hide()
            raBtn.forceActiveFocus()
        }
    }

    VirtualKeyboard {
        id: vkb
        parent: root.parent ? root.parent : root
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        bottomBarHeight: vpx(48)
        lightTheme: root.lightTheme

        onKeyTapped: function(ch) {
            if (root._raVkbMode) {
                if (root._raActiveField === "user") credentialsPopup.appendToUser(ch)
                    else credentialsPopup.appendToKey(ch)
                        _vkbRefocusTimer.start()
                        return
            }
            root._vkbTyping = true
            inputField.text = inputField.text + ch
            root._vkbTyping = false
            debounceTimer.stop()
            vkbDebounceTimer.restart()
            _vkbRefocusTimer.start()
        }

        onBackspacePressed: {
            if (root._raVkbMode) {
                if (root._raActiveField === "user") credentialsPopup.backspaceUser()
                    else credentialsPopup.backspaceKey()
                        _vkbRefocusTimer.start()
                        return
            }
            root._vkbTyping = true
            if (inputField.text.length > 0)
                inputField.text = inputField.text.slice(0, -1)
                root._vkbTyping = false
                debounceTimer.stop()
                vkbDebounceTimer.restart()
                _vkbRefocusTimer.start()
        }

        onCloseRequested: {
            _vkbRefocusTimer.stop()
            if (root._raVkbMode) {
                root._raVkbSuppressReopen = true
                _raVkbSuppressTimer.restart()
                root.keyboardOpen = false
                hide()
                credentialsPopup.focusFieldSafe(root._raActiveField)
                return
            }
            root.keyboardOpen = false
            hide()
            inputField.forceActiveFocus()
        }
    }

    Timer {
        id: _vkbRefocusTimer
        interval: 16
        repeat: false
        onTriggered: {
            if (root.keyboardOpen)
                vkb.forceActiveFocusOnKeyGrid()
        }
    }

    function _activateSearch() {
        inputField.forceActiveFocus()
        root.keyboardOpen = true
        vkb.show()
    }

    Component.onCompleted: {
        root.batteryCharging = api.device.batteryCharging
        root.batteryPercent = api.device.batteryPercent
        root.batteryLevel = isNaN(root.batteryPercent) ? -1 : Math.round(root.batteryPercent * 100)
        root.hasBattery = !isNaN(api.device.batteryPercent)
        root._raUser = api.memory.has("ra_api_user") ? api.memory.get("ra_api_user") : ""
    }

    function activate() { inputField.forceActiveFocus(); }
    function clearSearch() { inputField.text = ""; }
    function closeKeyboard() {
        _vkbRefocusTimer.stop()
        root.keyboardOpen = false
        vkb.hide()
        inputField.forceActiveFocus()
    }
    function clearSearchImmediate() {
        debounceTimer.stop();
        vkbDebounceTimer.stop();
        inputField.text = "";
        committedQuery = "";
    }

    function backspaceOne() {
        if (inputField.text.length > 0)
            inputField.text = inputField.text.slice(0, -1);
        else
            root.backToGridRequested();
    }
}
