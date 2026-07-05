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

    property var game: null
    property bool lightTheme: false

    readonly property color _textPrimary: lightTheme ? "#0d1117" : "#f0f4f8"
    readonly property color _textSecondary: lightTheme ? "#2a6080" : "#c8d8e8"
    readonly property color _textMuted: lightTheme ? "#5a6472" : "#b8bcbf"
    readonly property color _textDim: lightTheme ? "#8b929a" : "#585a60"
    readonly property color _bgCard: lightTheme ? "#f8f9fc" : "#1c2533"
    readonly property color _bgHighlight: lightTheme ? "#e9ecef" : "#3d4450"
    readonly property color _progressBg: lightTheme ? "#d1d5db" : "#585a60"
    readonly property color _progressFill: lightTheme ? "#1a6b7a" : "#1a9fff"
    readonly property color _progressFull: lightTheme ? "#0d9488" : "#f5a623"
    readonly property color _borderColor: lightTheme ? "#cbd5e1" : "#2a3a48"
    readonly property color _buttonBg: lightTheme ? "#e2e8f0" : "#1e2d3a"
    readonly property color _buttonBorder: lightTheme ? "#94a3b8" : "#2e3e50"
    readonly property color _buttonFocusBg: lightTheme ? "#0d1117" : "#f5a623"
    readonly property color _buttonFocusText: lightTheme ? "#ffffff" : "#0b1117"
    readonly property color _debugBg: lightTheme ? "#eef2f5" : "#050b12"
    readonly property color _debugText: lightTheme ? "#1a6b7a" : "#3a7a5a"
    readonly property color _iconColor: lightTheme ? "#0d1117" : "#ffffff"

    signal tabFocusRequested()
    signal gameSelected(var newGame)

    readonly property bool gridActiveFocus: {
        if (typeof _earnedListView !== "undefined" && _earnedListView.activeFocus) return true
            if (typeof _lockedListView !== "undefined" && _lockedListView.activeFocus) return true
                return false
    }
    readonly property bool hasGrid: true
    readonly property var currentGame: null

    function gridFocusAtZero() {
        if (_earnedList.length > 0) {
            root._activeSection = "earned"
            _earnedListView.forceActiveFocus()
        } else if (_lockedList.length > 0) {
            root._activeSection = "locked"
            _lockedListView.forceActiveFocus()
        }
    }

    property string _apiKey: api.memory.has("ra_api_key") ? api.memory.get("ra_api_key") : ""
    property string _apiUser: api.memory.has("ra_api_user") ? api.memory.get("ra_api_user") : ""

    readonly property string _base: "https://retroachievements.org/API/"
    readonly property string _media: "https://media.retroachievements.org"
    readonly property bool _hasCredentials: _apiKey !== "" && _apiUser !== ""

    property bool _searching: false
    property bool _loading: false

    property bool _notFound: false
    property bool _noAchievementsYet: false

    property string _errorMsg: ""
    property string _debugLog: ""

    property string _raGameId: ""
    property string _raTitle: ""
    property string _raConsole: ""
    property string _raImgIcon: ""
    property int _raNumAch: 0
    property int _raPoints: 0
    property int _numEarned: 0
    property var _achievements: []
    property int _selIdx: 0
    property int _raPlayers: 0

    function _log(msg) {
        root._debugLog = root._debugLog + "\n" + msg;
    }

    function _apiUrl(endpoint, params) {
        var url = _base + endpoint + "?y=" + _apiKey;
        for (var k in params) url += "&" + k + "=" + encodeURIComponent(params[k]);
        return url;
    }

    function _get(url, cb) {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState !== XMLHttpRequest.DONE) return;
            if (xhr.status === 200) {
                try { cb(null, JSON.parse(xhr.responseText)); }
                catch(e) { cb("JSON parse error: " + e, null); }
            } else {
                cb("HTTP " + xhr.status, null);
            }
        };
        xhr.send();
    }

    function _romanToArabic(str) {
        var map = {
            "xv": "15", "xiv": "14", "xiii": "13", "xii": "12", "xi": "11",
            "x": "10", "ix": "9", "viii": "8", "vii": "7", "vi": "6",
            "v": "5", "iv": "4", "iii": "3", "ii": "2", "i": "1"
        };
        return str.replace(/\b(x(?:iv|v|i{1,3})?|i{1,3}|iv|vi{0,3}|viii|ix)\b/g, function(m) {
            return map[m] || m;
        });
    }

    function _normalize(str) {
        if (!str) return "";
        return _romanToArabic(str.toLowerCase())
        .replace(/\b(the|a|an)\b\s*/g, "")
        .replace(/[:\-\u2013_',\.\!?®™©\(\)\[\]\/\\]/g, " ")
        .replace(/\s+/g, " ")
        .trim();
    }

    function _words(norm) {
        return norm.split(" ").filter(function(w){ return w.length >= 1; });
    }

    function _matchScore(pegTitle, raTitle) {
        var pNorm = _normalize(pegTitle);
        var rNorm = _normalize(raTitle);

        if (pNorm === rNorm) return 2.0;

        var pWords = _words(pNorm);
        var rWords = _words(rNorm);
        if (pWords.length === 0) return 0.0;

        var hitsP = 0;
        for (var i = 0; i < pWords.length; i++) {
            if (rNorm.indexOf(pWords[i]) !== -1) hitsP++;
        }
        var precision = hitsP / pWords.length;

        var hitsR = 0;
        for (var j = 0; j < rWords.length; j++) {
            if (pNorm.indexOf(rWords[j]) !== -1) hitsR++;
        }
        var recall = rWords.length > 0 ? hitsR / rWords.length : 0;

        if (precision + recall === 0) return 0.0;
        var f1 = 2.0 * precision * recall / (precision + recall);

        var extraInRA  = rWords.length - hitsR;
        var extraInPeg = pWords.length - hitsP;
        if (extraInRA > 0)  f1 = Math.max(0.0, f1 - (extraInRA  / rWords.length) * 0.5);
        if (extraInPeg > 0) f1 = Math.max(0.0, f1 - (extraInPeg / pWords.length) * 0.5);

        return f1;
    }

    readonly property var _consoleMappings: ({
        "snes": ["SNES/Super Famicom"],
        "superfamicom": ["SNES/Super Famicom"],
        "nes": ["NES/Famicom"],
        "famicom": ["NES/Famicom"],
        "fds": ["Famicom Disk System"],
        "famicomdisksystem": ["Famicom Disk System"],
        "n64": ["Nintendo 64"],
        "nintendo64": ["Nintendo 64"],
        "gb": ["Game Boy"],
        "gameboy": ["Game Boy"],
        "gbc": ["Game Boy Color"],
        "gameboycolor": ["Game Boy Color"],
        "gba": ["Game Boy Advance"],
        "gameboyadvance": ["Game Boy Advance"],
        "nds": ["Nintendo DS"],
        "nintendods": ["Nintendo DS"],
        "ndsi": ["Nintendo DSi"],
        "nintendodsi": ["Nintendo DSi"],
        "3ds": ["Nintendo 3DS"],
        "nintendo3ds": ["Nintendo 3DS"],
        "gamecube": ["GameCube"],
        "gc": ["GameCube"],
        "wii": ["Wii"],
        "wiiu": ["Wii U"],
        "virtualboy": ["Virtual Boy"],
        "pokemini": ["Pokemon Mini"],
        "genesis": ["Genesis/Mega Drive"],
        "megadrive": ["Genesis/Mega Drive"],
        "mastersystem": ["Master System"],
        "sms": ["Master System"],
        "gamegear": ["Game Gear"],
        "gg": ["Game Gear"],
        "saturn": ["Saturn"],
        "dreamcast": ["Dreamcast"],
        "segacd": ["Sega CD"],
        "megacd": ["Sega CD"],
        "32x": ["32X"],
        "sega32x": ["32X"],
        "segapico": ["Sega Pico"],
        "sg1000": ["SG-1000"],
        "psx": ["PlayStation"],
        "ps1": ["PlayStation"],
        "playstation": ["PlayStation"],
        "ps2": ["PlayStation 2"],
        "playstation2": ["PlayStation 2"],
        "psp": ["PlayStation Portable"],
        "atari2600": ["Atari 2600"],
        "atari5200": ["Atari 5200"],
        "atari7800": ["Atari 7800"],
        "lynx": ["Atari Lynx"],
        "atarilynx": ["Atari Lynx"],
        "jaguar": ["Atari Jaguar"],
        "atarijaguar": ["Atari Jaguar"],
        "jaguarcd": ["Atari Jaguar CD"],
        "atarijaguarcd": ["Atari Jaguar CD"],
        "atarist": ["Atari ST"],
        "pcengine": ["PC Engine/TurboGrafx-16"],
        "turbografx": ["PC Engine/TurboGrafx-16"],
        "tg16": ["PC Engine/TurboGrafx-16"],
        "pcenginecd": ["PC Engine CD/TurboGrafx-CD"],
        "turbografxcd": ["PC Engine CD/TurboGrafx-CD"],
        "pcfx": ["PC-FX"],
        "pc8800": ["PC-8000/8800"],
        "pc9800": ["PC-9800"],
        "pc6000": ["PC-6000"],
        "ngp": ["Neo Geo Pocket"],
        "neogeopocket": ["Neo Geo Pocket"],
        "neogeocd": ["Neo Geo CD"],
        "arcade": ["Arcade"],
        "mame": ["Arcade"],
        "wonderswan": ["WonderSwan"],
        "msx": ["MSX"],
        "colecovision": ["ColecoVision"],
        "intellivision": ["Intellivision"],
        "vectrex": ["Vectrex"],
        "3do": ["3DO Interactive Multiplayer"],
        "amiga": ["Amiga"],
        "amstradcpc": ["Amstrad CPC"],
        "appleii": ["Apple II"],
        "c64": ["Commodore 64"],
        "commodore64": ["Commodore 64"],
        "dos": ["DOS"],
        "vic20": ["VIC-20"],
        "zxspectrum": ["ZX Spectrum"],
        "zx81": ["ZX81"],
        "fmtowns": ["FM Towns"],
        "sharpx1": ["Sharp X1"],
        "sharpx68000": ["Sharp X68000"],
        "x68000": ["Sharp X68000"],
        "philipscdi": ["Philips CD-i"],
        "cdi": ["Philips CD-i"],
        "thomsonto8": ["Thomson TO8"],
        "oric": ["Oric"],
        "nokiangage": ["Nokia N-Gage"],
        "ngage": ["Nokia N-Gage"],
        "gameandwatch": ["Game & Watch"],
        "uzebox": ["Uzebox"],
        "arduboy": ["Arduboy"],
        "ti83": ["TI-83"],
        "tic80": ["TIC-80"],
        "wasm4": ["WASM-4"],
        "watarasupervision": ["Watara Supervision"],
        "supervision": ["Watara Supervision"],
        "megaduck": ["Mega Duck"],
        "zeebo": ["Zeebo"],
        "xbox": ["Xbox"]
    })

    readonly property var _consoleIds: ({
        "snes": 3, "superfamicom": 3,
        "nes": 7, "famicom": 7,
        "fds": 81, "famicomdisksystem": 81,
        "n64": 2, "nintendo64": 2,
        "gb": 4, "gameboy": 4,
        "gbc": 6, "gameboycolor": 6,
        "gba": 5, "gameboyadvance": 5,
        "nds": 18, "nintendods": 18,
        "ndsi": 78, "nintendodsi": 78,
        "3ds": 62, "nintendo3ds": 62,
        "gamecube": 16, "gc": 16,
        "wii": 19,
        "wiiu": 20,
        "virtualboy": 28,
        "pokemini": 24,
        "genesis": 1, "megadrive": 1,
        "mastersystem": 11, "sms": 11,
        "gamegear": 15, "gg": 15,
        "saturn": 39,
        "dreamcast": 40,
        "segacd": 9, "megacd": 9,
        "32x": 10, "sega32x": 10,
        "segapico": 68,
        "sg1000": 33,
        "psx": 12, "ps1": 12, "playstation": 12,
        "ps2": 21, "playstation2": 21,
        "psp": 41,
        "atari2600": 25,
        "atari5200": 50,
        "atari7800": 51,
        "lynx": 13, "atarilynx": 13,
        "jaguar": 17, "atarijaguar": 17,
        "jaguarcd": 77, "atarijaguarcd": 77,
        "atarist": 36,
        "pcengine": 8, "turbografx": 8, "tg16": 8,
        "pcenginecd": 76, "turbografxcd": 76,
        "pcfx": 49,
        "pc8800": 47,
        "pc9800": 48,
        "pc6000": 67,
        "ngp": 14, "neogeopocket": 14,
        "neogeocd": 56,
        "arcade": 27, "mame": 27,
        "wonderswan": 53,
        "msx": 29,
        "colecovision": 44,
        "intellivision": 45,
        "vectrex": 46,
        "3do": 43,
        "amiga": 35,
        "amstradcpc": 37,
        "appleii": 38,
        "c64": 30, "commodore64": 30,
        "dos": 26,
        "vic20": 34,
        "zxspectrum": 59,
        "zx81": 31,
        "fmtowns": 58,
        "sharpx1": 64,
        "sharpx68000": 52, "x68000": 52,
        "philipscdi": 42, "cdi": 42,
        "thomsonto8": 66,
        "oric": 32,
        "nokiangage": 61, "ngage": 61,
        "gameandwatch": 60,
        "uzebox": 80,
        "arduboy": 71,
        "ti83": 79,
        "tic80": 65,
        "wasm4": 72,
        "watarasupervision": 63, "supervision": 63,
        "megaduck": 69,
        "zeebo": 70,
        "xbox": 22
    })

    function _getCollectionShortName() {
        if (!game) return "";
        try {
            if (game.collections && game.collections.count > 0) {
                var col = game.collections.get(0);
                var name = col.name || "";
                var shortName = col.shortName || "";
                _log("Collection[0] name='" + name + "'  shortName='" + shortName + "'");
                var sn = shortName !== ""
                ? shortName.toLowerCase().replace(/[\s\-_]/g, "")
                : name.toLowerCase().replace(/[\s\-_]/g, "");
                return sn;
            } else {
                _log("game.collections: empty or unavailable");
            }
        } catch(e) {
            _log("game.collections read error: " + e);
        }
        return "";
    }

    function load() {
        _apiKey = api.memory.has("ra_api_key") ? api.memory.get("ra_api_key") : "";
        _apiUser = api.memory.has("ra_api_user") ? api.memory.get("ra_api_user") : "";

        _raGameId = ""; _raTitle = ""; _raConsole = ""; _raImgIcon = "";
        _raNumAch = 0; _raPoints = 0; _numEarned = 0;
        _achievements = []; _selIdx = 0;
        _notFound = false;
        _noAchievementsYet = false;
        _errorMsg = ""; _debugLog = "";
        _searching = false; _loading = false;

        _log("=== load() ===");

        if (!game) {
            _log("ERROR: game is null");
            _errorMsg = "No game selected.";
            return;
        }

        _log("game.title       = '" + (game.title || "") + "'");
        _log("game.developer   = '" + (game.developer || "") + "'");
        _log("game.publisher   = '" + (game.publisher || "") + "'");
        _log("game.genre       = '" + (game.genre || "") + "'");
        _log("game.releaseYear = '" + (game.releaseYear || "") + "'");

        var directId = "";
        try {
            if (typeof game.extraData !== "undefined" && game.extraData) {
                directId = game.extraData["x-id"]
                || game.extraData["ra_id"]
                || game.extraData["ra_game_id"]
                || game.extraData["retroachievements_id"]
                || "";
                _log("game.extraData ra_id = '" + directId + "'");
            } else {
                _log("game.extraData: not available");
            }
        } catch(e) {
            _log("game.extraData error: " + e);
        }

        var colShort = _getCollectionShortName();

        if (!_hasCredentials) {
            _log("No credentials (ra_api_key / ra_api_user missing)");
            _errorMsg = "Connect your RetroAchievements account\nto see your progress here.";
            return;
        }
        _log("Credentials OK: user='" + _apiUser + "', key=" + _apiKey.substring(0,4) + "****");

        if (directId !== "") {
            _log("Using direct RA ID from extraData: " + directId);
            _raGameId = directId;
            _fetchProgress(directId);
        } else {
            _searchForGame(colShort);
        }
    }

    function _searchForGame(colShort) {
        _searching = true;
        _log("Fetching API_GetUserCompletionProgress (c=500)...");

        var url = _apiUrl("API_GetUserCompletionProgress.php",
                          { u: _apiUser, c: 500, o: 0 });
        _get(url, function(err, data) {
            _searching = false;

            if (err || !data) {
                _log("API error: " + (err || "empty response"));
                _errorMsg = "Could not reach RetroAchievements.\n(" + (err || "empty") + ")";
                return;
            }

            var list = data.Results || (Array.isArray(data) ? data : []);
            _log("Received " + list.length + " games in user library");

            var pegTitle = game ? (game.title || "") : "";
            var pegNorm = _normalize(pegTitle);
            var raConsoles = _consoleMappings[colShort] || [];

            _log("Pegasus title (raw):        '" + pegTitle + "'");
            _log("Pegasus title (normalized): '" + pegNorm + "'");
            _log("Collection shortName key:   '" + colShort + "'");
            _log("Expected RA consoles:       " + JSON.stringify(raConsoles));

            var scored = [];
            for (var i = 0; i < list.length; i++) {
                var g = list[i];
                var sc = _matchScore(pegTitle, g.Title || "");

                if (raConsoles.length > 0 && (g.ConsoleName || "") !== "") {
                    var consoleMatch = false;
                    for (var ci = 0; ci < raConsoles.length; ci++) {
                        if ((g.ConsoleName || "").indexOf(raConsoles[ci]) !== -1) {
                            consoleMatch = true;
                            break;
                        }
                    }
                    sc = consoleMatch ? sc + 0.5 : sc - 0.2;
                }
                scored.push({ g: g, score: sc });
            }

            scored.sort(function(a, b){ return b.score - a.score; });

            _log("--- Top 8 candidates ---");
            for (var ti = 0; ti < Math.min(8, scored.length); ti++) {
                var s = scored[ti];
                _log("  [" + s.score.toFixed(3) + "] '" + (s.g.Title || "?")
                + "' | " + (s.g.ConsoleName || "?")
                + " | ID=" + (s.g.GameID || "?"));
            }
            _log("------------------------");

            var best = scored.length > 0 ? scored[0] : null;
            var bestF1Base = best ? _matchScore(pegTitle, best.g.Title || "") : 0;
            var THRESHOLD = 0.60;

            var bestConsoleMatch = false;
            if (best && raConsoles.length > 0 && (best.g.ConsoleName || "") !== "") {
                for (var cj = 0; cj < raConsoles.length; cj++) {
                    if ((best.g.ConsoleName || "").indexOf(raConsoles[cj]) !== -1) {
                        bestConsoleMatch = true;
                        break;
                    }
                }
            }
            var consoleCheckRequired = raConsoles.length > 0;
            var consoleOk = !consoleCheckRequired || bestConsoleMatch;

            var F1_MIN = 0.70;
            var accepted = best
            && bestF1Base >= F1_MIN
            && best.score >= THRESHOLD
            && consoleOk;

            _log("Acceptance check: f1=" + bestF1Base.toFixed(3)
            + " total=" + (best ? best.score.toFixed(3) : "n/a")
            + " consoleOk=" + consoleOk
            + " consoleCheckRequired=" + consoleCheckRequired
            + " bestConsoleMatch=" + bestConsoleMatch);

            if (accepted) {
                _log("MATCH ACCEPTED: f1=" + bestF1Base.toFixed(3)
                + " total=" + best.score.toFixed(3)
                + " title='" + best.g.Title + "' ID=" + best.g.GameID);
                _raGameId = String(best.g.GameID || "");
                _fetchProgress(_raGameId);
            } else {
                if (best) {
                    _log("MATCH REJECTED: f1=" + bestF1Base.toFixed(3)
                    + " total=" + best.score.toFixed(3)
                    + " consoleOk=" + consoleOk
                    + "  title='" + best.g.Title + "' console='" + (best.g.ConsoleName||"") + "'");
                } else {
                    _log("MATCH REJECTED: list was empty");
                }
                _log("Trying GetGameList fallback...");
                _searchByGameList(pegTitle, colShort);
            }
        });
    }

    function _searchByGameList(pegTitle, colShort) {
        var cid = _consoleIds[colShort] || 0;
        if (cid === 0) {
            _log("No console ID mapping for '" + colShort + "' – cannot use GetGameList");
            _showNotFound(pegTitle);
            return;
        }

        _log("Fetching API_GetGameList consoleId=" + cid + " ('" + colShort + "')...");
        var url = _apiUrl("API_GetGameList.php", { i: cid });
        _get(url, function(err, data) {
            if (err || !Array.isArray(data)) {
                _log("GetGameList error: " + (err || "not an array"));
                _showNotFound(pegTitle);
                return;
            }
            _log("GetGameList returned " + data.length + " games");

            var scored = [];
            for (var i = 0; i < data.length; i++) {
                var g = data[i];
                var sc = _matchScore(pegTitle, g.Title || "");
                scored.push({ g: g, score: sc });
            }
            scored.sort(function(a,b){ return b.score - a.score; });

            _log("--- GetGameList Top 8 ---");
            for (var ti = 0; ti < Math.min(8, scored.length); ti++) {
                var s = scored[ti];
                _log("  [" + s.score.toFixed(3) + "] '" + (s.g.Title || "?")
                + "' ID=" + (s.g.ID || s.g.GameID || "?"));
                console.log("[RA:fallback:top8] #" + (ti+1),
                            "score=" + s.score.toFixed(3),
                            "| title='" + (s.g.Title || "?") + "'",
                            "| ID=" + (s.g.ID || s.g.GameID || "?"));
            }
            _log("------------------------");

            var THRESHOLD = 0.55;
            var best = scored.length > 0 ? scored[0] : null;

            if (best && best.score >= THRESHOLD) {
                var gid = String(best.g.ID || best.g.GameID || "");
                _log("FALLBACK MATCH ACCEPTED: '" + best.g.Title + "' ID=" + gid);
                _raGameId = gid;
                _fetchProgress(gid);
            } else {
                _log("FALLBACK MATCH REJECTED"
                + (best ? ": best=" + best.score.toFixed(3) + " '" + best.g.Title + "'" : ""));
                _showNotFound(pegTitle);
            }
        });
    }

    function _showNotFound(pegTitle) {
        _log("=== NOT FOUND: '" + pegTitle + "' ===");
        _notFound = true;
    }

    function _fetchProgress(gid) {
        _loading = true;
        _log("Fetching API_GetGameInfoAndUserProgress ID=" + gid + " user=" + _apiUser + "...");

        var url = _apiUrl("API_GetGameInfoAndUserProgress.php",
                          { u: _apiUser, g: gid });
        _get(url, function(err, data) {
            _loading = false;

            if (err || !data) {
                _log("GetGameInfoAndUserProgress error: " + (err || "empty"));
                _errorMsg = "Could not load game data.\n(" + (err || "empty") + ")";
                return;
            }

            _raTitle = data.Title || "";
            _raConsole = data.ConsoleName || "";
            _raImgIcon = data.ImageIcon ? (_media + data.ImageIcon) : "";
            _raNumAch = parseInt(data.NumAchievements) || 0;
            _raPoints = parseInt(data.Points) || 0;
            _numEarned = parseInt(data.NumAwardedToUser) || 0;
            _raPlayers = parseInt(data.NumDistinctPlayersCasual) || 0;

            _log("Loaded: '" + _raTitle + "' / " + _raConsole);
            _log("Achievements: " + _numEarned + "/" + _raNumAch + "  Points: " + _raPoints);

            var ach = [];
            var achMap = data.Achievements || {};
            for (var id in achMap) {
                var a = achMap[id];
                var earned = (a.DateEarned && a.DateEarned !== "");
                ach.push({
                    id: id,
                    title: a.Title || "",
                    description: a.Description || "",
                    points: parseInt(a.Points) || 0,
                         badgeUrl: a.BadgeName ? (_media + "/Badge/" + a.BadgeName + ".png") : "",
                         badgeLocked: a.BadgeName ? (_media + "/Badge/" + a.BadgeName + "_lock.png") : "",
                         earned: earned,
                         dateEarned: earned ? a.DateEarned : "",
                         numAwarded: parseInt(a.NumAwarded) || 0,
                         trueRatio: parseInt(a.TrueRatio) || 0
                });
            }
            ach.sort(function(a, b) {
                if (a.earned !== b.earned) return a.earned ? -1 : 1;
                return b.points - a.points;
            });
            _achievements = ach;
            _earnedIdx = 0;
            _lockedIdx = 0;
            _activeSection = _earnedList.length > 0 ? "earned" : "locked";
            _log("Done. " + ach.length + " achievements loaded.");
            if (_raNumAch === 0) _noAchievementsYet = true;
        });
    }

    Component.onCompleted: load()
    onGameChanged: load()

    readonly property var _earnedList: {
        var r = []
        for (var i = 0; i < _achievements.length; i++)
            if (_achievements[i].earned) r.push(_achievements[i])
                return r
    }
    readonly property var _lockedList: {
        var r = []
        for (var i = 0; i < _achievements.length; i++)
            if (!_achievements[i].earned) r.push(_achievements[i])
                return r
    }

    property string _activeSection: "locked"
    property int _earnedIdx: 0
    property int _lockedIdx: 0

    readonly property var _activeAch: {
        if (_activeSection === "earned" && _earnedList.length > 0)
            return _earnedList[_earnedIdx]
            if (_lockedList.length > 0)
                return _lockedList[_lockedIdx]
                return {}
    }

    Item {
        anchors.fill: parent
        visible: !_searching && !_loading && _errorMsg !== ""

        Flickable {
            anchors.fill: parent
            contentHeight: _errCol.implicitHeight + vpx(16)
            clip: true

            Column {
                id: _errCol
                anchors { top: parent.top; left: parent.left; right: parent.right }
                spacing: vpx(10)

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: vpx(36); height: vpx(36)

                    Item {
                        id: _raIconContainer
                        anchors.fill: parent
                        visible: _raIconImg.status === Image.Ready
                        Image {
                            id: _raIconImg
                            anchors.fill: parent
                            source: "assets/icons/retroachievements.svg"
                            fillMode: Image.PreserveAspectFit
                            mipmap: true
                            visible: false
                        }
                        ColorOverlay {
                            anchors.fill: _raIconImg
                            source: _raIconImg
                            color: _iconColor
                            Behavior on color { ColorAnimation { duration: 300 } }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        visible: _raIconImg.status !== Image.Ready
                        text: "RA"
                        font.pixelSize: vpx(12)
                        font.bold: true
                        color: _iconColor
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root._errorMsg
                    font.pixelSize: vpx(12); font.family: global.fonts.sans
                    color: _textDim
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    width: parent.width * 0.85
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: vpx(90); height: vpx(28)
                    visible: root._hasCredentials
                    readonly property bool _foc: activeFocus
                    focus: true

                    Rectangle {
                        anchors.fill: parent; radius: vpx(14)
                        color: parent._foc ? _buttonFocusBg : _buttonBg
                        border.color: parent._foc ? _buttonFocusBg : _buttonBorder
                        border.width: vpx(1)
                        Behavior on color { ColorAnimation { duration: 150 } }
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }
                    Text {
                        anchors.centerIn: parent; text: "Retry"
                        font.pixelSize: vpx(11); font.family: global.fonts.sans; font.bold: true
                        color: parent._foc ? _buttonFocusText : _textSecondary
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }
                    Keys.onUpPressed: { event.accepted = true; root.tabFocusRequested() }
                    Keys.onPressed: {
                        if (!event.isAutoRepeat && api.keys.isAccept(event)) {
                            event.accepted = true; root.load()
                        }
                        if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                            event.accepted = true; root.tabFocusRequested()
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: root.load()
                    }
                }

                Rectangle {
                    width: parent.width
                    height: _dbgTxt.implicitHeight + vpx(14)
                    color: _debugBg
                    radius: vpx(4)
                    border.color: _borderColor
                    border.width: vpx(1)
                    visible: root._debugLog !== ""
                    Behavior on color { ColorAnimation { duration: 300 } }
                    Behavior on border.color { ColorAnimation { duration: 300 } }

                    Text {
                        id: _dbgTxt
                        anchors { fill: parent; margins: vpx(7) }
                        text: root._debugLog.trim()
                        font.pixelSize: vpx(9); font.family: "monospace"
                        color: _debugText
                        wrapMode: Text.WrapAnywhere
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }
            }
        }
    }

    Column {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        spacing: vpx(12)
        visible: _errorMsg === ""

        Column {
            width: parent.width
            spacing: vpx(6)

            Row {
                spacing: vpx(8)
                visible: !_searching && !_loading && _raNumAch > 0

                Text {
                    text: "You've unlocked " + root._numEarned + "/" + root._raNumAch
                    font.pixelSize: vpx(18); font.family: global.fonts.sans
                    color: _textSecondary
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
                Text {
                    visible: root._raNumAch > 0
                    text: "(" + Math.round(root._numEarned / root._raNumAch * 100) + "%)"
                    font.pixelSize: vpx(18); font.family: global.fonts.sans
                    color: _textDim
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                Text {
                    visible: root._raConsole !== ""
                    text: "· " + root._raConsole
                    font.pixelSize: vpx(18); font.family: global.fonts.sans
                    color: _textDim
                    anchors.verticalCenter: parent.verticalCenter
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }

            Item {
                width: parent.width; height: vpx(7)
                visible: root._raNumAch > 0

                Rectangle {
                    anchors.fill: parent; radius: vpx(2)
                    color: _progressBg
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
                Rectangle {
                    anchors { left: parent.left; top: parent.top; bottom: parent.bottom }
                    radius: vpx(2)
                    color: root._numEarned === root._raNumAch ? _progressFull : _progressFill
                    width: root._raNumAch > 0 ? parent.width * root._numEarned / root._raNumAch : 0
                    Behavior on width {
                        NumberAnimation { duration: 800; easing.type: Easing.OutQuad }
                    }
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }
        }

        Column {
            width: parent.width
            spacing: vpx(6)
            visible: root._earnedList.length > 0

            Item {
                x: -vpx(8)
                width: parent.width + vpx(16)
                height: vpx(158)
                clip: true

                Flickable {
                    id: _earnedListView
                    x: vpx(8)
                    width: parent.width - vpx(16)
                    height: vpx(140)
                    y: vpx(10)
                    contentWidth: _earnedRow.width + vpx(10)
                    interactive: false
                    clip: false

                    focus: root._earnedList.length > 0

                    Keys.onLeftPressed: {
                        event.accepted = true
                        if (root._earnedIdx > 0) {
                            root._earnedIdx--
                            var leftEdge = vpx(10) + root._earnedIdx * (vpx(100) + vpx(6))
                            _earnedListView.contentX = Math.min(_earnedListView.contentX, Math.max(0, leftEdge))
                        }
                    }
                    Keys.onRightPressed: {
                        event.accepted = true
                        if (root._earnedIdx < root._earnedList.length - 1) {
                            root._earnedIdx++
                            var rightEdge = vpx(10) + root._earnedIdx * (vpx(100) + vpx(6)) + vpx(640)
                            _earnedListView.contentX = Math.max(_earnedListView.contentX, Math.max(0, rightEdge - _earnedListView.width))
                        }
                    }
                    Keys.onUpPressed: {
                        event.accepted = true
                        root.tabFocusRequested()
                    }
                    Keys.onDownPressed: {
                        event.accepted = true
                        if (root._lockedList.length > 0) {
                            root._activeSection = "locked"
                            _lockedListView.forceActiveFocus()
                        }
                    }
                    Keys.onPressed: {
                        if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                            event.accepted = true; root.tabFocusRequested()
                        }
                    }
                    onActiveFocusChanged: {
                        if (activeFocus) root._activeSection = "earned"
                    }

                    Row {
                        id: _earnedRow
                        x: vpx(10)
                        spacing: vpx(6)

                        Repeater {
                            model: root._earnedList.length
                            delegate: Item {
                                id: _eItem
                                readonly property bool _sel: index === root._earnedIdx && root._activeSection === "earned"
                                readonly property var _a: root._earnedList[index] || {}

                                width: _sel ? vpx(640) : vpx(100)
                                height: vpx(100)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: vpx(0)
                                    color: _eItem._sel ? _bgHighlight : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Rectangle {
                                    id: selectionRect
                                    anchors.fill: parent
                                    property real borderExtra: 0
                                    anchors.margins: vpx(-3.5) - borderExtra
                                    border.width: vpx(1.5) + borderExtra
                                    color: "transparent"
                                    border.color: _textPrimary
                                    radius: vpx(0)
                                    opacity: 0
                                    SequentialAnimation on opacity {
                                        running: _eItem._sel && _earnedListView.activeFocus; loops: Animation.Infinite
                                        NumberAnimation { to: 0.8; duration: 600; easing.type: Easing.InOutQuad }
                                        NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutQuad }
                                        onStopped: selectionRect.opacity = 0
                                    }
                                    SequentialAnimation on borderExtra {
                                        id: borderPulseEarned; running: false
                                        NumberAnimation { to: vpx(3.5); duration: 150; easing.type: Easing.OutQuad }
                                        NumberAnimation { to: 0; duration: 250; easing.type: Easing.InQuad }
                                    }
                                }
                                on_SelChanged: { if (_eItem._sel && _earnedListView.activeFocus) borderPulseEarned.restart() }

                                Row {
                                    anchors {
                                        fill: parent
                                        leftMargin: vpx(10); rightMargin: vpx(10)
                                        topMargin: vpx(10); bottomMargin: vpx(10)
                                    }
                                    spacing: vpx(12)
                                    visible: _eItem._sel
                                    clip: true

                                    Image {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: vpx(75); height: vpx(75)
                                        source: _eItem._a.badgeUrl || ""
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true;
                                        Rectangle {
                                            anchors.fill: parent; radius: vpx(0)
                                            color: _bgCard
                                            visible: parent.status !== Image.Ready
                                            Behavior on color { ColorAnimation { duration: 300 } }
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: vpx(4)
                                        width: parent.width - vpx(76)

                                        Text {
                                            text: _eItem._a.title || ""
                                            font.pixelSize: vpx(16); font.bold: true
                                            font.family: global.fonts.sans; color: _textPrimary
                                            elide: Text.ElideRight; width: parent.width
                                            Behavior on color { ColorAnimation { duration: 300 } }
                                        }
                                        Text {
                                            text: _eItem._a.description || ""
                                            font.pixelSize: vpx(13); font.family: global.fonts.sans
                                            color: _textMuted
                                            elide: Text.ElideRight; width: parent.width
                                            Behavior on color { ColorAnimation { duration: 300 } }
                                        }
                                        Row {
                                            spacing: vpx(10)
                                            Text {
                                                visible: (_eItem._a.points || 0) > 0
                                                text: {
                                                    var p = _eItem._a.points || 0
                                                    var tr = _eItem._a.trueRatio || 0
                                                    return tr > p ? p + " (" + tr + ") pts" : p + " pts"
                                                }
                                                font.pixelSize: vpx(13); font.family: global.fonts.sans
                                                color: _progressFull
                                                anchors.verticalCenter: parent.verticalCenter
                                                Behavior on color { ColorAnimation { duration: 300 } }
                                            }
                                            Text {
                                                visible: (_eItem._a.numAwarded || 0) > 0 && root._raPlayers > 0
                                                text: {
                                                    var pct = Math.round((_eItem._a.numAwarded || 0) / root._raPlayers * 100)
                                                    return pct + "% unlock rate"
                                                }
                                                font.pixelSize: vpx(13); font.family: global.fonts.sans
                                                color: _textSecondary
                                                anchors.verticalCenter: parent.verticalCenter
                                                Behavior on color { ColorAnimation { duration: 300 } }
                                            }
                                        }
                                    }
                                }

                                Image {
                                    anchors.fill: parent
                                    source: _eItem._a.badgeUrl || ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true;
                                    visible: !_eItem._sel
                                    Rectangle {
                                        anchors.fill: parent; radius: vpx(0)
                                        color: _bgCard
                                        visible: parent.status !== Image.Ready
                                        Behavior on color { ColorAnimation { duration: 300 } }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        root._earnedIdx = index
                                        root._activeSection = "earned"
                                        _earnedListView.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Item {
            width: parent.width
            height: vpx(160)
            visible: (_searching || _loading || _raNumAch === 0) && !_notFound && !_noAchievementsYet

            Column {
                anchors.centerIn: parent
                spacing: vpx(16)

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: vpx(100); height: vpx(100)

                    Image {
                        id: _loadingIconSrc
                        anchors.fill: parent
                        source: "assets/icons/icon_0.png"
                        fillMode: Image.PreserveAspectFit
                        mipmap: true; smooth: true
                        visible: false
                    }

                    ColorOverlay {
                        id: _loadingIconOverlay
                        anchors.fill: parent
                        source: _loadingIconSrc
                        color: _iconColor
                        Behavior on color { ColorAnimation { duration: 300 } }
                        SequentialAnimation on scale {
                            running: _searching || _loading; loops: Animation.Infinite
                            NumberAnimation { to: 1.25; duration: 350; easing.type: Easing.InOutQuad }
                            NumberAnimation { to: 0.80; duration: 350; easing.type: Easing.InOutQuad }
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Loading…"
                    font.pixelSize: vpx(22)
                    font.family: global.fonts.sans
                    color: _textPrimary
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }
        }

        Item {
            width: parent.width
            height: vpx(160)
            visible: !_searching && !_loading && (_notFound || (_errorMsg === "" && _raGameId !== "" && _raNumAch === 0 && !_noAchievementsYet))

            Column {
                anchors.centerIn: parent
                spacing: vpx(10)

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: vpx(100); height: vpx(100)
                    visible: _noRaIconImg.status === Image.Ready
                    Image {
                        id: _noRaIconImg
                        anchors.fill: parent
                        source: "assets/icons/NO_RA.svg"
                        fillMode: Image.PreserveAspectFit
                        mipmap: true; smooth: true
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: _noRaIconImg
                        source: _noRaIconImg
                        color: _iconColor
                        opacity: 0.5
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No achievements for this game"
                    font.pixelSize: vpx(22); font.family: global.fonts.sans
                    color: _textPrimary
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }
        }

        Item {
            width: parent.width
            height: vpx(160)
            visible: !_searching && !_loading && _noAchievementsYet

            Column {
                anchors.centerIn: parent
                spacing: vpx(10)

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: vpx(100); height: vpx(100)
                    visible: _raIcon2Img.status === Image.Ready
                    Image {
                        id: _raIcon2Img
                        anchors.fill: parent
                        source: "assets/icons/RA.svg"
                        fillMode: Image.PreserveAspectFit
                        mipmap: true; smooth: true
                        visible: false
                    }
                    ColorOverlay {
                        anchors.fill: _raIcon2Img
                        source: _raIcon2Img
                        color: _iconColor
                        opacity: 0.5
                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No achievements yet for this game"
                    font.pixelSize: vpx(22); font.family: global.fonts.sans
                    color: _textPrimary
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }
        }

        Column {
            width: parent.width
            spacing: vpx(6)
            visible: root._lockedList.length > 0

            Text {
                text: "LOCKED ACHIEVEMENTS"
                font.pixelSize: vpx(18); font.bold: true; font.letterSpacing: vpx(1.5)
                font.family: global.fonts.sans; color: _textMuted
                Behavior on color { ColorAnimation { duration: 300 } }
            }

            Item {
                x: -vpx(8)
                width: parent.width + vpx(16)
                height: vpx(158)
                clip: true

                Flickable {
                    id: _lockedListView
                    x: vpx(8)
                    width: parent.width - vpx(16)
                    height: vpx(140)
                    y: vpx(10)
                    contentWidth: _lockedRow.width + vpx(10)
                    interactive: false
                    clip: false

                    focus: root._earnedList.length === 0

                    Keys.onLeftPressed: {
                        event.accepted = true
                        if (root._lockedIdx > 0) {
                            root._lockedIdx--
                            var leftEdge = vpx(10) + root._lockedIdx * (vpx(100) + vpx(6))
                            _lockedListView.contentX = Math.min(_lockedListView.contentX, Math.max(0, leftEdge))
                        }
                    }
                    Keys.onRightPressed: {
                        event.accepted = true
                        if (root._lockedIdx < root._lockedList.length - 1) {
                            root._lockedIdx++
                            var rightEdge = vpx(10) + root._lockedIdx * (vpx(100) + vpx(6)) + vpx(640)
                            _lockedListView.contentX = Math.max(_lockedListView.contentX, Math.max(0, rightEdge - _lockedListView.width))
                        }
                    }
                    Keys.onUpPressed: {
                        event.accepted = true
                        if (root._earnedList.length > 0) {
                            root._activeSection = "earned"
                            _earnedListView.forceActiveFocus()
                        } else {
                            root.tabFocusRequested()
                        }
                    }
                    Keys.onDownPressed: { event.accepted = true }
                    Keys.onPressed: {
                        if (!event.isAutoRepeat && api.keys.isCancel(event)) {
                            event.accepted = true; root.tabFocusRequested()
                        }
                    }
                    onActiveFocusChanged: {
                        if (activeFocus) root._activeSection = "locked"
                    }

                    Row {
                        id: _lockedRow
                        x: vpx(10)
                        spacing: vpx(6)

                        Repeater {
                            model: root._lockedList.length

                            delegate: Item {
                                id: _lItem
                                readonly property bool _sel: index === root._lockedIdx && (root._earnedList.length === 0 || root._activeSection === "locked")
                                readonly property var _a: root._lockedList[index] || {}

                                width: _sel ? vpx(640) : vpx(100)
                                height: vpx(100)

                                Rectangle {
                                    anchors.fill: parent
                                    radius: vpx(0)
                                    color: _lItem._sel ? _bgHighlight : "transparent"
                                    Behavior on color { ColorAnimation { duration: 150 } }
                                }

                                Rectangle {
                                    id: selectionRect2
                                    anchors.fill: parent
                                    property real borderExtra: 0
                                    anchors.margins: vpx(-3.5) - borderExtra
                                    border.width: vpx(1.5) + borderExtra
                                    color: "transparent"
                                    border.color: _textPrimary
                                    radius: vpx(0)
                                    opacity: 0
                                    SequentialAnimation on opacity {
                                        running: _lItem._sel && _lockedListView.activeFocus; loops: Animation.Infinite
                                        NumberAnimation { to: 0.8; duration: 600; easing.type: Easing.InOutQuad }
                                        NumberAnimation { to: 0.3; duration: 600; easing.type: Easing.InOutQuad }
                                        onStopped: selectionRect2.opacity = 0
                                    }
                                    SequentialAnimation on borderExtra {
                                        id: borderPulseLocked; running: false
                                        NumberAnimation { to: vpx(3.5); duration: 150; easing.type: Easing.OutQuad }
                                        NumberAnimation { to: 0; duration: 250; easing.type: Easing.InQuad }
                                    }
                                }
                                on_SelChanged: { if (_lItem._sel && _lockedListView.activeFocus) borderPulseLocked.restart() }

                                Row {
                                    anchors {
                                        fill: parent
                                        leftMargin: vpx(10); rightMargin: vpx(10)
                                        topMargin: vpx(8); bottomMargin: vpx(8)
                                    }
                                    spacing: vpx(12)
                                    visible: _lItem._sel
                                    clip: true

                                    Image {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: vpx(75); height: vpx(75)
                                        source: _lItem._a.badgeLocked || ""
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true;
                                        layer.enabled: true
                                        layer.effect: Desaturate { desaturation: 0.85 }
                                        Rectangle {
                                            anchors.fill: parent; radius: vpx(0)
                                            color: _bgCard
                                            visible: parent.status !== Image.Ready
                                            Behavior on color { ColorAnimation { duration: 300 } }
                                        }
                                    }

                                    Column {
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: vpx(4)
                                        width: parent.width - vpx(64)

                                        Text {
                                            text: _lItem._a.title || ""
                                            font.pixelSize: vpx(16); font.bold: true
                                            font.family: global.fonts.sans; color: _textPrimary
                                            elide: Text.ElideRight; width: parent.width
                                            Behavior on color { ColorAnimation { duration: 300 } }
                                        }
                                        Text {
                                            text: _lItem._a.description || ""
                                            font.pixelSize: vpx(13); font.family: global.fonts.sans
                                            color: _textMuted
                                            elide: Text.ElideRight; width: parent.width
                                            Behavior on color { ColorAnimation { duration: 300 } }
                                        }
                                        Text {
                                            visible: (_lItem._a.points || 0) > 0
                                            text: (_lItem._a.points || 0) + " pts"
                                            font.pixelSize: vpx(13); font.family: global.fonts.sans
                                            color: _textDim
                                            Behavior on color { ColorAnimation { duration: 300 } }
                                        }
                                    }
                                }

                                Image {
                                    anchors.fill: parent
                                    source: _lItem._a.badgeLocked || ""
                                    fillMode: Image.PreserveAspectFit
                                    asynchronous: true;
                                    visible: !_lItem._sel
                                    layer.enabled: true
                                    layer.effect: Desaturate { desaturation: 0.85 }
                                    Rectangle {
                                        anchors.fill: parent; radius: vpx(0)
                                        color: _bgCard
                                        visible: parent.status !== Image.Ready
                                        Behavior on color { ColorAnimation { duration: 300 } }
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        root._lockedIdx = index
                                        root._activeSection = "locked"
                                        _lockedListView.forceActiveFocus()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
