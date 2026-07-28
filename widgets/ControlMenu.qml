import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import "../core"
import "../components"

PanelWindow {
    id: controlPanel

    anchors {
        right: true
    }

    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 20

    mask: Region { item: dockItem }

    property bool isExpanded: hoverHandler.hovered
    
    // --- DIMENSIONS ---
    property real visualWidth: isExpanded ? 160 : 32
    property real visualHeight: isExpanded ? 240 : 100

    property real shadowPaddingTop: 4
    property real shadowPaddingBottom: 4
    property real shadowPaddingRight: 4
    property real shadowPaddingLeft: 160

    implicitWidth: visualWidth + shadowPaddingLeft + shadowPaddingRight
    implicitHeight: visualHeight + shadowPaddingTop + shadowPaddingBottom
    
    color: "transparent"

    Behavior on visualWidth { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
    Behavior on visualHeight { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

    // --- EXECUTION PROCESSES ---
    Process { id: setVolProc }
    Process { id: setBriProc }

    // --- FETCHING PROCESSES ---
    Process {
        id: volFetcher
        running: true
        command: ["bash", "-c", `
            while true; do
                wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print $2}'
                sleep 1
            done
        `]
        stdout: SplitParser {
            onRead: (line) => {
                if (!volSlider.isDragging) volSlider.value = parseFloat(line);
            }
        }
    }

    Process {
        id: briFetcher
        running: true
        command: ["bash", "-c", `
            while true; do
                if [ "$(ls -A /sys/class/backlight 2>/dev/null)" ]; then
                    brightnessctl -c backlight -m 2>/dev/null | awk -F, '{print $4}' | tr -d '%'
                    sleep 1
                elif command -v ddcutil &>/dev/null; then
                    ddcutil getvcp 10 2>/dev/null | grep -oP 'current value =\\s*\\K[0-9]+' || echo 50
                    sleep 5
                else
                    echo 100
                    sleep 60
                fi
            done
        `]
        stdout: SplitParser {
            onRead: (line) => {
                if (!briSlider.isDragging) briSlider.value = parseFloat(line) / 100.0;
            }
        }
    }

    // --- UI LAYERS ---
    Item {
        id: dockItem
        width: controlPanel.visualWidth
        height: controlPanel.visualHeight
        
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: controlPanel.shadowPaddingRight

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
            
            radius: controlPanel.isExpanded ? 16 : controlPanel.visualWidth / 2
            border.color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
            border.width: 1
            clip: true
            
            Behavior on radius { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

            HoverHandler {
                id: hoverHandler
            }

            // --- COMPACT STATE (Pillola Verticale) ---
            Item {
                anchors.fill: parent
                opacity: controlPanel.isExpanded ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Column {
                    anchors.centerIn: parent
                    spacing: 24

                    Text {
                        text: "\uf185"
                        color: Theme.primary
                        font.pixelSize: 16
                        anchors.horizontalCenter: parent.horizontalCenter
                    }

                    Text {
                        text: "\uf028"
                        color: Theme.secondary
                        font.pixelSize: 16
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }
            }
            
            // --- EXPANDED STATE (Sliders) ---
            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 24
                
                opacity: controlPanel.isExpanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }

                // Brightness slider
                CustomVerticalSlider {
                    id: briSlider
                    icon: "\uf185" 
                    activeColor: Theme.primary
                    
                    onUserChangedValue: (val) => {
                        var perc = Math.max(1, Math.round(val * 100));
                        var cmd = `if [ "$(ls -A /sys/class/backlight 2>/dev/null)" ]; then brightnessctl -c backlight set ${perc}%; elif command -v ddcutil &>/dev/null; then ddcutil setvcp 10 ${perc} --noverify; fi`
                        
                        setBriProc.command = ["bash", "-c", cmd];
                        setBriProc.running = true;
                    }
                }

                // Volume slider
                CustomVerticalSlider {
                    id: volSlider
                    icon: "\uf028" 
                    activeColor: Theme.secondary
                    
                    onUserChangedValue: (val) => {
                        var perc = Math.round(val * 100);
                        setVolProc.command = ["bash", "-c", "wpctl set-volume @DEFAULT_AUDIO_SINK@ " + perc + "%"];
                        setVolProc.running = true;
                    }
                }
            }
        }
    }
}