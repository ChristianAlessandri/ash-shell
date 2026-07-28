import QtQuick
import QtQuick.Layouts 
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects
import "../../core"
import "../../components"
import "../../core/MprisUtils.js" as MprisUtils

Item {
    id: root
    
    // --- EMPTY STATE ---
    Column {
        anchors.centerIn: parent
        spacing: 15
        visible: playerRepeater.count === 0
        
        Text { text: "Media"; color: Theme.primary; font.pixelSize: 22; font.bold: true; anchors.horizontalCenter: parent.horizontalCenter }
        Text { text: "No media playing"; color: Theme.secondary; font.pixelSize: 14; anchors.horizontalCenter: parent.horizontalCenter }
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
            
            // SHARED PROPERTIES
            property string trackName: MprisUtils.getTrackName(player)
            property string coverUrl: MprisUtils.getCoverUrl(player)
            property string artistName: MprisUtils.getArtistName(player)
            property bool isPlaying: MprisUtils.isPlaying(player)

            // --- LYRICS STATE MANAGEMENT ---
            property string activeLyricLine: ""
            property string previousLyricLine: ""
            property string nextLyricLine: ""
            property var parsedLyricsData: [] 
            property real localPositionSec: 0
            property string lastFetchedTrack: ""

            onTrackNameChanged: {
                if (trackName !== lastFetchedTrack) {
                    localPositionSec = 0;
                    fetchLyrics();
                }
            }
            
            Component.onCompleted: fetchLyrics()

            function fetchLyrics() {
                if (trackName === "Unknown Track" || trackName === "") {
                    previousLyricLine = "";
                    activeLyricLine = "";
                    nextLyricLine = "";
                    return;
                }

                if (trackName === lastFetchedTrack)
                    return;

                lastFetchedTrack = trackName;

                previousLyricLine = "";
                activeLyricLine = "Fetching lyrics..."; 
                nextLyricLine = "";
                parsedLyricsData = [];

                var cleanArtist = artistName.split(/,|\s+e\s+|\s+&\s+|\s+feat\.?\s+|\s+ft\.?\s+/i)[0].trim();
                var cleanTrack = trackName.replace(/\s*\(.*?\)/g, "").trim();
                var query = cleanTrack + " " + cleanArtist;

                var xhr = new XMLHttpRequest();
                var url = "https://lrclib.net/api/search?q=" + encodeURIComponent(query);
                
                xhr.open("GET", url, true);
                xhr.setRequestHeader("Content-Type", "application/json");
                
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200) {
                            var response = JSON.parse(xhr.responseText);
                            if (response.length > 0) {
                                var bestMatch = response[0];
                                if (bestMatch.syncedLyrics) {
                                    parseLRC(bestMatch.syncedLyrics);
                                    updateActiveLyric(0);
                                } else {
                                    activeLyricLine = "No synced lyrics available"; 
                                }
                            } else {
                                activeLyricLine = "Lyrics not found";
                            }
                        } else {
                            activeLyricLine = "Error connecting to LRCLib";
                        }
                    }
                }
                xhr.send();
            }

            function parseLRC(lrcString) {
                var lines = lrcString.split("\n");
                var tempLyrics = [];
                var regex = /\[(\d+):(\d+(?:\.\d+)?)\](.*)/;

                for (var i = 0; i < lines.length; i++) {
                    var match = regex.exec(lines[i]);
                    if (!match) continue;
                    var text = match[3].trim();
                    if (text.length === 0) continue;

                    tempLyrics.push({
                        time: parseInt(match[1], 10) * 60 + parseFloat(match[2]),
                        text: text
                    });
                }
                parsedLyricsData = tempLyrics;
            }

            function updateActiveLyric(timeSec) {
                if (parsedLyricsData.length === 0) {
                    previousLyricLine = "";
                    activeLyricLine = "♪";
                    nextLyricLine = "";
                    return;
                }

                var current = -1;
                for (var i = 0; i < parsedLyricsData.length; i++) {
                    if (timeSec >= parsedLyricsData[i].time)
                        current = i;
                    else
                        break;
                }

                if (current < 0) {
                    previousLyricLine = "";
                    activeLyricLine = "♪";
                    nextLyricLine = parsedLyricsData[0].text;
                    return;
                }

                previousLyricLine = current > 0 ? parsedLyricsData[current - 1].text : "";
                activeLyricLine = parsedLyricsData[current].text;
                nextLyricLine = current < parsedLyricsData.length - 1 ? parsedLyricsData[current + 1].text : "";
            }

            Timer {
                interval: 200
                running: isPlaying && parsedLyricsData.length > 0
                repeat: true
                onTriggered: {
                    var pos = Number(player.position || 0);
                    if (pos > 100000) pos /= 1000000.0;
                    updateActiveLyric(pos);
                }
            }

            // --- UI LAYOUT ---
            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // ==================== LEFT COLUMN: Cover & Controls ====================
                DashboardCard {
                    Layout.preferredWidth: 190
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        
                        Item { Layout.fillHeight: true }

                        // Album Cover Art
                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 130
                            Layout.preferredHeight: 130 

                            Rectangle {
                                id: coverMask
                                anchors.fill: parent
                                radius: 14 
                                visible: false 
                            }

                            Item {
                                anchors.fill: parent
                                layer.enabled: coverImage.status === Image.Ready && width > 0 && height > 0
                                layer.effect: OpacityMask {
                                    maskSource: coverMask
                                }

                                Image {
                                    id: coverImage
                                    anchors.fill: parent
                                    source: coverUrl
                                    fillMode: Image.PreserveAspectCrop
                                    mipmap: true 
                                    smooth: true
                                    cache: true
                                    visible: false 
                                }

                                FastBlur {
                                    anchors.fill: parent
                                    source: coverImage
                                    radius: 20
                                    visible: coverImage.status === Image.Ready
                                }
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "\uf001" 
                                color: Theme.surfaceText
                                font.pixelSize: 42
                                visible: coverImage.status !== Image.Ready
                            }
                        }

                        // Playback controls
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12
                            
                            // Previous button
                            Rectangle {
                                width: 36; height: 36; radius: 18; 
                                color: prevHover.hovered ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.15) : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.05)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Text { anchors.centerIn: parent; text: "\uf048"; font.pixelSize: 12; color: Theme.surfaceText }
                                
                                HoverHandler { id: prevHover }
                                TapHandler { onTapped: if(typeof player.previous === "function") player.previous() }
                            }
                            
                            // Play/Pause button
                            Rectangle {
                                width: 54; height: 40; radius: 20; 
                                color: playHover.hovered ? Theme.secondary : Theme.primary
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Text { anchors.centerIn: parent; text: isPlaying ? "\uf04c" : "\uf04b"; font.pixelSize: 16; color: Theme.primaryText }
                                
                                HoverHandler { id: playHover }
                                TapHandler { onTapped: if(typeof player.togglePlaying === "function") player.togglePlaying() }
                            }
                            
                            // Next button
                            Rectangle {
                                width: 36; height: 36; radius: 18; 
                                color: nextHover.hovered ? Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.15) : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.05)
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                Text { anchors.centerIn: parent; text: "\uf051"; font.pixelSize: 12; color: Theme.surfaceText }
                                
                                HoverHandler { id: nextHover }
                                TapHandler { onTapped: if(typeof player.next === "function") player.next() }
                            }
                        }

                        Item { Layout.fillHeight: true }
                    }
                }

                // ==================== RIGHT COLUMN: Metadata & Lyrics ====================
                DashboardCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 24
                        spacing: 8

                        // --- TRACK INFO ---
                        Text {
                            Layout.fillWidth: true
                            text: trackName
                            color: Theme.primary
                            font.pixelSize: 24 
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: artistName
                            color: Theme.secondary
                            font.pixelSize: 16
                            elide: Text.ElideRight
                        }

                        Item { Layout.preferredHeight: 16 }

                        // --- LYRICS ---
                        Text {
                            Layout.fillWidth: true
                            text: previousLyricLine
                            color: Theme.surfaceText
                            opacity: 0.45
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: activeLyricLine
                            color: Theme.surfaceText
                            font.pixelSize: 16
                            font.bold: true
                            elide: Text.ElideRight

                            Behavior on text {
                                SequentialAnimation {
                                    NumberAnimation { target: parent; property: "opacity"; to: 0.4; duration: 80 }
                                    PropertyAction {}
                                    NumberAnimation { target: parent; property: "opacity"; to: 1.0; duration: 120 }
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: nextLyricLine
                            color: Theme.surfaceText
                            opacity: 0.45
                            font.pixelSize: 13
                            elide: Text.ElideRight
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}