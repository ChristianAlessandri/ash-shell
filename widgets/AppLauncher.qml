import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../core"

PanelWindow {
    id: launcherPanel

    anchors {
        bottom: true
    }

    exclusionMode: ExclusionMode.Ignore
    focusable: isExpanded 

    property bool isExpanded: hoverHandler.hovered
    property real visualWidth: isExpanded ? 600 : 300
    property real visualHeight: isExpanded ? 500 : 30

    implicitWidth: visualWidth
    implicitHeight: visualHeight
    color: "transparent"

    Behavior on visualWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
    Behavior on visualHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

    property var allApps: []

    onIsExpandedChanged: {
        if (isExpanded) {
            launcherPanel.requestActivate();
            searchInput.forceActiveFocus();
        } else {
            searchInput.text = "";
        }
    }

    Process { id: execProc }

    function launchApp(execCmd) {
        execProc.command = ["bash", "-c", "setsid " + execCmd + " >/dev/null 2>&1 &"];
        execProc.running = true;
        searchInput.text = "";
    }

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

    Item {
        width: launcherPanel.visualWidth
        height: launcherPanel.visualHeight
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter

        HoverHandler { id: hoverHandler }

        Rectangle {
            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            width: 300
            height: 30
            radius: 15
            color: Theme.primary
            opacity: 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: launcherPanel.isExpanded ? 12 : 0
            color: Theme.surface
            radius: 24
            border.color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
            border.width: 1
            opacity: launcherPanel.isExpanded ? 1 : 0
            clip: true

            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16
                visible: launcherPanel.isExpanded

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