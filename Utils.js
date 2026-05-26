// BigScreenFE Theme
// Copyright (C) 2026 Gonzalo
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/

function assetOrEmpty(url) {
    return url ? url : "";
}

function clamp(value, min, max) {
    return Math.max(min, Math.min(max, value));
}

function formatPlayTime(seconds) {
    if (!seconds || seconds <= 0) return "Never played";
    var h = Math.floor(seconds / 3600);
    var m = Math.floor((seconds % 3600) / 60);
    if (h > 0) return h + "h " + m + "m";
    return m + "m";
}

function formatDate(date) {
    if (!date || isNaN(date.getTime())) return "";
    var y = date.getFullYear();
    var mo = ("0" + (date.getMonth() + 1)).slice(-2);
    var d = ("0" + date.getDate()).slice(-2);
    return y + "-" + mo + "-" + d;
}

function formatRating(rating) {
    var stars = Math.round(rating * 5);
    var out = "";
    for (var i = 0; i < 5; i++) out += (i < stars) ? "★" : "☆";
    return out;
}

function normalizeForSearch(text) {
    if (!text) return "";
    return text.toLowerCase()
    .replace(/[áàäâã]/g, "a")
    .replace(/[éèëê]/g, "e")
    .replace(/[íìïî]/g, "i")
    .replace(/[óòöôõ]/g, "o")
    .replace(/[úùüû]/g, "u")
    .replace(/[ñ]/g, "n")
    .replace(/[ç]/g, "c")
    .trim();
}

function formatLastPlayed(date) {
    if (!date || isNaN(date.getTime())) return "";
    var now = new Date();
    var diffMs = now - date;
    var diffDays = Math.floor(diffMs / (1000 * 60 * 60 * 24));

    if (diffDays === 0) return "TODAY";
    if (diffDays === 1) return "YESTERDAY";
    if (diffDays <= 7) return "LAST WEEK";
    if (diffDays <= 14) return "LAST TWO WEEKS";
    if (diffDays <= 30) return "LAST MONTH";
    if (diffDays <= 365) return "LAST " + Math.floor(diffDays / 30) + " MONTHS";
    return "OVER A YEAR AGO";
}

var _genericHeaders = [
    "introduccion", "introducción",
"descripcion", "descripción",
"caracteristicas", "características",
"caracteristicas principales", "características principales",
"acerca de este juego", "acerca del juego",
"sobre el juego", "sobre este juego",
"introduction", "description", "overview",
"about this game", "about the game",
"features", "main features", "key features",
"synopsis", "sinopsis", "summary"
];

function _stripHtml(text) {
    var s = text;
    s = s.replace(/<video[\s\S]*?<\/video>/gi, " ");
    s = s.replace(/<span[\s\S]*?<\/span>/gi, " ");
    s = s.replace(/<br\s*\/?>/gi, " ");
    s = s.replace(/<[^>]+>/g, " ");
    s = s.replace(/&amp;/g, "&");
    s = s.replace(/&lt;/g, "<");
    s = s.replace(/&gt;/g, ">");
    s = s.replace(/&nbsp;/g, " ");
    s = s.replace(/&quot;/g, "\"");
    s = s.replace(/&#39;/g, "'");
    s = s.replace(/\r\n|\r|\n/g, " ");
    s = s.replace(/\s{2,}/g, " ");
    return s.trim();
}

function _isGenericHeader(fragment) {
    var l = fragment.toLowerCase().trim().replace(/[.:!?\-]+$/, "").replace(/^[\s]+/, "");
    for (var i = 0; i < _genericHeaders.length; i++) {
        if (l === _genericHeaders[i]) return true;
    }
    return false;
}

function truncateDescription(text) {
    if (!text) return "";

    var flat = _stripHtml(text);
    if (flat.length === 0) return "";

    var prefix = flat.substring(0, 80).toLowerCase();
    for (var h = 0; h < _genericHeaders.length; h++) {
        var hdr = _genericHeaders[h];
        var idx = prefix.indexOf(hdr);
        if (idx !== -1) {
            var before = flat.substring(0, idx).trim();
            if (before.length === 0) {
                flat = flat.substring(idx + hdr.length).replace(/^[\s]+/, "").trim();
                flat = flat.replace(/\s{2,}/g, " ");
                break;
            }
        }
    }

    var result = "";
    var dotCount = 0;
    var i = 0;
    while (i < flat.length && dotCount < 2) {
        var nextDot = flat.indexOf(".", i);
        if (nextDot === -1) {
            var rest = flat.substring(i).trim();
            if (rest.length > 0 && !_isGenericHeader(rest))
                result += (result.length > 0 ? " " : "") + rest;
            break;
        }
        var sentence = flat.substring(i, nextDot + 1).trim();
        if (!_isGenericHeader(sentence)) {
            result += (result.length > 0 ? " " : "") + sentence;
            dotCount++;
        }
        i = nextDot + 1;
    }

    return result.replace(/\s{2,}/g, " ").trim();
}

function gameMatchesSearch(game, query) {
    if (!query || query.length === 0) return true;
    var fields = [
        game.title || "",
        game.developer || "",
        game.publisher || "",
        game.genre || ""
    ];
    for (var i = 0; i < fields.length; i++) {
        if (normalizeForSearch(fields[i]).indexOf(query) !== -1)
            return true;
    }
    return false;
}

function getUniqueGenresFromGames(maxGenres) {
    var uniqueGenres = new Set();
    var genreCount = {};

    for (var i = 0; i < api.allGames.count; i++) {
        var game = api.allGames.get(i);
        if (game && game.genre) {
            var cleanedGenres = cleanAndSplitGenres(game.genre);
            cleanedGenres.forEach(function(genre) {
                if (genre && genre.trim() !== "") {
                    var cleanGenre = genre.trim();
                    uniqueGenres.add(cleanGenre);

                    if (!genreCount[cleanGenre]) {
                        genreCount[cleanGenre] = 0;
                    }
                    genreCount[cleanGenre]++;
                }
            });
        }
    }

    var genresArray = Array.from(uniqueGenres);
    genresArray.sort(function(a, b) {
        return (genreCount[b] || 0) - (genreCount[a] || 0);
    });

    if (maxGenres && maxGenres > 0) {
        return genresArray.slice(0, maxGenres);
    }

    return genresArray;
}

function cleanAndSplitGenres(genreText) {
    if (!genreText) return [];

    var separators = [",", "/", "-", "&", "|", ";"];
    var allParts = [genreText];

    for (var i = 0; i < separators.length; i++) {
        var separator = separators[i];
        var newParts = [];

        for (var j = 0; j < allParts.length; j++) {
            var part = allParts[j];
            var splitParts = part.split(separator);

            for (var k = 0; k < splitParts.length; k++) {
                newParts.push(splitParts[k]);
            }
        }
        allParts = newParts;
    }

    var cleanedParts = [];
    for (var l = 0; l < allParts.length; l++) {
        var cleaned = allParts[l].trim();

        if (cleaned.length > 0 &&
            cleaned.toLowerCase() !== "and" &&
            cleaned.toLowerCase() !== "or" &&
            cleaned.toLowerCase() !== "game" &&
            cleaned.length > 2) {
            cleanedParts.push(cleaned);
            }
    }

    return cleanedParts;
}

function getFirstGenre(gameData) {
    if (!gameData || !gameData.genre) return "Unknown";

    var cleanedGenres = cleanAndSplitGenres(gameData.genre);
    return cleanedGenres.length > 0 ? cleanedGenres[0] : "Unknown";
}
