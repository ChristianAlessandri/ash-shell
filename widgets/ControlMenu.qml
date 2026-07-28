import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../core"

PanelWindow {
    id: controlPanel

    anchors {
        right: true
    }

    exclusionMode: ExclusionMode.Ignore

    property bool isExpanded: hoverHandler.hovered
    
    property real visualWidth: isExpanded ? 140 : 20
    property real visualHeight: isExpanded ? 240 : 160

    implicitWidth: visualWidth
    implicitHeight: visualHeight
    
    color: "transparent"

    Behavior on visualWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
    Behavior on visualHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

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

    // --- FETCHING PROCESSES ---
    Process {
        id: briFetcher
        running: true
        command: ["bash", "-c", `
            while true; do
                if [ "$(ls -A /sys/class/backlight 2>/dev/null)" ]; then
                    # Notebook
                    brightnessctl -c backlight -m 2>/dev/null | awk -F, '{print $4}' | tr -d '%'
                    sleep 1
                elif command -v ddcutil &>/dev/null; then
                    # External monitor
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

    // --- CUSTOM COMPONENT ---
    component CustomVerticalSlider: Item {
        id: sliderRoot
        
        property real value: 0.5
        property color activeColor: Theme.primary
        property string icon: ""
        
        readonly property bool isDragging: mouseArea.pressed

        signal userChangedValue(real newValue)

        Layout.fillHeight: true
        Layout.fillWidth: true

        ColumnLayout {
            anchors.fill: parent
            spacing: 16

            Text {
                text: sliderRoot.icon
                color: sliderRoot.isDragging ? sliderRoot.activeColor : Theme.surfaceText
                font.pixelSize: 18
                Layout.alignment: Qt.AlignHCenter
                Behavior on color { ColorAnimation { duration: 150 } }
            }

            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: 32
                Layout.alignment: Qt.AlignHCenter

                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)

                    Rectangle {
                        width: parent.width
                        height: Math.max(16, parent.height * sliderRoot.value)
                        anchors.bottom: parent.bottom
                        radius: 16
                        color: sliderRoot.activeColor
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    
                    onPositionChanged: (mouse) => updateValue(mouse.y)
                    onClicked: (mouse) => updateValue(mouse.y)
                    
                    function updateValue(mouseY) {
                        var val = 1.0 - (mouseY / height);
                        val = Math.max(0.0, Math.min(1.0, val));
                        sliderRoot.value = val;
                        sliderRoot.userChangedValue(val);
                    }
                }
            }
        }
    }

    // --- MAIN CONTAINER ---
    Item {
        width: controlPanel.visualWidth
        height: controlPanel.visualHeight
        
        HoverHandler { id: hoverHandler }

        Rectangle {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 20
            height: 160
            radius: 10
            color: Theme.primary 
            opacity: 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        Rectangle {
            anchors.fill: parent
            anchors.margins: controlPanel.isExpanded ? 12 : 0
            color: Theme.surface
            radius: 16
            border.color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
            border.width: 1
            opacity: controlPanel.isExpanded ? 1 : 0
            clip: true
            
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
            
            RowLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 24
                visible: controlPanel.isExpanded

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