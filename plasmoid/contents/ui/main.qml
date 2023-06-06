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
    property string lastUpdated

    Plasmoid.icon: Qt.resolvedUrl("./finance.svg")

    Plasmoid.preferredRepresentation: Plasmoid.compactRepresentation

    ListModel {
        id: symbolsModel
    }

    //
    // Compact Representation
    //
    Plasmoid.compactRepresentation: Item {

        Layout.minimumHeight: 50 * symbolsModel.count

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
                ColumnLayout {
                    id: infoColumn
                    Layout.fillWidth: true
                    spacing: -1

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignLeft

                        height: 25

                        text: longName
                        // Sometimes it has HTML encoded characters
                        // StyledText will render them nicely (and more performant than RichText)
                        textFormat: Text.StyledText
                        elide: Text.ElideMiddle
                    }

                    PlasmaComponents3.Label {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignRight

                        height: 25
                        font.weight: Font.Black

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
        RowLayout {
            id: headerRow
            width: parent.width
            height: title.implicitHeight
            PlasmaExtras.Title {
                id: title
                Layout.fillWidth: true
                Layout.preferredHeight: implicitHeight
                text: stack.currentPage.title
            }
            PlasmaComponents3.ToolButton {
                visible: stack.depth === 1
                icon.name: "view-refresh"
                onClicked: {
                    mainPage.refresh();
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
            anchors {
                top: headerRow.bottom
                left: parent.left
                right: parent.right
                bottom: footer.top
                topMargin: units.smallSpacing
                bottomMargin: units.smallSpacing
            }
        }

        PlasmaComponents3.Label {
            id: footer
            anchors.bottom: parent.bottom
            width: parent.width

            font.pointSize: theme.smallestFont.pointSize
            font.weight: Font.Thin
            font.underline: true
            opacity: 0.7
            linkColor: theme.textColor
            elide: Text.ElideLeft
            horizontalAlignment: Text.AlignRight
            text: "<a href='https://finance.yahoo.com/'>Powered by Yahoo! Finance</a>"
            onLinkActivated: Qt.openUrlExternally(link)

            PlasmaCore.ToolTipArea {
                id: tooltip
                anchors.fill: parent
                mainText: "Last Updated"
                subText: lastUpdated
            }
        }

        MainPage {
            id: mainPage
            stack: stack
        }

        Component.onCompleted: {
            stack.push(mainPage);
        }
    }
}
