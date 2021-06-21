/**
 *  This file is part of YapStocks.
 *
 *  Copyright 2020 Symeon Huang (@librehat)
 *
 *  YapStocks is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.

 *  YapStocks is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with YapStocks.  If not, see <https://www.gnu.org/licenses/>.
 */
import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQml.Models 2.12
import org.kde.plasma.plasmoid 2.0
import org.kde.plasma.core 2.0 as PlasmaCore
import org.kde.plasma.components 2.0 as PlasmaComponents
import org.kde.plasma.components 3.0 as PlasmaComponents3
import org.kde.plasma.extras 2.0 as PlasmaExtras

Item {
    id: root

    property bool loading: false
    property string lastUpdated

    readonly property var symbols: plasmoid.configuration.symbols
    readonly property int updateInterval: plasmoid.configuration.updateInterval

    Plasmoid.icon: Qt.resolvedUrl("./finance.svg")

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    ListModel {
        id: symbolsModel
    }

    //
    // Compact Representation
    //
    Plasmoid.compactRepresentation: Item {

        Layout.minimumHeight: 25 * symbolsModel.count

        /*function localiseNumber(num) {
            if (typeof num === "string") {
                return "N/A";
            }
            return Number(num).toLocaleString(locale, "f", priceDecimals);
        }*/

        ListView {
            id: view

            anchors.fill: parent

            model: symbolsModel
            delegate: PlasmaComponents.ListItem {
                RowLayout {
                    id: contentRow
                    anchors.fill: parent

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignLeft

                        height: 25

                        text: currentPrice
                    }
                }
            }
        }

        // click to toggle the popup
        MouseArea {
            anchors.fill: parent
            onClicked: plasmoid.expanded = !plasmoid.expanded
        }
    }

    //
    // Full Representation
    //
    Plasmoid.fullRepresentation: Item {

        id: rootFull

        RowLayout {
            id: headerRow
            width: parent.width
            height: title.implicitHeight
            PlasmaExtras.Title {
                id: title
                Layout.fillWidth: true
                text: stack.currentPage.title
            }
            PlasmaComponents3.ToolButton {
                visible: stack.depth === 1
                icon.name: "view-refresh"
                onClicked: {
                    timer.restart();
                    rootFull.refresh();
                }

                PlasmaComponents3.ToolTip {
                    text: "Refresh the data"
                }
            }
            PlasmaComponents3.ToolButton {
                visible: stack.depth > 1
                icon.name: "draw-arrow-back"
                onClicked: stack.pop()

                PlasmaComponents3.ToolTip {
                    text: "Return to previous page"
                }
            }
        }

        PlasmaComponents.PageStack {
            id: stack
            initialPage: mainView
            anchors {
                top: headerRow.bottom
                left: parent.left
                right: parent.right
                bottom: footer.top
                topMargin: units.smallSpacing
                bottomMargin: units.smallSpacing
            }
        }

        PlasmaComponents.Page {  // Ubuntu 20.04 doesn't have PlasmaComponents3.Page
            id: mainView
            readonly property string title: "Stocks"

            PlasmaComponents3.ScrollView {
                anchors.fill: parent
                ListView {
                    id: view

                    model: symbolsModel
                    delegate: StockQuoteDelegate {
                        width: parent.width
                        onPricesClicked: {
                            stack.push(chartComponent, {symbol, stack});
                        }
                        onNamesClicked: {
                            stack.push(profileComponent, {symbol, stack});
                        }
                    }
                }
            }
        }

        PlasmaComponents3.Label {
            id: footer
            anchors.bottom: parent.bottom
            anchors.right: parent.right

            font.pointSize: theme.smallestFont.pointSize
            font.weight: Font.Thin
            font.underline: true
            opacity: 0.7
            linkColor: theme.textColor
            text: "<a href='https://finance.yahoo.com/'>Powered by Yahoo! Finance</a>"
            onLinkActivated: Qt.openUrlExternally(link)

            PlasmaCore.ToolTipArea {
                id: tooltip
                anchors.fill: parent
                mainText: "Last Updated"
                subText: lastUpdated
            }
        }

        Component {
            id: profileComponent
            ProfilePage {}
        }

        Component {
            id: chartComponent
            PriceChart {}
        }

        PlasmaComponents3.BusyIndicator {
            anchors.centerIn: parent
            visible: loading
            running: loading
        }
    }

    function refresh() {
        if (symbols && symbols.length > 0) {
            loading = true;
            worker.sendMessage({action: "modify", symbols: symbols, model: symbolsModel});
        } else {
            symbolsModel.clear();
        }
    }

    WorkerScript {
        id: worker
        source: "../code/dataloader.mjs"
        onMessage: {
            loading = false;
            lastUpdated = (new Date()).toLocaleString();
            timer.restart();
        }

        Component.onCompleted: {
            // refresh on start up for the initial load
            root.refresh();
            // connecting signals here to avoid sending messages to the worker before it's ready
            root.symbolsChanged.connect(root.refresh);
        }
    }

    Timer {
        id: timer
        interval: updateInterval
        running: true
        repeat: true
        onTriggered: {
            if (symbolsModel.count > 0) {
                loading = true;
                worker.sendMessage({action: "refresh", model: symbolsModel});
            }
        }
    }
}
