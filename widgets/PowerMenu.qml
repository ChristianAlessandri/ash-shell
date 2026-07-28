import Quickshell
import QtQuick
import QtQuick.Layouts
import Quickshell.Io
import Qt5Compat.GraphicalEffects
import "../core"

PanelWindow {
    id: powerPanel
    
    anchors { 
        bottom: true 
        left: true
        right: true
    }

    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 28

    mask: Region { item: dockItem }

    property bool isExpanded: hoverHandler.hovered

    property real visualWidth: isExpanded ? 200 : 40
    property real visualHeight: isExpanded ? 300 : 40
    
    // Invisible paddings
    property real shadowPaddingBottom: 4
    property real shadowPaddingLeft: 4
    property real shadowPaddingTop: 260 // Extra space to allow the animation to expand upwards
    property real shadowPaddingRight: 160 // Extra space to allow the animation to expand to the right

    implicitWidth: visualWidth + shadowPaddingLeft + shadowPaddingRight
    implicitHeight: visualHeight + shadowPaddingTop + shadowPaddingBottom
    color: "transparent"

    Behavior on visualWidth { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
    Behavior on visualHeight { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

    // --- SYSTEM PROCESSES ---
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
    
    Process { id: procSuspend; command: ["systemctl", "suspend"] }
    Process { id: procReboot; command: ["systemctl", "reboot"] }
    Process { id: procPoweroff; command: ["systemctl", "poweroff"] }

    // --- UI LAYERS ---
    Item {
        id: dockItem
        width: powerPanel.visualWidth
        height: powerPanel.visualHeight
        anchors.bottom: parent.bottom
        anchors.bottomMargin: powerPanel.shadowPaddingBottom
        anchors.left: parent.left
        anchors.leftMargin: powerPanel.shadowPaddingLeft

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
            radius: powerPanel.isExpanded ? 16 : powerPanel.visualHeight / 2
            border.color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
            border.width: 1
            clip: true 

            Behavior on radius { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

            HoverHandler {
                id: hoverHandler
            }

            // COMPACT STATE
            Item {
                anchors.fill: parent
                opacity: powerPanel.isExpanded ? 0 : 1
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 200 } }

                Text {
                    text: "\uf011"
                    color: Theme.primary
                    font.pixelSize: 16
                    anchors.centerIn: parent
                }
            }

            // EXPANDED STATE
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 8
                
                opacity: powerPanel.isExpanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 350; easing.type: Easing.InOutQuad } }

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
                    color: btnHover.hovered ? Theme.primary : Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.05)
                    
                    Behavior on color { ColorAnimation { duration: 150 } }

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 12
                        Text { text: parent.parent.iconText; font.pixelSize: 16; color: btnHover.hovered ? Theme.primaryText : Theme.surfaceText }
                        Text { text: parent.parent.labelText; font.pixelSize: 14; font.bold: true; color: btnHover.hovered ? Theme.primaryText : Theme.surfaceText }
                    }
                    
                    HoverHandler { id: btnHover }
                    TapHandler {
                        onTapped: {
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