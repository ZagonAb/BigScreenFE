// BigScreenFE Theme
// Copyright (C) 2026 Gonzalo
//
// Licensed under Creative Commons
// Attribution-NonCommercial-ShareAlike 4.0 International.
//
// https://creativecommons.org/licenses/by-nc-sa/4.0/

import QtQuick 2.15
import SortFilterProxyModel 0.2

Item {
    id: root

    property alias model: collectionsListModel
    property alias favoritesModel: favoritesModel
    property alias lastPlayedModel: lastPlayedModel
    property bool favoritesVisible: favoritesModel.count > 0
    readonly property int allGamesCount: allGamesModel.count

    SortFilterProxyModel {
        id: allGamesModel
        sourceModel: api.allGames
        sorters: RoleSorter {
            roleName: "sortBy"
            sortOrder: Qt.AscendingOrder
        }
    }

    SortFilterProxyModel {
        id: favoritesModel
        sourceModel: api.allGames
        filters: ValueFilter { roleName: "favorite"; value: true }
        sorters: RoleSorter  { roleName: "sortBy";   sortOrder: Qt.AscendingOrder }
    }

    SortFilterProxyModel {
        id: lastPlayedModel
        sourceModel: api.allGames
        filters: ExpressionFilter {
            expression: {
                var d = model.lastPlayed;
                return d instanceof Date && !isNaN(d.getTime());
            }
        }
        sorters: RoleSorter { roleName: "lastPlayed"; sortOrder: Qt.DescendingOrder }
    }

    ListModel {
        id: collectionsListModel

        Component.onCompleted: {
            collectionsListModel.append({
                name: "All Games", shortName: "allgames",
                games: allGamesModel, isCollections: false
            });
            collectionsListModel.append({
                name: "Favorites", shortName: "favorites",
                games: favoritesModel, isCollections: false
            });
            collectionsListModel.append({
                name: "Collections", shortName: "collections",
                games: allGamesModel, isCollections: true
            });
            collectionsListModel.append({
                name: "Last Played", shortName: "lastplayed",
                games: lastPlayedModel, isCollections: false
            });
        }
    }
}
