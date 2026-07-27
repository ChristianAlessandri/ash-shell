import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import Qt5Compat.GraphicalEffects
import "../../core"

Item {
    id: root
    property string timeString: "00:00"

    // --- SYSTEM DATA PROPERTIES ---
    property string uptimeText: "up 0 minutes"
    property string userInfo: "user@linux"
    
    property real cpuUsage: 0.0
    property real memoryUsage: 0.0
    property real storageUsage: 0.0
    
    property real lastCpuTotal: 0
    property real lastCpuIdle: 0

    // --- WEATHER PROPERTIES ---
    property string weatherTemp: "--°C"
    property string weatherDesc: "..."
    property string weatherIcon: "\uf185"

    // --- CONTINUOUS METRICS & INFO PROCESS ---
    Process {
        id: sysInfoProcess
        running: true
        command: [
            "bash",
            "-c",
            `while true; do
                USER_INFO="$(whoami)@$(hostname)"
                UPTIME="up $(awk '{print int($1/60)}' /proc/uptime) minutes"
                CPU=$(head -n 1 /proc/stat)
                MEM=$(awk '/^MemTotal/ {t=$2} /^MemAvailable/ {a=$2} END {print t, a}' /proc/meminfo)
                DISK=$(df / | awk 'NR==2 {print $3, $2}')
                
                echo "$USER_INFO|$UPTIME|$CPU|$MEM|$DISK"
                sleep 1
            done`
        ]
        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.split('|');
                if(parts.length !== 5) return;

                // 1. User & Uptime
                root.userInfo = parts[0];
                root.uptimeText = parts[1];

                // 2. CPU Usage
                var cpuRaw = parts[2].trim().split(/\s+/);
                var user = parseInt(cpuRaw[1]);
                var nice = parseInt(cpuRaw[2]);
                var system = parseInt(cpuRaw[3]);
                var idle = parseInt(cpuRaw[4]);
                var iowait = parseInt(cpuRaw[5]);
                var irq = parseInt(cpuRaw[6]);
                var softirq = parseInt(cpuRaw[7]);

                var currentIdle = idle + iowait;
                var currentNonIdle = user + nice + system + irq + softirq;
                var currentTotal = currentIdle + currentNonIdle;

                if (root.lastCpuTotal !== 0) {
                    var totalDiff = currentTotal - root.lastCpuTotal;
                    var idleDiff = currentIdle - root.lastCpuIdle;
                    if (totalDiff > 0) {
                        root.cpuUsage = (totalDiff - idleDiff) / totalDiff;
                    }
                }
                root.lastCpuTotal = currentTotal;
                root.lastCpuIdle = currentIdle;

                // 3. Memory Usage
                var memRaw = parts[3].split(' ');
                var memTotal = parseInt(memRaw[0]); 
                var memAvail = parseInt(memRaw[1]); 
                root.memoryUsage = (memTotal - memAvail) / memTotal;

                // 4. Storage Usage
                var diskRaw = parts[4].split(' ');
                var diskUsed = parseInt(diskRaw[0]); 
                var diskTotal = parseInt(diskRaw[1]);
                root.storageUsage = diskUsed / diskTotal;
            }
        }
    }

    // --- CALENDAR LOGIC ---
    property int currentMonth: new Date().getMonth()
    property int currentYear: new Date().getFullYear()
    property var calendarDays: []
    property var monthNames: ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]

    function updateCalendar() {
        var days = [];
        var firstDay = new Date(currentYear, currentMonth, 1);
        var lastDay = new Date(currentYear, currentMonth + 1, 0);
        
        var startingDayOfWeek = firstDay.getDay(); 
        var emptyDays = startingDayOfWeek === 0 ? 6 : startingDayOfWeek - 1; 
        
        var prevMonthLastDay = new Date(currentYear, currentMonth, 0).getDate();
        
        for (var i = emptyDays - 1; i >= 0; i--) {
            days.push({ day: prevMonthLastDay - i, isCurrentMonth: false, isToday: false });
        }
        
        var today = new Date();
        for (var j = 1; j <= lastDay.getDate(); j++) {
            var isToday = (j === today.getDate() && currentMonth === today.getMonth() && currentYear === today.getFullYear());
            days.push({ day: j, isCurrentMonth: true, isToday: isToday });
        }
        
        var remaining = 35 - days.length;
        if (remaining < 0) remaining = 42 - days.length; 
        
        for (var k = 1; k <= remaining; k++) {
            days.push({ day: k, isCurrentMonth: false, isToday: false });
        }
        
        calendarDays = days;
    }

    Component.onCompleted: updateCalendar()

    // --- WEATHER FETCH LOGIC ---
    Timer {
        interval: 1800000 // Update every 30 minutes
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var xhr = new XMLHttpRequest();
            // wttr.in detects location automatically based on IP
            xhr.open("GET", "https://wttr.in/?format=j1", true);
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                    try {
                        var response = JSON.parse(xhr.responseText);
                        var current = response.current_condition[0];
                        
                        root.weatherTemp = current.temp_C + "°C";
                        root.weatherDesc = current.weatherDesc[0].value;
                        
                        var lowerDesc = root.weatherDesc.toLowerCase();
                        if (lowerDesc.includes("rain") || lowerDesc.includes("drizzle") || lowerDesc.includes("shower")) {
                            root.weatherIcon = "\uf740"; // Rain
                        } else if (lowerDesc.includes("snow") || lowerDesc.includes("ice")) {
                            root.weatherIcon = "\uf2dc"; // Snow
                        } else if (lowerDesc.includes("thunder") || lowerDesc.includes("storm")) {
                            root.weatherIcon = "\uf0e7"; // Thunder
                        } else if (lowerDesc.includes("cloud") || lowerDesc.includes("overcast")) {
                            root.weatherIcon = "\uf0c2"; // Cloudy
                        } else {
                            root.weatherIcon = "\uf185"; // Sunny/Clear
                        }
                    } catch(e) {
                        console.log("Error parsing weather:", e);
                    }
                }
            }
            xhr.send();
        }
    }

    // --- REUSABLE COMPONENTS ---
    component DashboardCard : Rectangle {
        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.04)
        radius: 16
        border.color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
        border.width: 1
        clip: true 
    }

    component MiniRingGauge : Item {
        property real value: 0.0
        property string icon: ""
        
        width: 32; height: 32 
        
        onValueChanged: canvas.requestPaint()
        
        Canvas {
            id: canvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                var cx = width / 2;
                var cy = height / 2;
                var r = width / 2 - 4;
                
                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, Math.PI * 2);
                ctx.lineWidth = 4;
                ctx.strokeStyle = Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.1);
                ctx.stroke();
                
                ctx.beginPath();
                ctx.arc(cx, cy, r, -Math.PI/2, -Math.PI/2 + (Math.PI * 2 * parent.value));
                ctx.strokeStyle = Theme.primary;
                ctx.lineCap = "round";
                ctx.stroke();
            }
        }
        
        Text {
            anchors.centerIn: parent
            text: parent.icon
            color: Theme.surfaceText
            font.pixelSize: 11
        }
    }

    // --- UI LAYOUT ---
    RowLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        // ==========================================
        // BLOCK 1: DASHBOARD
        // ==========================================
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 65 
            spacing: 12

            // --- ROW 1 ---
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 35
                spacing: 12

                DashboardCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 40

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        
                        Text { 
                            text: root.weatherIcon
                            font.pixelSize: 32
                            color: Theme.surfaceText
                            Layout.alignment: Qt.AlignVCenter 
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 2
                            
                            Text { 
                                text: root.weatherTemp
                                font.pixelSize: 22
                                font.bold: true
                                color: Theme.surfaceText
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                            Text { 
                                text: root.weatherDesc
                                font.pixelSize: 12
                                color: Theme.secondary
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }
                        }
                    }
                }

                DashboardCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredWidth: 60

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12
                        
                        Rectangle {
                            Layout.preferredWidth: 42; Layout.preferredHeight: 42
                            radius: 21
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                            Text { anchors.centerIn: parent; text: "\uf007"; font.pixelSize: 18; color: Theme.primary }
                        }
                        
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 4
                            
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Text { text: "\uf120"; font.pixelSize: 12; color: Theme.secondary }
                                Text { text: root.userInfo; font.pixelSize: 12; font.bold: true; color: Theme.surfaceText; Layout.fillWidth: true; elide: Text.ElideRight }
                            }
                            
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6
                                Rectangle { width: 20; height: 20; radius: 10; color: Qt.rgba(Theme.secondary.r, Theme.secondary.g, Theme.secondary.b, 0.2); Text { anchors.centerIn: parent; text: "\uf017"; font.pixelSize: 10; color: Theme.secondary } }
                                Text { text: root.uptimeText; font.pixelSize: 11; color: Theme.surfaceText; opacity: 0.8; Layout.fillWidth: true; elide: Text.ElideRight }
                            }
                        }
                    }
                }
            }

            // --- ROW 2 ---
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredHeight: 65
                spacing: 12

                // Watch
                DashboardCard {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 70
                    Layout.maximumWidth: 70

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 0
                        
                        Item { Layout.fillHeight: true }
                        Text { text: root.timeString.split(":")[0]; font.pixelSize: 32; font.bold: true; color: Theme.primary; Layout.alignment: Qt.AlignHCenter }
                        Text { text: "•••"; font.pixelSize: 16; color: Theme.secondary; opacity: 0.5; Layout.alignment: Qt.AlignHCenter }
                        Text { text: root.timeString.split(":")[1]; font.pixelSize: 32; font.bold: true; color: Theme.surfaceText; Layout.alignment: Qt.AlignHCenter }
                        Item { Layout.fillHeight: true }
                    }
                }

                // Calendar
                DashboardCard {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 4

                        // Header
                        RowLayout {
                            Layout.fillWidth: true
                            
                            Item {
                                Layout.preferredWidth: 24; Layout.preferredHeight: 24
                                Text { anchors.centerIn: parent; text: "\uf053"; font.pixelSize: 10; color: Theme.surfaceText; opacity: 0.5 }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (root.currentMonth === 0) { root.currentMonth = 11; root.currentYear--; }
                                        else { root.currentMonth--; }
                                        root.updateCalendar();
                                    }
                                }
                            }
                            
                            Text { 
                                text: root.monthNames[root.currentMonth] + " " + root.currentYear
                                font.pixelSize: 13; font.bold: true; color: Theme.primary
                                Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter 
                            }
                            
                            Item {
                                Layout.preferredWidth: 24; Layout.preferredHeight: 24
                                Text { anchors.centerIn: parent; text: "\uf054"; font.pixelSize: 10; color: Theme.surfaceText; opacity: 0.5 }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        if (root.currentMonth === 11) { root.currentMonth = 0; root.currentYear++; }
                                        else { root.currentMonth++; }
                                        root.updateCalendar();
                                    }
                                }
                            }
                        }

                        // Days
                        RowLayout {
                            Layout.fillWidth: true
                            Repeater {
                                model: ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
                                Text { text: modelData; font.pixelSize: 10; color: Theme.surfaceText; font.bold: true; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
                            }
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            columns: 7
                            rowSpacing: 2
                            columnSpacing: 2
                            
                            Repeater {
                                model: root.calendarDays
                                delegate: Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    
                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: Math.min(parent.width, 24)
                                        height: width
                                        color: modelData.isToday ? Theme.primary : "transparent"
                                        radius: width / 2
                                        
                                        Text {
                                            anchors.centerIn: parent
                                            text: modelData.day
                                            font.pixelSize: 11
                                            color: modelData.isToday ? Theme.primaryText : Theme.surfaceText
                                            opacity: modelData.isCurrentMonth ? (modelData.isToday ? 1.0 : 0.7) : 0.3
                                            font.bold: modelData.isToday
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // System Gauges
                DashboardCard {
                    Layout.fillHeight: true
                    Layout.preferredWidth: 50
                    Layout.maximumWidth: 50
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 8
                        
                        Item { Layout.fillHeight: true }
                        MiniRingGauge { Layout.alignment: Qt.AlignHCenter; value: root.cpuUsage; icon: "\uf2db" } 
                        MiniRingGauge { Layout.alignment: Qt.AlignHCenter; value: root.memoryUsage; icon: "" }   
                        MiniRingGauge { Layout.alignment: Qt.AlignHCenter; value: root.storageUsage; icon: "\uf0a0" } 
                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }

        // ==========================================
        // BLOCK 2: MEDIA PLAYER
        // ==========================================
        DashboardCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 35 

            Column {
                anchors.centerIn: parent
                spacing: 10
                visible: playerRepeater.count === 0
                
                Rectangle {
                    width: 100; height: 100
                    radius: 24
                    color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.1)
                    anchors.horizontalCenter: parent.horizontalCenter
                    Text { anchors.centerIn: parent; text: "\uf001"; font.pixelSize: 32; color: Theme.primary; opacity: 0.5 }
                }
                
                Text {
                    text: "No Media"
                    color: Theme.primary 
                    font.pixelSize: 16
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            Repeater {
                id: playerRepeater
                model: Mpris.players

                delegate: Item {
                    anchors.fill: parent
                    anchors.margins: 16
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
                        return stateString === "playing" || stateString === "1";
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 12

                        // Blurred Cover Art
                        Item {
                            Layout.alignment: Qt.AlignHCenter
                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 100

                            Rectangle {
                                id: coverMask
                                anchors.fill: parent
                                radius: 24 
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
                                font.pixelSize: 48
                                visible: coverImage.status !== Image.Ready
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 4
                            
                            Text { 
                                text: trackName
                                color: Theme.primary
                                font.pixelSize: 16
                                font.bold: true
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }
                            Text { 
                                text: artistName
                                color: Theme.surfaceText
                                opacity: 0.7
                                font.pixelSize: 12
                                Layout.fillWidth: true
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                            }
                        }

                        Item { Layout.fillHeight: true } 

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 16
                            
                            Rectangle {
                                width: 36; height: 36; radius: 18; color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.05)
                                Text { anchors.centerIn: parent; text: "\uf048"; font.pixelSize: 12; color: Theme.surfaceText }
                                MouseArea { anchors.fill: parent; onClicked: if(typeof player.previous === "function") player.previous() }
                            }
                            
                            Rectangle {
                                width: 54; height: 40; radius: 20; color: Theme.primary
                                Text { anchors.centerIn: parent; text: isPlaying ? "\uf04c" : "\uf04b"; font.pixelSize: 16; color: Theme.primaryText }
                                MouseArea { anchors.fill: parent; onClicked: if(typeof player.togglePlaying === "function") player.togglePlaying() }
                            }
                            
                            Rectangle {
                                width: 36; height: 36; radius: 18; color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.05)
                                Text { anchors.centerIn: parent; text: "\uf051"; font.pixelSize: 12; color: Theme.surfaceText }
                                MouseArea { anchors.fill: parent; onClicked: if(typeof player.next === "function") player.next() }
                            }
                        }
                    }
                }
            }
        }
    }
}