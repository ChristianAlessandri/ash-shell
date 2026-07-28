import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../core"

PanelWindow {
    id: powerPanel

    anchors {
        bottom: true
        left: true
    }

    exclusionMode: ExclusionMode.Ignore

    property bool isExpanded: hoverHandler.hovered
    
    property real visualWidth: isExpanded ? 200 : 60
    property real visualHeight: isExpanded ? 300 : 60

    implicitWidth: visualWidth
    implicitHeight: visualHeight
    
    color: "transparent"

    Behavior on visualWidth { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
    Behavior on visualHeight { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }

    // --- SYSTEM PROCESSES ---
    // Specific logout commands for different desktop environments
    Process { 
        id: procLogout 
        command: [
            "bash", 
            "-c", 
            `case "$XDG_CURRENT_DESKTOP" in
                *Hyprland*) hyprctl dispatch exit ;;
                *Sway*|*sway*) swaymsg exit ;;
                *GNOME*) gnome-session-quit --logout --no-prompt ;;
                *KDE*) qdbus org.kde.ksmserver /KSMServer logout 0 0 0 ;;
                *) loginctl terminate-user $USER ;;
            esac`
        ] 
    }
    
    // Standard systemctl commands for suspend, reboot, and poweroff
    Process { id: procSuspend; command: ["systemctl", "suspend"] }
    Process { id: procReboot; command: ["systemctl", "reboot"] }
    Process { id: procPoweroff; command: ["systemctl", "poweroff"] }

    // Main container
    Item {
        width: powerPanel.visualWidth
        height: powerPanel.visualHeight
        
        HoverHandler {
            id: hoverHandler
        }
        
        // --- INVISIBLE INDICATOR ---
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            width: 60
            height: 60
            color: Theme.primary 
            opacity: powerPanel.isExpanded ? 0 : 0 
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        // --- Expanded Menu ---
        Rectangle {
            anchors.fill: parent
            anchors.margins: powerPanel.isExpanded ? 12 : 0
            color: Theme.surface
            radius: 16
            border.color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
            border.width: 1
            opacity: powerPanel.isExpanded ? 1 : 0
            clip: true
            
            Behavior on opacity { NumberAnimation { duration: 300; easing.type: Easing.OutExpo } }
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8
                visible: powerPanel.isExpanded

                Text {
                    text: "\uf011  Power"
                    color: Theme.primary
                    font.pixelSize: 16
                    font.bold: true
                    Layout.alignment: Qt.AlignHCenter
                    Layout.bottomMargin: 8
                }

                component PowerButton: Rectangle {
                    property string iconText: ""
                    property string labelText: ""
                    property var targetProcess: null
                    
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 12
                    color: btnMouse.containsMouse ? Theme.primary : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.05)
                    
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 12
                        Text { text: parent.parent.iconText; font.pixelSize: 16; color: btnMouse.containsMouse ? Theme.primaryText : Theme.surfaceText }
                        Text { text: parent.parent.labelText; font.pixelSize: 14; font.bold: true; color: btnMouse.containsMouse ? Theme.primaryText : Theme.surfaceText }
                    }
                    
                    MouseArea {
                        id: btnMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (parent.targetProcess) {
                                parent.targetProcess.running = true;
                            }
                        }
                    }
                }

                PowerButton {
                    iconText: "\uf2f5" 
                    labelText: "Log Out"
                    targetProcess: procLogout
                }
                PowerButton {
                    iconText: "\uf186" 
                    labelText: "Suspend"
                    targetProcess: procSuspend
                }
                PowerButton {
                    iconText: "\uf021" 
                    labelText: "Restart"
                    targetProcess: procReboot
                }
                PowerButton {
                    iconText: "\uf011" 
                    labelText: "Shut Down"
                    targetProcess: procPoweroff
                }
            }
        }
    }
}