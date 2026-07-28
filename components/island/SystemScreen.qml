import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../core"
import "../../components"

Item {
    id: root
    
    property var sysMonitor 

    // --- REUSABLE COMPONENTS ---
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
            width: parent.width; height: 105; spacing: 12

            DashboardCard {
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1

                Item {
                    anchors.fill: parent; anchors.margins: 14
                    
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
                        anchors.bottom: parent.bottom; anchors.left: parent.left
                        width: parent.width - 75; spacing: 8
                        LinearProgressBar { width: parent.width; height: 6; value: sysMonitor.cpuUsage }
                    }

                    Rectangle {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: 54; height: 54; radius: 20; color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                        Column {
                            anchors.centerIn: parent; spacing: -2
                            Text { text: "Usage"; color: Theme.primary; opacity: 0.7; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: Math.round(sysMonitor.cpuUsage * 100) + "%"; color: Theme.primary; font.bold: true; font.pixelSize: 15; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                    }
                }
            }

            DashboardCard {
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 1
                Item {
                    anchors.fill: parent; anchors.margins: 14
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
                        anchors.bottom: parent.bottom; anchors.left: parent.left
                        width: parent.width - 75; spacing: 8
                        LinearProgressBar { width: parent.width; height: 6; value: sysMonitor.gpuUsage }
                    }
                    Rectangle {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        width: 54; height: 54; radius: 20; color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.12)
                        Column {
                            anchors.centerIn: parent; spacing: -2
                            Text { text: "Usage"; color: Theme.primary; opacity: 0.7; font.pixelSize: 10; anchors.horizontalCenter: parent.horizontalCenter }
                            Text { text: Math.round(sysMonitor.gpuUsage * 100) + "%"; color: Theme.primary; font.bold: true; font.pixelSize: 15; anchors.horizontalCenter: parent.horizontalCenter }
                        }
                    }
                }
            }
        }

        // ROW 2: Storage, Network, Memory
        RowLayout {
            width: parent.width; height: parent.height - 105 - parent.spacing; spacing: 12

            DashboardCard {
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 42 
                Item {
                    anchors.fill: parent; anchors.margins: 12
                    Item {
                        id: storageChartArea
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; width: 66; height: 66
                        Canvas {
                            id: storageCanvas
                            anchors.fill: parent
                            
                            Connections { target: sysMonitor; function onStorageUsageChanged() { storageCanvas.requestPaint() } }
                            
                            onPaint: {
                                var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                                var cx = width / 2; var cy = height / 2; var r = width / 2 - 6;
                                var startAngle = Math.PI * 0.75; var endAngle = Math.PI * 2.25;
                                
                                ctx.beginPath(); ctx.arc(cx, cy, r, startAngle, endAngle);
                                ctx.lineWidth = 6; ctx.lineCap = "round"; ctx.strokeStyle = Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.15); ctx.stroke();
                                
                                ctx.beginPath(); var progressAngle = startAngle + (endAngle - startAngle) * sysMonitor.storageUsage;
                                ctx.arc(cx, cy, r, startAngle, progressAngle); ctx.strokeStyle = Theme.primary; ctx.stroke();
                            }
                            Column {
                                anchors.centerIn: parent; spacing: -2
                                Text { text: "\uf0a0"; font.pixelSize: 12; color: Theme.surfaceText; anchors.horizontalCenter: parent.horizontalCenter }
                                Text { text: Math.round(sysMonitor.storageUsage * 100) + "%"; color: Theme.surfaceText; font.bold: true; font.pixelSize: 14; anchors.horizontalCenter: parent.horizontalCenter }
                            }
                        }
                    }
                    Column {
                        anchors.left: storageChartArea.right; anchors.leftMargin: 10; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                        Text { text: "Root"; color: Theme.surfaceText; font.bold: true; font.pixelSize: 14; width: parent.width; elide: Text.ElideRight }
                        Text { text: sysMonitor.storageText; color: Theme.primary; opacity: 0.7; font.pixelSize: 9; width: parent.width; elide: Text.ElideRight }
                    }
                }
            }

            DashboardCard {
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 33 
                Item {
                    anchors.fill: parent; anchors.margins: 12

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
                        anchors.bottom: parent.bottom; anchors.left: parent.left; anchors.right: parent.right; spacing: 2
                        Item {
                            width: parent.width; height: 14
                            Text { text: "\uf063 DL"; color: Theme.secondary; font.pixelSize: 10; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: sysMonitor.dlSpeed; color: Theme.surfaceText; font.bold: true; font.pixelSize: 10; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                        }
                        Item {
                            width: parent.width; height: 14
                            Text { text: "\uf062 UL"; color: Theme.secondary; font.pixelSize: 10; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: sysMonitor.ulSpeed; color: Theme.surfaceText; font.bold: true; font.pixelSize: 10; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                        }
                    }

                    Canvas {
                        id: networkCanvas
                        anchors.top: netHeader.bottom; anchors.bottom: netStats.top; anchors.left: parent.left; anchors.right: parent.right
                        anchors.topMargin: 8; anchors.bottomMargin: 8
                        
                        Connections { target: sysMonitor; function onNetworkHistoryChanged() { networkCanvas.requestPaint() } }

                        onPaint: {
                            var ctx = getContext("2d"); ctx.clearRect(0, 0, width, height);
                            if (sysMonitor.networkHistory.length === 0) return;
                            var step = width / (sysMonitor.networkHistory.length - 1);
                            
                            ctx.beginPath(); ctx.moveTo(0, height);
                            for (var i = 0; i < sysMonitor.networkHistory.length; i++) {
                                var y = height - (sysMonitor.networkHistory[i] * height * 0.85);
                                ctx.lineTo(i * step, y);
                            }
                            ctx.lineTo(width, height); ctx.closePath(); ctx.fillStyle = Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15); ctx.fill();

                            ctx.beginPath();
                            for (var j = 0; j < sysMonitor.networkHistory.length; j++) {
                                var yLine = height - (sysMonitor.networkHistory[j] * height * 0.85);
                                if (j === 0) ctx.moveTo(j * step, yLine);
                                else ctx.lineTo(j * step, yLine);
                            }
                            ctx.lineWidth = 2; ctx.strokeStyle = Theme.primary; ctx.lineJoin = "round"; ctx.stroke();
                        }
                    }
                }
            }

            DashboardCard {
                Layout.fillWidth: true; Layout.fillHeight: true; Layout.preferredWidth: 25
                Item {
                    anchors.fill: parent; anchors.margins: 12

                    Row {
                        id: memHeader
                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8
                        Text { text: "\uefc5"; color: Theme.surfaceText; font.pixelSize: 14 }
                        Text { text: "Memory"; color: Theme.surfaceText; font.bold: true; font.pixelSize: 14 }
                    }

                    CircularGauge {
                        id: memoryCanvas
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 2 
                        width: 66 
                        height: 66
                        gaugeWidth: 6
                        value: sysMonitor.memoryUsage
                        showText: false
                    }
                    
                    Column {
                        anchors.centerIn: memoryCanvas
                        spacing: -2
                        Text { text: Math.round(sysMonitor.memoryUsage * 100) + "%"; color: Theme.surfaceText; font.bold: true; font.pixelSize: 14; anchors.horizontalCenter: parent.horizontalCenter }
                        Text { text: "Used"; color: Theme.secondary; font.pixelSize: 9; anchors.horizontalCenter: parent.horizontalCenter }
                    }

                    Text {
                        id: memSub
                        text: sysMonitor.memText
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