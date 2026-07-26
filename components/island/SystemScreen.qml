// components/island/SystemScreen.qml
import QtQuick
import QtQuick.Layouts
import "../../core"

Item {
    id: root
    
    // --- MOCK DATA PROPERTIES ---
    property real cpuUsage: 0.09
    property real gpuUsage: 0.23
    property real storageUsage: 0.04
    property real memoryUsage: 0.21
    property var networkHistory: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    // --- METRICS SIMULATOR ---
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.cpuUsage = Math.max(0.01, Math.min(1.0, root.cpuUsage + (Math.random() * 0.1 - 0.05)));
            root.gpuUsage = Math.max(0.01, Math.min(1.0, root.gpuUsage + (Math.random() * 0.1 - 0.05)));
            root.memoryUsage = Math.max(0.1, Math.min(1.0, root.memoryUsage + (Math.random() * 0.02 - 0.01)));
            
            var newHistory = root.networkHistory.slice(1);
            newHistory.push(Math.random());
            root.networkHistory = newHistory;
            
            networkCanvas.requestPaint();
            storageCanvas.requestPaint();
            memoryCanvas.requestPaint();
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
    // Sostituito GridLayout con Column + RowLayout per un controllo flexbox perfetto
    Column {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        anchors.topMargin: 16
        anchors.bottomMargin: 16
        spacing: 12

        // ==========================================
        // ROW 1: CPU & GPU (50% e 50%)
        // ==========================================
        RowLayout {
            width: parent.width
            height: 105
            spacing: 12

            // --- CPU ---
            DashboardCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1 // Peso uguale

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
                            Text { text: "AMD Ryzen 5 7600X"; color: Theme.primary; font.pixelSize: 10; opacity: 0.7; elide: Text.ElideRight; width: 120 }
                        }
                    }

                    Column {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        width: parent.width - 75 
                        spacing: 8
                        
                        Row {
                            spacing: 6
                            Text { text: "\uf2c9"; color: Theme.surfaceText; font.pixelSize: 13 }
                            Text { text: "71°C"; color: Theme.surfaceText; font.pixelSize: 13; font.bold: true }
                        }
                        
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

            // --- GPU ---
            DashboardCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1 // Peso uguale

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
                            Text { text: "NVIDIA RTX 4060"; color: Theme.primary; font.pixelSize: 10; opacity: 0.7; elide: Text.ElideRight; width: 120 }
                        }
                    }

                    Column {
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        width: parent.width - 75 
                        spacing: 8
                        
                        Row {
                            spacing: 6
                            Text { text: "\uf2c9"; color: Theme.surfaceText; font.pixelSize: 13 }
                            Text { text: "42°C"; color: Theme.surfaceText; font.pixelSize: 13; font.bold: true }
                        }
                        
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

        // ==========================================
        // ROW 2: Storage, Network, Memory
        // ==========================================
        RowLayout {
            width: parent.width
            height: parent.height - 105 - parent.spacing
            spacing: 12

            // --- STORAGE ---
            DashboardCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                // Aumentato il peso flex per dare più respiro al testo
                Layout.preferredWidth: 42 

                Item {
                    anchors.fill: parent
                    anchors.margins: 12

                    // Dimensioni esplicite (66x66) per evitare che si schiacci
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

                    // Colonna di testo con spaziature ridotte
                    Column {
                        anchors.left: storageChartArea.right
                        anchors.leftMargin: 10
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text { text: "Storage"; color: Theme.surfaceText; font.bold: true; font.pixelSize: 14; width: parent.width; elide: Text.ElideRight }
                        Text { text: "17.6 / 476.9 GiB"; color: Theme.primary; opacity: 0.7; font.pixelSize: 9; width: parent.width; elide: Text.ElideRight }
                        
                        Item { width: 1; height: 2 } // Piccolo spaziatore visivo
                        
                        Rectangle {
                            width: Math.min(parent.width, 60); height: 18
                            radius: 6
                            color: Qt.rgba(Theme.primary.r, Theme.primary.g, Theme.primary.b, 0.15)
                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                Text { text: "\uf0a0"; color: Theme.primary; font.pixelSize: 10 }
                                Text { text: "sda"; color: Theme.primary; font.pixelSize: 10 }
                            }
                        }
                    }
                }
            }

            // --- NETWORK ---
            DashboardCard {
                Layout.fillWidth: true
                Layout.fillHeight: true
                // Ridotto per cedere spazio agli altri due
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
                            Text { text: "575 KB/s"; color: Theme.surfaceText; font.bold: true; font.pixelSize: 10; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
                        }
                        Item {
                            width: parent.width; height: 14
                            Text { text: "\uf062 UL"; color: Theme.secondary; font.pixelSize: 10; anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter }
                            Text { text: "462 KB/s"; color: Theme.surfaceText; font.bold: true; font.pixelSize: 10; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter }
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

            // --- MEMORY ---
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

                    // Fissato esplicitamente il Canvas a 66x66 e messo fisicamente al centro
                    Canvas {
                        id: memoryCanvas
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: 2 // Lo scosta leggermente in basso rispetto al centro assoluto per bilanciare visivamente i testi
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
                        text: "7.4 / 30.4 GiB"
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