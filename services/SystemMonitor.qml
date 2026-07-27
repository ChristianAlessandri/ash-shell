// services/SystemMonitor.qml
import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // Expose properties to the parent component
    property string userInfo: "user@linux"
    property string uptimeText: "up 0 minutes"
    property real cpuUsage: 0.0
    property real memoryUsage: 0.0
    property real storageUsage: 0.0
    property real gpuUsage: 0.0
    
    property string memText: "0.0 / 0.0 GiB"
    property string storageText: "0.0 / 0.0 GiB"
    property string dlSpeed: "0 KB/s"
    property string ulSpeed: "0 KB/s"
    property var networkHistory: []

    // Internal properties to track previous values for calculations
    property real lastCpuTotal: 0
    property real lastCpuIdle: 0
    property real lastRx: -1
    property real lastTx: -1

    function formatBytes(bytes) {
        if (bytes < 1024) return bytes + " B";
        else if (bytes < 1048576) return (bytes / 1024).toFixed(0) + " KB";
        else return (bytes / 1048576).toFixed(1) + " MB";
    }

    Process {
        id: combinedMetricsProcess
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
                NET=$(sed 's/://g' /proc/net/dev | awk 'NR>2 {rx+=$2; tx+=$10} END {print rx, tx}')
                GPU=$(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || echo 0)
                
                echo "$USER_INFO|$UPTIME|$CPU|$MEM|$DISK|$NET|$GPU"
                sleep 1
            done`
        ]

        stdout: SplitParser {
            onRead: (output) => {
                var parts = output.trim().split('|');
                if (parts.length !== 7) return;

                root.userInfo = parts[0];
                root.uptimeText = parts[1];

                // CPU Parsing
                var cpuRaw = parts[2].trim().split(/\s+/);
                var idle = parseInt(cpuRaw[4]);
                var iowait = parseInt(cpuRaw[5]);
                var currentIdle = idle + iowait;
                var currentNonIdle = parseInt(cpuRaw[1]) + parseInt(cpuRaw[2]) + parseInt(cpuRaw[3]) + parseInt(cpuRaw[6]) + parseInt(cpuRaw[7]);
                var currentTotal = currentIdle + currentNonIdle;

                if (root.lastCpuTotal !== 0) {
                    var totalDiff = currentTotal - root.lastCpuTotal;
                    if (totalDiff > 0) root.cpuUsage = (totalDiff - (currentIdle - root.lastCpuIdle)) / totalDiff;
                }
                root.lastCpuTotal = currentTotal;
                root.lastCpuIdle = currentIdle;

                // Memory Parsing
                var memRaw = parts[3].split(' ');
                var memTotal = parseInt(memRaw[0]); 
                var memUsed = memTotal - parseInt(memRaw[1]);
                root.memoryUsage = memUsed / memTotal;
                root.memText = (memUsed / 1048576).toFixed(1) + " / " + (memTotal / 1048576).toFixed(1) + " GiB";

                // Storage Parsing
                var diskRaw = parts[4].split(' ');
                var diskTotal = parseInt(diskRaw[1]);
                root.storageUsage = parseInt(diskRaw[0]) / diskTotal;
                root.storageText = (parseInt(diskRaw[0]) / 1048576).toFixed(1) + " / " + (diskTotal / 1048576).toFixed(1) + " GiB";

                // Network Parsing
                var netRaw = parts[5].split(' ');
                var rx = parseInt(netRaw[0]);
                var tx = parseInt(netRaw[1]);
                if (root.lastRx !== -1) {
                    root.dlSpeed = formatBytes(rx - root.lastRx);
                    root.ulSpeed = formatBytes(tx - root.lastTx);
                    var normalizedNet = Math.min(1.0, (rx - root.lastRx) / 15728640);
                    
                    var newHistory = root.networkHistory.length >= 15 ? root.networkHistory.slice(1) : root.networkHistory;
                    newHistory.push(normalizedNet);
                    root.networkHistory = newHistory;
                }
                root.lastRx = rx;
                root.lastTx = tx;

                // GPU Parsing
                var gpuParsed = parseInt(parts[6]);
                if (!isNaN(gpuParsed)) root.gpuUsage = gpuParsed / 100.0;
            }
        }
    }
}