// BigScreenFE Theme
// Copyright (C) 2026 Gonzalo
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/

import QtQuick 2.15
import "Utils.js" as Utils

Item {
    id: root

    property var game: null
    property bool lightTheme: false

    readonly property color _textPrimary: lightTheme ? "#0d1117" : "#e0e8ee"
    readonly property color _textSecondary: lightTheme ? "#5a6472" : "#b3b5b7"
    readonly property color _textMuted: lightTheme ? "#8b929a" : "#73787b"

    readonly property string _boxFront: game ? (game.assets.boxFront || "") : ""
    readonly property bool _hasBox: _boxFront !== ""

    implicitHeight: Math.max(_boxArea.implicitHeight, _rightCol.implicitHeight)

    Item {
        id: _boxArea
        anchors {
            top: parent.top
            left: parent.left
        }
        width: vpx(250)
        implicitHeight: vpx(320)
        visible: root._hasBox

        Image {
            id: _boxImg
            anchors.fill: parent
            source: root._boxFront
            fillMode: Image.PreserveAspectFit
            verticalAlignment: Image.AlignTop
            horizontalAlignment: Image.AlignLeft
            asynchronous: true
            smooth: true
            mipmap: true
        }
    }

    Column {
        id: _rightCol
        anchors {
            top: parent.top
            left: root._hasBox ? _boxArea.right : parent.left
            right: parent.right
            leftMargin: root._hasBox ? vpx(24) : 0
        }
        spacing: vpx(16)

        Text {
            id: _desc
            width: parent.width
            visible: root.game && root.game.description && root.game.description !== ""
            text: root.game ? Utils.truncateDescription(root.game.description || "") : ""
            color: root._textSecondary
            font.family: global.fonts.sans
            font.pixelSize: vpx(18)
            wrapMode: Text.WordWrap
            lineHeight: 1.55
            Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.InOutQuad } }
        }

        Column {
            width: parent.width
            spacing: vpx(8)
            visible: root.game !== null

            Repeater {
                model: [
                    { label: "Developer", value: root.game ? (root.game.developer || "") : "" },
                    { label: "Publisher", value: root.game ? (root.game.publisher || "") : "" },
                    { label: "Genre", value: root.game ? (root.game.genre || "") : "" },
                    { label: "Release Date", value: root.game && root.game.releaseYear > 0 ? String(root.game.releaseYear) : "" },
                    { label: "Players", value: root.game && root.game.players > 0 ? (root.game.players === 1 ? "Single-Player" : "1–" + root.game.players + " Players") : "" }
                ]

                delegate: Row {
                    visible: modelData.value !== ""
                    spacing: vpx(6)

                    Text {
                        text: modelData.label + ":"
                        color: root._textMuted
                        font.family: global.fonts.sans
                        font.pixelSize: vpx(16)
                        Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                    }

                    Text {
                        text: modelData.value
                        color: root._textSecondary
                        font.family: global.fonts.sans
                        font.pixelSize: vpx(16)
                        font.bold: true
                        Behavior on color { ColorAnimation { duration: 300; easing.type: Easing.InOutQuad } }
                    }
                }
            }
        }
    }
}
