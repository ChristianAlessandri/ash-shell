import QtQuick
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects
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
            
            property string trackName: player.title || (player.metadata && player.metadata["xesam:title"]) || "Unknown Track"
            property string coverUrl: player.artUrl || (player.metadata && player.metadata["mpris:artUrl"]) || ""
            
            property string artistName: {
                var metaArtist = player.metadata ? player.metadata["xesam:artist"] : null;
                if (!metaArtist) return player.artist ? String(player.artist) : "Unknown Artist";
                
                if (Array.isArray(metaArtist) || typeof metaArtist === "object") {
                    return metaArtist.length > 0 ? String(metaArtist[0]) : "Unknown Artist";
                }
                return String(metaArtist);
            }

            property bool isPlaying: {
                var stateString = String(player.playbackState).toLowerCase();
                var statusString = String(player.playbackStatus).toLowerCase();
                return stateString === "playing" || stateString === "1";
            }

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
            
            Component.onCompleted: {
                fetchLyrics();
            }

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

                var xhr = new XMLHttpRequest();
                var safeArtist = artistName.split(",")[0].trim();
                var url = "https://lrclib.net/api/get?track_name=" + encodeURIComponent(trackName) + "&artist_name=" + encodeURIComponent(safeArtist);
                
                xhr.open("GET", url, true);
                xhr.setRequestHeader("Content-Type", "application/json");
                
                xhr.onreadystatechange = function() {
                    if (xhr.readyState === XMLHttpRequest.DONE) {
                        if (xhr.status === 200) {
                            var response = JSON.parse(xhr.responseText);
                            if (response.syncedLyrics) {
                                parseLRC(response.syncedLyrics);
                                
                                updateActiveLyric(0);
                            } else {
                                activeLyricLine = "No synced lyrics available"; 
                            }
                        } else {
                            activeLyricLine = "Lyrics not found";
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

                    if (!match)
                        continue;

                    var text = match[3].trim();

                    if (text.length === 0)
                        continue;

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

                previousLyricLine =
                    current > 0
                        ? parsedLyricsData[current - 1].text
                        : "";

                activeLyricLine =
                    parsedLyricsData[current].text;

                nextLyricLine =
                    current < parsedLyricsData.length - 1
                        ? parsedLyricsData[current + 1].text
                        : "";
            }

            // --- LYRICS SYNCHRONIZATION TIMER ---
            Timer {
                interval: 200
                running: isPlaying && parsedLyricsData.length > 0
                repeat: true

                onTriggered: {
                    var pos = Number(player.position || 0);

                    // Compatibility: Some MPRIS implementations return position in microseconds, others in milliseconds. Normalize to seconds.
                    if (pos > 100000)
                        pos /= 1000000.0;

                    updateActiveLyric(pos);
                }
            }

            // --- UI LAYOUT ---
            Row {
                anchors.centerIn: parent
                width: parent.width * 0.9
                height: parent.height * 0.85
                spacing: 20

                // ==================== LEFT COLUMN: Cover & Controls ====================
                Column {
                    width: 110 // Fixed width to maintain consistent layout boundaries
                    height: parent.height
                    spacing: 12
                    
                    // Center the column content vertically relative to the right column
                    anchors.verticalCenter: parent.verticalCenter

                    // 1. Album Cover Art
                    Item {
                        width: 110
                        height: 110
                        anchors.horizontalCenter: parent.horizontalCenter

                        Rectangle {
                            id: coverMask
                            anchors.fill: parent
                            radius: 12
                            visible: false 
                        }

                        Image {
                            id: coverImage
                            anchors.fill: parent
                            source: coverUrl
                            fillMode: Image.PreserveAspectCrop
                            
                            mipmap: true 
                            smooth: true
                            
                            layer.enabled: coverImage.status === Image.Ready
                            layer.effect: OpacityMask {
                                maskSource: coverMask
                            }
                            
                            Text {
                                anchors.centerIn: parent
                                text: "🎵"
                                font.pixelSize: 32
                                visible: coverImage.status !== Image.Ready
                            }
                        }
                    }

                    // 2. Playback Controls
                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 18

                        Text {
                            text: "⏮"
                            color: prevArea.pressed ? Theme.primary : Theme.surfaceText
                            font.pixelSize: 20

                            MouseArea {
                                id: prevArea
                                anchors.fill: parent
                                anchors.margins: -10 // Expanded hit area for easier clicking
                                onClicked: if (typeof player.previous === "function") player.previous()
                            }
                        }

                        Text {
                            text: isPlaying ? "⏸" : "▶"
                            color: playArea.pressed ? Theme.primary : Theme.surfaceText
                            font.pixelSize: 20

                            MouseArea {
                                id: playArea
                                anchors.fill: parent
                                anchors.margins: -10
                                onClicked: {
                                    if (typeof player.togglePlaying === "function")
                                        player.togglePlaying()
                                }
                            }
                        }

                        Text {
                            text: "⏭"
                            color: nextArea.pressed ? Theme.primary : Theme.surfaceText
                            font.pixelSize: 20

                            MouseArea {
                                id: nextArea
                                anchors.fill: parent
                                anchors.margins: -10
                                onClicked: if (typeof player.next === "function") player.next()
                            }
                        }
                    }
                }

                // ==================== RIGHT COLUMN: Metadata & Lyrics ====================
                Column {
                    // Calculate remaining width dynamically (Total - LeftColumn - Spacing)
                    width: parent.width - 130 
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4 // Tighter spacing for text elements

                    // --- TRACK INFO ---
                    Text {
                        text: trackName
                        color: Theme.primary
                        font.pixelSize: 17
                        font.bold: true
                        width: parent.width
                        elide: Text.ElideRight
                    }

                    Text {
                        text: artistName
                        color: Theme.secondary
                        font.pixelSize: 13
                        width: parent.width
                        elide: Text.ElideRight
                    }

                    // Visual separator between metadata and lyrics
                    Item { width: 1; height: 10 } 

                    // --- LYRICS ---
                    Text {
                        text: previousLyricLine
                        color: Theme.secondary
                        opacity: 0.45
                        font.pixelSize: 12
                        width: parent.width
                        elide: Text.ElideRight
                    }

                    Text {
                        text: activeLyricLine
                        color: Theme.primary
                        font.pixelSize: 15
                        font.bold: true
                        width: parent.width
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
                        text: nextLyricLine
                        color: Theme.secondary
                        opacity: 0.45
                        font.pixelSize: 12
                        width: parent.width
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }
}