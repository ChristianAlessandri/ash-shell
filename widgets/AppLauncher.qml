import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import "../core"

PanelWindow {
    id: launcherPanel

    anchors {
        bottom: true
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 28

    mask: Region { item: dockItem }
    
    focusable: isExpanded 

    property bool isExpanded: hoverHandler.hovered
    
    // --- DIMENSIONS ---
    property real visualWidth: isExpanded ? 600 : 200
    property real visualHeight: isExpanded ? 500 : 40

    property real shadowPaddingBottom: 4
    property real shadowPaddingTop: 550

    implicitWidth: parent.width
    implicitHeight: visualHeight + shadowPaddingTop + shadowPaddingBottom
    
    color: "transparent"

    Behavior on visualWidth { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
    Behavior on visualHeight { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

    property var allApps: []
    property string osIcon: "\uf17c"
    property string hostName: "PC"

    onIsExpandedChanged: {
        if (isExpanded) {
            launcherPanel.requestActivate();
            searchInput.forceActiveFocus();
        } else {
            searchInput.text = "";
        }
    }

    // --- SYSTEM INFO FETCHER (OS & Hostname) ---
    Process {
        id: sysInfoFetcher
        running: true
        command: ["bash", "-c", "source /etc/os-release 2>/dev/null; echo \"${ID:-linux}|$(hostname)\""]
        stdout: SplitParser {
            onRead: (line) => {
                var parts = line.split("|");
                var os = parts[0].toLowerCase();
                launcherPanel.hostName = parts[1];

                if (os.includes("arch")) launcherPanel.osIcon = "\uf303";
                else if (os.includes("manjaro")) launcherPanel.osIcon = "\uf312";
                else if (os.includes("endeavour")) launcherPanel.osIcon = "\uf32d";
                else if (os.includes("ubuntu")) launcherPanel.osIcon = "\uf3df";
                else if (os.includes("mint")) launcherPanel.osIcon = "\uf30e";
                else if (os.includes("pop")) launcherPanel.osIcon = "\uf32c";
                else if (os.includes("debian")) launcherPanel.osIcon = "\uf77d";
                else if (os.includes("fedora")) launcherPanel.osIcon = "\uf798";
                else if (os.includes("centos")) launcherPanel.osIcon = "\uf304";
                else if (os.includes("redhat") || os.includes("rhel")) launcherPanel.osIcon = "\uf316";
                else if (os.includes("suse")) launcherPanel.osIcon = "\uf7d6";
                else if (os.includes("nixos")) launcherPanel.osIcon = "\uf313";
                else if (os.includes("gentoo")) launcherPanel.osIcon = "\uf30d";
                else if (os.includes("alpine")) launcherPanel.osIcon = "\uf300";
                else if (os.includes("void")) launcherPanel.osIcon = "\uf32e";
                else if (os.includes("elementary")) launcherPanel.osIcon = "\uf309";
                else if (os.includes("mageia")) launcherPanel.osIcon = "\uf310";
                else if (os.includes("slackware")) launcherPanel.osIcon = "\uf318";
                else if (os.includes("devuan")) launcherPanel.osIcon = "\uf307";
                else if (os.includes("raspbian") || os.includes("raspberry")) launcherPanel.osIcon = "\uf315";
                else if (os.includes("freebsd")) launcherPanel.osIcon = "\uf30c";
                else launcherPanel.osIcon = "\uf17c";
            }
        }
    }

    // --- EXECUTION PROCESS ---
    Process { id: execProc }

    function launchApp(execCmd) {
        execProc.command = ["bash", "-c", "setsid " + execCmd + " >/dev/null 2>&1 &"];
        execProc.running = true;
        searchInput.text = "";
    }

    // --- APP SEARCH LOGIC ---
    function loadApps(jsonString) {
        try {
            allApps = JSON.parse(jsonString);
            filterApps("");
        } catch(e) {
            console.log("Error parsing apps JSON: " + e);
        }
    }

    function filterApps(query) {
        appModel.clear();
        var q = query.toLowerCase().trim();
        for (var i = 0; i < allApps.length; i++) {
            if (allApps[i].name.toLowerCase().includes(q)) {
                appModel.append(allApps[i]);
            }
        }
    }

    // --- APP FETCHER (Python) ---
    Process {
        id: appFetcher
        running: true
        command: ["python3", "-c", `
import os, json
apps = []
dirs = ['/usr/share/applications', os.path.expanduser('~/.local/share/applications')]
for d in dirs:
    if not os.path.exists(d): continue
    for root, _, files in os.walk(d):
        for f in files:
            if f.endswith('.desktop'):
                try:
                    with open(os.path.join(root, f), 'r', encoding='utf-8') as file:
                        name = exec_cmd = nodisplay = icon = None
                        for line in file:
                            if line.startswith('Name=') and not name: name = line[5:].strip()
                            elif line.startswith('Exec=') and not exec_cmd: exec_cmd = line[5:].split(' %')[0].strip()
                            elif line.startswith('NoDisplay='): nodisplay = line[10:].strip().lower()
                            elif line.startswith('Icon=') and not icon: icon = line[5:].strip()
                        if nodisplay == 'true': continue
                        if name and exec_cmd: apps.append({'name': name, 'exec': exec_cmd, 'icon': icon if icon else ""})
                except: pass
apps.sort(key=lambda x: x['name'].lower())
print(json.dumps(apps))
        `]
        stdout: SplitParser {
            onRead: (line) => {
                launcherPanel.loadApps(line);
            }
        }
    }

    // --- UI LAYERS ---
    Item {
        id: dockItem
        width: launcherPanel.visualWidth
        height: launcherPanel.visualHeight
        
        anchors.bottom: parent.bottom
        anchors.bottomMargin: launcherPanel.shadowPaddingBottom
        anchors.horizontalCenter: parent.horizontalCenter

        // ELEVATION SHADOW LAYER
        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            radius: menuBackground.radius
            
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                color: Qt.rgba(0, 0, 0, 0.4) 
                radius: 15     
                samples: 31    
                verticalOffset: 4
                horizontalOffset: 0
            }
        }

        // MAIN CONTENT LAYER
        Rectangle {
            id: menuBackground
            anchors.fill: parent
            color: Theme.surface
            
            radius: launcherPanel.isExpanded ? 24 : launcherPanel.visualHeight / 2
            border.color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
            border.width: 1
            clip: true

            Behavior on radius { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

            HoverHandler { id: hoverHandler }

            // --- COMPACT STATE (Pillola Orizzontale) ---
            Item {
                anchors.fill: parent
                opacity: launcherPanel.isExpanded ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                RowLayout {
                    anchors.centerIn: parent
                    spacing: 12
                    
                    Text {
                        text: launcherPanel.osIcon
                        color: Theme.primary
                        font.pixelSize: 18
                    }
                    
                    Text {
                        text: launcherPanel.hostName
                        color: Theme.surfaceText
                        font.pixelSize: 15
                        font.bold: true
                    }
                }
            }

            // --- EXPANDED STATE ---
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16
                
                opacity: launcherPanel.isExpanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }

                TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.preferredHeight: 50
                    placeholderText: "Search applications..."
                    font.pixelSize: 18
                    color: Theme.surfaceText
                    
                    background: Rectangle {
                        color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.05)
                        radius: 12
                        border.color: searchInput.activeFocus ? Theme.primary : "transparent"
                        border.width: 1
                        Behavior on border.color { ColorAnimation { duration: 150 } }
                    }

                    TapHandler {
                        onTapped: {
                            launcherPanel.requestActivate();
                            searchInput.forceActiveFocus();
                        }
                    }

                    onTextChanged: launcherPanel.filterApps(text)
                    
                    Keys.onReturnPressed: {
                        if (appModel.count > 0) {
                            launcherPanel.launchApp(appModel.get(0).exec);
                        }
                    }
                }

                ListView {
                    id: appList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    model: ListModel { id: appModel }
                    
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 50
                        radius: 12
                        color: delegateHover.hovered ? Theme.primary : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 16

                            Image {
                                Layout.preferredWidth: 24
                                Layout.preferredHeight: 24
                                sourceSize: Qt.size(24, 24)
                                fillMode: Image.PreserveAspectFit
                                source: model.icon.startsWith("/") ? "file://" + model.icon : "image://icon/" + model.icon

                                Text {
                                    anchors.centerIn: parent
                                    visible: parent.status !== Image.Ready
                                    text: "\uf009"
                                    font.pixelSize: 16
                                    color: delegateHover.hovered ? Theme.primaryText : Theme.secondary
                                }
                            }

                            Text {
                                text: model.name
                                font.pixelSize: 16
                                font.bold: true
                                color: delegateHover.hovered ? Theme.primaryText : Theme.surfaceText
                                Layout.fillWidth: true
                            }
                        }

                        HoverHandler { id: delegateHover }
                        TapHandler { onTapped: launcherPanel.launchApp(model.exec) }
                    }
                }
            }
        }
    }
}