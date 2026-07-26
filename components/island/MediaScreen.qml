import QtQuick
import Quickshell.Services.Mpris
import "../../core"

Item {
    id: root
    
    // --- EMPTY STATE ---
    Column {
        anchors.centerIn: parent
        spacing: 15
        visible: playerRepeater.count === 0
        
        Text {
            text: "Media"
            color: Theme.primary 
            font.pixelSize: 22
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Text {
            text: "No media playing"
            color: Theme.secondary 
            font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    // --- ACTIVE STATE ---
    Repeater {
        id: playerRepeater
        model: Mpris.players

        delegate: Item {
            width: root.width
            height: root.height
            
            visible: index === 0 

            property var player: modelData
            
            // Metadata extraction
            property string trackName: player.title || (player.metadata && player.metadata["xesam:title"]) || "Unknown Track"
            property string coverUrl: player.artUrl || (player.metadata && player.metadata["mpris:artUrl"]) || ""
            
            // Parse the artist array
            property string artistName: {
                var metaArtist = player.metadata ? player.metadata["xesam:artist"] : null;
                if (!metaArtist) return player.artist ? String(player.artist) : "Unknown Artist";
                
                // Since xesam:artist is an array of strings, we explicitly grab the first item
                if (Array.isArray(metaArtist) || typeof metaArtist === "object") {
                    return metaArtist.length > 0 ? String(metaArtist[0]) : "Unknown Artist";
                }
                return String(metaArtist);
            }

            property bool isPlaying: {
                var stateString = String(player.playbackState).toLowerCase();
                var statusString = String(player.playbackStatus).toLowerCase();
                
                return stateString === "playing" || 
                       stateString === "1";
            }

            Row {
                anchors.centerIn: parent
                spacing: 20
                width: parent.width * 0.85
                height: 90 

                // --- ALBUM COVER ART ---
                Rectangle {
                    width: height
                    height: parent.height
                    radius: 12
                    color: Theme.surface 
                    border.color: Theme.secondary
                    border.width: 1
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: coverUrl
                        fillMode: Image.PreserveAspectCrop
                        
                        Text {
                            anchors.centerIn: parent
                            text: "🎵"
                            font.pixelSize: 32
                            visible: parent.status !== Image.Ready
                        }
                    }
                }

                // --- TRACK INFO & CONTROLS ---
                Column {
                    width: parent.width - parent.height - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Column {
                        width: parent.width
                        spacing: 2

                        Text {
                            text: trackName
                            color: Theme.primary 
                            font.pixelSize: 18
                            font.bold: true
                            elide: Text.ElideRight
                            width: parent.width
                        }
                        
                        Text {
                            text: artistName
                            color: Theme.secondary 
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            width: parent.width
                        }
                    }

                    Row {
                        spacing: 24

                        Text {
                            text: "⏮"
                            color: prevArea.pressed ? Theme.primary : Theme.surfaceText
                            font.pixelSize: 22
                            
                            MouseArea {
                                id: prevArea
                                anchors.fill: parent
                                anchors.margins: -10
                                onClicked: if (typeof player.previous === "function") player.previous()
                            }
                        }

                        Text {
                            text: isPlaying ? "⏸" : "▶"
                            color: playArea.pressed ? Theme.primary : Theme.surfaceText
                            font.pixelSize: 22
                            
                            MouseArea {
                                id: playArea
                                anchors.fill: parent
                                anchors.margins: -10
                                onClicked: {
                                    if (typeof player.togglePlaying === "function") {
                                        player.togglePlaying()
                                    }
                                }
                            }
                        }

                        Text {
                            text: "⏭"
                            color: nextArea.pressed ? Theme.primary : Theme.surfaceText
                            font.pixelSize: 22
                            
                            MouseArea {
                                id: nextArea
                                anchors.fill: parent
                                anchors.margins: -10
                                onClicked: if (typeof player.next === "function") player.next()
                            }
                        }
                    }
                }
            }
        }
    }
}