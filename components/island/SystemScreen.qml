import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../core"

Item {
    id: root
    
    // --- METRICS STATE PROPERTIES ---
    property real cpuUsage: 0.0
    property real gpuUsage: 0.0
    property real storageUsage: 0.0
    property real memoryUsage: 0.0
    
    property string memText: "0.0 / 0.0 GiB"
    property string storageText: "0.0 / 0.0 GiB"
    property string dlSpeed: "0 KB/s"
    property string ulSpeed: "0 KB/s"
    
    property var networkHistory: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    property real lastCpuTotal: 0
    property real lastCpuIdle: 0
    property real lastRx: -1
    property real lastTx: -1

    function formatBytes(bytes) {
        if (bytes < 1024) return bytes + " B";
        else if (bytes < 1048576) return (bytes / 1024).toFixed(0) + " KB";
        else return (bytes / 1048576).toFixed(1) + " MB";
    }

    // --- CONTINUOUS METRICS PROCESS ---
    Process {
        id: metricsProcess
        running: true
        command: [
            "bash",
            "-c",
            `while true; do
                CPU=$(head -n 1 /proc/stat)
                MEM=$(awk '/^MemTotal/ {t=$2} /^MemAvailable/ {a=$2} END {print t, a}' /proc/meminfo)
                DISK=$(df / | awk 'NR==2 {print $3, $2}')
                NET=$(sed 's/://g' /proc/net/dev | awk 'NR>2 {rx+=$2; tx+=$10} END {print rx, tx}')
                GPU=$(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || echo 0)
                
                echo "$CPU|$MEM|$DISK|$NET|$GPU"
                sleep 1
            done`
        ]

        stdout: SplitParser {
            onRead: (output) => {
                var parts = output.trim().split('|');
                if (parts.length !== 5) return;

                // --- CPU PARSING ---
                var cpuRaw = parts[0].trim().split(/\s+/);
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

                // --- MEMORY PARSING ---
                var memRaw = parts[1].split(' ');
                var memTotal = parseInt(memRaw[0]); 
                var memAvail = parseInt(memRaw[1]); 
                var memUsed = memTotal - memAvail;
                root.memoryUsage = memUsed / memTotal;
                root.memText = (memUsed / 1048576).toFixed(1) + " / " + (memTotal / 1048576).toFixed(1) + " GiB";

                // --- STORAGE PARSING ---
                var diskRaw = parts[2].split(' ');
                var diskUsed = parseInt(diskRaw[0]); 
                var diskTotal = parseInt(diskRaw[1]);
                root.storageUsage = diskUsed / diskTotal;
                root.storageText = (diskUsed / 1048576).toFixed(1) + " / " + (diskTotal / 1048576).toFixed(1) + " GiB";

                // --- NETWORK PARSING ---
                var netRaw = parts[3].split(' ');
                var rx = parseInt(netRaw[0]);
                var tx = parseInt(netRaw[1]);

                if (root.lastRx !== -1) {
                    var rxDiff = rx - root.lastRx;
                    var txDiff = tx - root.lastTx;
                    
                    root.dlSpeed = formatBytes(rxDiff);
                    root.ulSpeed = formatBytes(txDiff);

                    var maxSpeed = 15728640; 
                    var normalizedNet = Math.min(1.0, rxDiff / maxSpeed);
                    var newHistory = root.networkHistory.slice(1);
                    newHistory.push(normalizedNet);
                    root.networkHistory = newHistory;
                    
                    networkCanvas.requestPaint();
                }
                root.lastRx = rx;
                root.lastTx = tx;

                // --- GPU PARSING ---
                var gpuParsed = parseInt(parts[4]);
                if (!isNaN(gpuParsed)) {
                    root.gpuUsage = gpuParsed / 100.0;
                }

                storageCanvas.requestPaint();
                memoryCanvas.requestPaint();
            }
        }
    }

    // --- REUSABLE COMPONENTS ---
    component DashboardCard : Rectangle {
        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.04)
        radius: 12
        border.color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
        border.width: 1
    }

    component LinearProgressBar : Item {
        property real value: 0.0 
        
        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.15)
            
            Rectangle {
                width: parent.width * parent.parent.value
                height: parent.height
                radius: height / 2
                color: Theme.primary
                
                Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
            }
        }
    }

    // --- UI LAYOUT ---
    Column {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        spacing: 12

        // ROW 1: CPU & GPU
        RowLayout {
            width: parent.width
            height: 105
            spacing: 12

            DashboardCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1

                Item {
                    anchors.fill: parent
                    anchors.margins: 14
                    
                    Row {
                        id: cpuHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        spacing: 10
                        
                        Text { text: "\uf2db"; color: Theme.primary; font.pixelSize: 22; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: "CPU"; color: Theme.surfaceText; font.bold: true; font.pixelSize: 15 }
                            Text { text: "System"; color: Theme.primary; font.pixelSize: 10; opacity: 0.7; elide: Text.ElideRight; width: 120 }
                        }
                    }

                    Column {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        width: parent.width - 75 
                        spacing: 8
                        
                        LinearProgressBar {
                            width: parent.width; height: 6
                            value: root.cpuUsage
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 54; height: 54
                        radius: 20
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: -2
                            Text { text: "Usage"; color: Theme.primary; opacity: 0.7; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: Math.round(root.cpuUsage * 100) + "%"; color: Theme.primary; font.bold: true; font.pixelSize: 15; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                    }
                }
            }

            DashboardCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1

                Item {
                    anchors.fill: parent
                    anchors.margins: 14
                    
                    Row {
                        id: gpuHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        spacing: 10
                        
                        Text { text: "\uf108"; color: Theme.primary; font.pixelSize: 22; anchors.verticalCenter: parent.verticalCenter }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: "GPU"; color: Theme.surfaceText; font.bold: true; font.pixelSize: 15 }
                            Text { text: "Graphics"; color: Theme.primary; font.pixelSize: 10; opacity: 0.7; elide: Text.ElideRight; width: 120 }
                        }
                    }

                    Column {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        width: parent.width - 75 
                        spacing: 8
                        
                        LinearProgressBar {
                            width: parent.width; height: 6
                            value: root.gpuUsage
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        width: 54; height: 54
                        radius: 20
                        color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: -2
                            Text { text: "Usage"; color: Theme.primary; opacity: 0.7; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: Math.round(root.gpuUsage * 100) + "%"; color: Theme.primary; font.bold: true; font.pixelSize: 15; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                    }
                }
            }
        }

        // ROW 2: Storage, Network, Memory
        RowLayout {
            width: parent.width
            height: parent.height - 105 - parent.spacing
            spacing: 12

            DashboardCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 42 

                Item {
                    anchors.fill: parent
                    anchors.margins: 12

                    Item {
                        id: storageChartArea
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: 66 
                        height: 66

                        Canvas {
                            id: storageCanvas
                            anchors.fill: parent
                            
                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                var cx = width / 2;
                                var cy = height / 2;
                                var r = width / 2 - 6;
                                var startAngle = Math.PI * 0.75;
                                var endAngle = Math.PI * 2.25;
                                
                                ctx.beginPath();
                                ctx.arc(cx, cy, r, startAngle, endAngle);
                                ctx.lineWidth = 6;
                                ctx.lineCap = "round";
                                ctx.strokeStyle = Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.15);
                                ctx.stroke();
                                
                                ctx.beginPath();
                                var progressAngle = startAngle + (endAngle - startAngle) * root.storageUsage;
                                ctx.arc(cx, cy, r, startAngle, progressAngle);
                                ctx.strokeStyle = Theme.primary;
                                ctx.stroke();
                            }
                            
                            Column {
                                anchors.centerIn: parent
                                spacing: -2
                                Text { text: "\uf0a0"; font.pixelSize: 12; color: Theme.surfaceText; anchors.horizontalCenter: parent.horizontalCenter }
                                Text { text: Math.round(root.storageUsage * 100) + "%"; color: Theme.surfaceText; font.bold: true; font.pixelSize: 14; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                        }
                    }

                    Column {
                        anchors.left: storageChartArea.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        Text { text: "Root"; color: Theme.surfaceText; font.bold: true; font.pixelSize: 14; width: parent.width; elide: Text.ElideRight }
                        Text { text: root.storageText; color: Theme.primary; opacity: 0.7; font.pixelSize: 9; width: parent.width; elide: Text.ElideRight }
                    }
                }
            }

            DashboardCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 33 

                Item {
                    anchors.fill: parent
                    anchors.margins: 12

                    Row {
                        id: netHeader
                        anchors.top: parent.top
                        anchors.left: parent.left
                        spacing: 8
                        Text { text: "\uf0ec"; color: Theme.surfaceText; font.pixelSize: 14 }
                        Text { text: "Network"; color: Theme.surfaceText; font.bold: true; font.pixelSize: 14 }
                    }

                    Column {
                        id: netStats
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 2

                        Item {
                            width: parent.width; height: 14
                            Text { text: "\uf063 DL"; color: Theme.secondary; font.pixelSize: 10; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: root.dlSpeed; color: Theme.surfaceText; font.bold: true; font.pixelSize: 10; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                        }
                        Item {
                            width: parent.width; height: 14
                            Text { text: "\uf062 UL"; color: Theme.secondary; font.pixelSize: 10; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: root.ulSpeed; color: Theme.surfaceText; font.bold: true; font.pixelSize: 10; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    Canvas {
                        id: networkCanvas
                        anchors.top: netHeader.bottom
                        anchors.bottom: netStats.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.topMargin: 8
                        anchors.bottomMargin: 8

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            if (root.networkHistory.length === 0) return;
                            var step = width / (root.networkHistory.length - 1);
                            
                            ctx.beginPath();
                            ctx.moveTo(0, height);
                            for (var i = 0; i < root.networkHistory.length; i++) {
                                var y = height - (root.networkHistory[i] * height * 0.85);
                                ctx.lineTo(i * step, y);
                            }
                            ctx.lineTo(width, height);
                            ctx.closePath();
                            ctx.fillStyle = Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15);
                            ctx.fill();

                            ctx.beginPath();
                            for (var j = 0; j < root.networkHistory.length; j++) {
                                var yLine = height - (root.networkHistory[j] * height * 0.85);
                                if (j === 0) ctx.moveTo(j * step, yLine);
                                else ctx.lineTo(j * step, yLine);
                            }
                            ctx.lineWidth = 2;
                            ctx.strokeStyle = Theme.primary;
                            ctx.lineJoin = "round";
                            ctx.stroke();
                        }
                    }
                }
            }

            DashboardCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 25

                Item {
                    anchors.fill: parent
                    anchors.margins: 12

                    Row {
                        id: memHeader
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        Text { text: ""; color: Theme.surfaceText; font.pixelSize: 14 }
                        Text { text: "Memory"; color: Theme.surfaceText; font.bold: true; font.pixelSize: 14 }
                    }

                    Canvas {
                        id: memoryCanvas
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 2 
                        width: 66 
                        height: 66
                        
                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            var cx = width / 2;
                            var cy = height / 2;
                            var r = width / 2 - 6;
                            
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, 0, Math.PI * 2);
                            ctx.lineWidth = 6;
                            ctx.strokeStyle = Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.15);
                            ctx.stroke();
                            
                            ctx.beginPath();
                            ctx.arc(cx, cy, r, -Math.PI/2, -Math.PI/2 + (Math.PI * 2 * root.memoryUsage));
                            ctx.strokeStyle = Theme.primary;
                            ctx.lineCap = "round";
                            ctx.stroke();
                        }
                        
                        Column {
                            anchors.centerIn: parent
                            spacing: -2
                            Text { text: Math.round(root.memoryUsage * 100) + "%"; color: Theme.surfaceText; font.bold: true; font.pixelSize: 14; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: "Used"; color: Theme.secondary; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                    }

                    Text {
                        id: memSub
                        text: root.memText
                        color: Theme.primary
                        opacity: 0.7
                        font.pixelSize: 9
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
        }
    }
}