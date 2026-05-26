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

    property bool isOpen: false
    property bool lightTheme: false
    readonly property bool buttonFocused: _okBtn.activeFocus || _cancelBtn.activeFocus
    readonly property bool credentialsHasText: _userInput.text.length > 0 || _keyInput.text.length > 0

    signal credentialsSaved()
    signal popupClosed()
    signal userInputActivated()
    signal keyInputActivated()

    readonly property color _popupBg: lightTheme ? "#f8f9fa" : "#0b1117"
    readonly property color _borderColor: lightTheme ? "#cbd5e1" : "#243444"
    readonly property color _accentColor: "#f5a623"
    readonly property color _titleText: lightTheme ? "#0d1117" : "#c6d4df"
    readonly property color _labelText: lightTheme ? "#5a6472" : "#8b929a"
    readonly property color _inputBg: lightTheme ? "#ffffff" : "#292b2d"
    readonly property color _inputBgActive: lightTheme ? "#e9ecef" : "#0f2232"
    readonly property color _inputBorder: lightTheme ? "#cbd5e1" : "#292b2d"
    readonly property color _inputBorderActive: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _inputText: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _placeholderText: lightTheme ? "#8b929a" : "#3a4a5a"
    readonly property color _cursorColor: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _separator: lightTheme ? "#cbd5e1" : "#1e2e3e"
    readonly property color _msgBgTesting: lightTheme ? "#e2e8f0" : "#1a2535"
    readonly property color _msgBgSuccess: lightTheme ? "#d1fae5" : "#0d2918"
    readonly property color _msgBgError: lightTheme ? "#fee2e2" : "#2a100e"
    readonly property color _msgTextTesting: lightTheme ? "#1a6b7a" : "#57cbde"
    readonly property color _msgTextSuccess: lightTheme ? "#0d9488" : "#2ecc71"
    readonly property color _msgTextError: lightTheme ? "#dc2626" : "#e74c3c"
    readonly property color _okBtnBg: lightTheme ? "#e2e8f0" : "#292b2d"
    readonly property color _okBtnBgFocus: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _okBtnText: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _okBtnTextFocus: lightTheme ? "#ffffff" : "#0b1117"
    readonly property color _cancelBtnBg: lightTheme ? "#e2e8f0" : "#292b2d"
    readonly property color _cancelBtnBgFocus: lightTheme ? "#fecaca" : "#2a0f0f"
    readonly property color _cancelBtnBorder: lightTheme ? "#cbd5e1" : "#292b2d"
    readonly property color _cancelBtnBorderFocus: lightTheme ? "#dc2626" : "#e74c3c"
    readonly property color _cancelBtnText: lightTheme ? "#5a6472" : "#8b929a"
    readonly property color _cancelBtnTextFocus: lightTheme ? "#dc2626" : "#e74c3c"

    property string _testState: "idle"
    property string _testMsg: ""
    property string _activeField: "none"

    function appendToUser(ch) {
        if (_testState !== "testing") _userInput.text += ch
    }
    function backspaceUser() {
        if (_testState !== "testing" && _userInput.text.length > 0)
            _userInput.text = _userInput.text.slice(0, -1)
    }
    function appendToKey(ch) {
        if (_testState !== "testing") _keyInput.text += ch
    }
    function backspaceKey() {
        if (_testState !== "testing" && _keyInput.text.length > 0)
            _keyInput.text = _keyInput.text.slice(0, -1)
    }

    function focusFieldSafe(field) {
        if (field === "key") _keyFieldScope.forceActiveFocus()
            else _userFieldScope.forceActiveFocus()
    }

    function _activateField(field) {
        root._activeField = field
        if (field === "key") {
            _keyFieldScope.forceActiveFocus()
            root.keyInputActivated()
        } else {
            _userFieldScope.forceActiveFocus()
            root.userInputActivated()
        }
    }

    function open() {
        _userInput.text = api.memory.has("ra_api_user") ? api.memory.get("ra_api_user") : ""
        _keyInput.text = api.memory.has("ra_api_key") ? api.memory.get("ra_api_key") : ""
        _testState = "idle"
        _testMsg = ""
        isOpen = true
        _focusTimer.start()
    }

    function close() {
        isOpen = false
        root._activeField = "none"
        root.popupClosed()
    }

    function _save() {
        var u = _userInput.text.trim()
        var k = _keyInput.text.trim()
        if (u === "" || k === "") {
            _testState = "error"
            _testMsg = "Both fields are required."
            return
        }
        api.memory.set("ra_api_user", u)
        api.memory.set("ra_api_key", k)
        _testState = "testing"
        _testMsg = ""
        _testConnection(u, k)
    }

    function _testConnection(user, key) {
        var url = "https://retroachievements.org/API/API_GetUserSummary.php"
        + "?y=" + encodeURIComponent(key)
        + "&u=" + encodeURIComponent(user)
        + "&g=1"
        var xhr = new XMLHttpRequest()
        xhr.open("GET", url, true)
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return
                if (xhr.status === 200) {
                    try {
                        var data = JSON.parse(xhr.responseText)
                        if (data && (data.User || data.Username || data.MemberSince)) {
                            var displayName = data.User || data.Username || user
                            _testState = "success"
                            _testMsg = "Connected as " + displayName
                            _closeTimer.start()
                        } else {
                            _testState = "error"
                            _testMsg = "Invalid credentials. Check your API User and Key."
                        }
                    } catch(e) {
                        _testState = "error"
                        _testMsg = "Could not parse server response."
                    }
                } else if (xhr.status === 0) {
                    _testState = "success"
                    _testMsg = "Saved. (No network — could not verify)"
                    _closeTimer.start()
                } else {
                    _testState = "error"
                    _testMsg = "Server error: HTTP " + xhr.status
                }
        }
        xhr.send()
    }

    Timer {
        id: _closeTimer
        interval: 1400
        onTriggered: {
            isOpen = false
            root.credentialsSaved()
        }
    }

    Timer {
        id: _focusTimer
        interval: 30
        onTriggered: {
            root._activeField = "user"
            root.userInputActivated()
        }
    }

    property real _panelOpacity: isOpen ? 1.0 : 0.0
    Behavior on _panelOpacity { NumberAnimation { duration: 210; easing.type: Easing.InOutQuad } }

    visible: _panelOpacity > 0.001
    opacity: _panelOpacity

    Rectangle {
        id: _panel

        property real _slideOffset: root.isOpen ? 0 : vpx(-8)
        Behavior on _slideOffset { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

        anchors.horizontalCenter: parent.horizontalCenter
        width: vpx(460)
        y: _slideOffset
        height: _col.height + vpx(36)

        color: _popupBg
        radius: vpx(6)
        Behavior on color { ColorAnimation { duration: 200 } }

        Rectangle {
            anchors { fill: parent; margins: vpx(-1) }
            color: "transparent"
            border { color: _borderColor; width: vpx(1) }
            radius: parent.radius + vpx(1)
            z: -1
            Behavior on border.color { ColorAnimation { duration: 200 } }
        }

        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: vpx(3); color: _accentColor; radius: vpx(3)
        }

        Column {
            id: _col
            anchors {
                top: parent.top; topMargin: vpx(20)
                left: parent.left; leftMargin: vpx(22)
                right: parent.right; rightMargin: vpx(22)
            }
            spacing: vpx(12)

            Row {
                spacing: vpx(8)
                anchors.horizontalCenter: parent.horizontalCenter

                Item {
                    width: vpx(32); height: vpx(32)
                    anchors.verticalCenter: parent.verticalCenter
                    Image {
                        id: _titleIcon
                        anchors.fill: parent
                        source: "assets/icons/retroachievements.svg"
                        fillMode: Image.PreserveAspectFit
                        mipmap: true; visible: false
                    }
                    ColorOverlay {
                        anchors.fill: _titleIcon; source: _titleIcon
                        color: _accentColor; visible: _titleIcon.status === Image.Ready
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: _titleIcon.status !== Image.Ready
                        text: "RA"; font.pixelSize: vpx(13); font.bold: true; color: _accentColor
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Enter your RA credentials here."
                    font.pixelSize: vpx(18); font.family: global.fonts.sans
                    font.bold: true; color: _titleText
                    Behavior on color { ColorAnimation { duration: 200 } }
                }
            }

            Rectangle { width: parent.width; height: vpx(1); color: _separator; Behavior on color { ColorAnimation { duration: 200 } } }

            FocusScope {
                id: _userFieldScope
                width: parent.width
                height: _userFieldCol.implicitHeight

                readonly property bool _highlighted: activeFocus || root._activeField === "user"

                Keys.onPressed: {
                    if (root._testState === "testing") { event.accepted = true; return }
                    if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                        event.accepted = true
                        root._activateField("user")
                        return
                    }
                    if (api.keys.isCancel(event)) {
                        event.accepted = true
                        if (_userInput.text.length > 0)
                            _userInput.text = _userInput.text.slice(0, -1)
                            return
                    }
                }
                Keys.onDownPressed: { event.accepted = true; _keyFieldScope.forceActiveFocus() }

                Column {
                    id: _userFieldCol
                    width: parent.width
                    spacing: vpx(5)

                    Text {
                        text: "USER NAME:"
                        font.pixelSize: vpx(11); font.family: global.fonts.sans
                        font.letterSpacing: 0.6; color: _labelText
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Rectangle {
                        id: _userRect
                        width: parent.width; height: vpx(32); radius: vpx(4)
                        color: _userFieldScope._highlighted ? _inputBgActive : _inputBg
                        border.color: _userFieldScope._highlighted ? _inputBorderActive : _inputBorder
                        border.width: vpx(1)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        TextInput {
                            id: _userInput
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: vpx(10); rightMargin: vpx(10)
                            }
                            color: _inputText; font.pixelSize: vpx(13)
                            font.family: global.fonts.sans
                            selectionColor: "#2a6496"; selectedTextColor: "#ffffff"
                            clip: true
                            readOnly: true
                            activeFocusOnPress: false
                            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                            | Qt.ImhSensitiveData | Qt.ImhMultiLine

                            cursorDelegate: Rectangle {
                                id: _userCursor
                                width: vpx(2)
                                height: vpx(16)
                                color: _cursorColor
                                visible: root._activeField === "user" && root._testState !== "testing"
                                SequentialAnimation on opacity {
                                    running: _userCursor.visible
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 1; duration: 0 }
                                    NumberAnimation { to: 1; duration: 480 }
                                    NumberAnimation { to: 0; duration: 0 }
                                    NumberAnimation { to: 0; duration: 480 }
                                }
                                onVisibleChanged: if (!visible) opacity = 1
                            }

                            Text {
                                anchors.fill: parent
                                text: "your username"
                                color: _placeholderText
                                font: _userInput.font
                                visible: _userInput.text.length === 0
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            onClicked: {
                                if (root._testState !== "testing")
                                    root._activateField("user")
                            }
                        }
                    }
                }
            }

            FocusScope {
                id: _keyFieldScope
                width: parent.width
                height: _keyFieldCol.implicitHeight

                readonly property bool _highlighted: activeFocus || root._activeField === "key"

                Keys.onPressed: {
                    if (root._testState === "testing") { event.accepted = true; return }
                    if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                        event.accepted = true
                        root._activateField("key")
                        return
                    }
                    if (api.keys.isCancel(event)) {
                        event.accepted = true
                        if (_keyInput.text.length > 0)
                            _keyInput.text = _keyInput.text.slice(0, -1)
                            return
                    }
                }
                Keys.onUpPressed: { event.accepted = true; _userFieldScope.forceActiveFocus() }
                Keys.onDownPressed: { event.accepted = true; _okBtn.forceActiveFocus() }

                Column {
                    id: _keyFieldCol
                    width: parent.width
                    spacing: vpx(5)

                    Text {
                        text: "API KEY:"
                        font.pixelSize: vpx(11); font.family: global.fonts.sans
                        font.letterSpacing: 0.6; color: _labelText
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Rectangle {
                        id: _keyRect
                        width: parent.width; height: vpx(32); radius: vpx(4)
                        color: _keyFieldScope._highlighted ? _inputBgActive : _inputBg
                        border.color: _keyFieldScope._highlighted ? _inputBorderActive : _inputBorder
                        border.width: vpx(1)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }

                        TextInput {
                            id: _keyInput
                            anchors {
                                left: parent.left; right: parent.right
                                verticalCenter: parent.verticalCenter
                                leftMargin: vpx(10); rightMargin: vpx(10)
                            }
                            color: _inputText; font.pixelSize: vpx(13)
                            font.family: global.fonts.sans
                            selectionColor: "#2a6496"; selectedTextColor: "#ffffff"
                            clip: true
                            readOnly: true
                            activeFocusOnPress: false
                            inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                            | Qt.ImhSensitiveData | Qt.ImhMultiLine

                            cursorDelegate: Rectangle {
                                id: _keyCursor
                                width: vpx(2)
                                height: vpx(16)
                                color: _cursorColor
                                visible: root._activeField === "key" && root._testState !== "testing"
                                SequentialAnimation on opacity {
                                    running: _keyCursor.visible
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 1; duration: 0 }
                                    NumberAnimation { to: 1; duration: 480 }
                                    NumberAnimation { to: 0; duration: 0 }
                                    NumberAnimation { to: 0; duration: 480 }
                                }
                                onVisibleChanged: if (!visible) opacity = 1
                            }

                            Text {
                                anchors.fill: parent
                                text: "your API key"
                                color: _placeholderText
                                font: _keyInput.font
                                visible: _keyInput.text.length === 0
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.IBeamCursor
                            onClicked: {
                                if (root._testState !== "testing")
                                    root._activateField("key")
                            }
                        }
                    }
                }
            }

            Item {
                width: parent.width
                height: root._testState !== "idle" ? vpx(34) : 0
                clip: true
                Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.InOutQuad } }

                Rectangle {
                    anchors { fill: parent; topMargin: vpx(2) }
                    radius: vpx(4)
                    color: {
                        if (root._testState === "testing") return _msgBgTesting
                            if (root._testState === "success") return _msgBgSuccess
                                return _msgBgError
                    }
                    Behavior on color { ColorAnimation { duration: 200 } }

                    Row {
                        anchors {
                            left: parent.left; leftMargin: vpx(10)
                            verticalCenter: parent.verticalCenter
                        }
                        spacing: vpx(8)

                        Item {
                            width: vpx(16); height: vpx(16)
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root._testState === "testing"
                            Rectangle {
                                anchors.fill: parent; radius: width / 2
                                color: "transparent"
                                border.width: vpx(2); border.color: _msgTextTesting
                                Rectangle {
                                    anchors { top: parent.top; horizontalCenter: parent.horizontalCenter }
                                    width: vpx(2); height: vpx(5); color: _msgTextTesting; radius: vpx(1)
                                }
                                RotationAnimator on rotation {
                                    running: root._testState === "testing"
                                    loops: Animation.Infinite; from: 0; to: 360; duration: 900
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root._testState === "success" || root._testState === "error"
                            text: root._testState === "success" ? "✔" : "✘"
                            color: root._testState === "success" ? _msgTextSuccess : _msgTextError
                            font.pixelSize: vpx(13); font.bold: true
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: {
                                if (root._testState === "testing") return "Verifying credentials…"
                                    return root._testMsg
                            }
                            color: {
                                if (root._testState === "testing") return _msgTextTesting
                                    if (root._testState === "success") return _msgTextSuccess
                                        return _msgTextError
                            }
                            font.pixelSize: vpx(11); font.family: global.fonts.sans
                            elide: Text.ElideRight; width: vpx(370)
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: vpx(12)

                Item {
                    id: _okBtn
                    width: vpx(90); height: vpx(32)
                    readonly property bool _busy: root._testState === "testing"

                    Rectangle {
                        anchors.fill: parent; radius: vpx(15)
                        color: {
                            if (_okBtn._busy) return _msgBgTesting
                                if (_okBtn.activeFocus) return _okBtnBgFocus
                                    return _okBtnBg
                        }
                        border.color: (_okBtn.activeFocus && !_okBtn._busy) ? _inputBorderActive : _inputBorder
                        border.width: vpx(1)
                        opacity: _okBtn._busy ? 0.5 : 1.0
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                        Behavior on opacity { NumberAnimation { duration: 150 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "OK"
                        font.pixelSize: vpx(13); font.family: global.fonts.sans; font.bold: true
                        color: (_okBtn.activeFocus && !_okBtn._busy) ? _okBtnTextFocus : _okBtnText
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Keys.onUpPressed: { event.accepted = true; _keyFieldScope.forceActiveFocus() }
                    Keys.onRightPressed: { event.accepted = true; _cancelBtn.forceActiveFocus() }
                    Keys.onPressed: {
                        if (_okBtn._busy) { event.accepted = true; return }
                        if (api.keys.isCancel(event)) { event.accepted = true; root.close(); return }
                        if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                            event.accepted = true; root._save(); return
                        }
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true; root._save()
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (!_okBtn._busy) root._save() }
                    }
                }

                Item {
                    id: _cancelBtn
                    width: vpx(90); height: vpx(32)

                    Rectangle {
                        anchors.fill: parent; radius: vpx(15)
                        color: _cancelBtn.activeFocus ? _cancelBtnBgFocus : _cancelBtnBg
                        border.color: _cancelBtn.activeFocus ? _cancelBtnBorderFocus : _cancelBtnBorder
                        border.width: vpx(1)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }
                    Text {
                        anchors.centerIn: parent
                        text: "Cancel"
                        font.pixelSize: vpx(13); font.family: global.fonts.sans; font.bold: true
                        color: _cancelBtn.activeFocus ? _cancelBtnTextFocus : _cancelBtnText
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Keys.onUpPressed: { event.accepted = true; _keyFieldScope.forceActiveFocus() }
                    Keys.onLeftPressed: { event.accepted = true; _okBtn.forceActiveFocus() }
                    Keys.onPressed: {
                        if (root._testState === "testing") { event.accepted = true; return }
                        if (api.keys.isCancel(event) || api.keys.isAccept(event)
                            || event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true; root.close()
                            }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: { if (root._testState !== "testing") root.close() }
                    }
                }
            }

            Item { width: 1; height: vpx(4) }
        }
    }
}
