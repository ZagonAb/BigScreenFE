// BigScreenFE Theme
// Copyright (C) 2026 Gonzalo
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/

import QtQuick 2.15

Item {
    id: root

    property string label: "L1"
    property string side:  "left"
    property bool isActive: false
    property bool lightTheme: false

    signal clicked()

    implicitWidth: vpx(52)
    implicitHeight: vpx(44)

    readonly property color _bgInactive: lightTheme ? "#0d1117" : "#ffffff"
    readonly property color _bgActive: lightTheme ? "#5a6472" : "#cccccc"
    readonly property color _textColor: lightTheme ? "#ffffff" : "#020508"

    Canvas {
        id: bg
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);

            var w = width;
            var h = height;
            var rBig = vpx(9);
            var rSmall = vpx(3);
            var x = 0;
            var y = 0;
            var tl = (root.side === "left")  ? rBig : rSmall;
            var tr = (root.side === "right") ? rBig : rSmall;
            var br = rSmall;
            var bl = rSmall;

            ctx.beginPath();
            ctx.moveTo(x + tl, y);
            ctx.lineTo(x + w - tr, y);
            ctx.arcTo(x + w, y, x + w, y + tr,     tr);
            ctx.lineTo(x + w, y + h - br);
            ctx.arcTo(x + w, y + h, x + w - br, y + h, br);
            ctx.lineTo(x + bl, y + h);
            ctx.arcTo(x, y + h, x, y + h - bl, bl);
            ctx.lineTo(x, y + tl);
            ctx.arcTo(x, y, x + tl, y, tl);
            ctx.closePath();

            ctx.fillStyle = root.isActive ? _bgActive : _bgInactive;
            ctx.fill();
        }
    }

    Text {
        id: btnText
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.isActive ? vpx(1) : 0
        text: root.label
        color: _textColor
        font.pixelSize: vpx(22)
        font.bold: true
        font.family: global.fonts.sans
        Behavior on anchors.verticalCenterOffset { NumberAnimation { duration: 80 } }
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: { root.isActive = true; bg.requestPaint() }
        onReleased: { root.isActive = false; bg.requestPaint(); root.clicked() }
        onCanceled: { root.isActive = false; bg.requestPaint() }
    }

    Connections {
        target: root
        function onIsActiveChanged() { bg.requestPaint() }
        function onLightThemeChanged() { bg.requestPaint() }
    }

    onWidthChanged: bg.requestPaint()
    onHeightChanged: bg.requestPaint()
    onVisibleChanged: if (visible) bg.requestPaint()
}
