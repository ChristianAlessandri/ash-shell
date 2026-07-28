import Quickshell
import QtQuick
import Qt5Compat.GraphicalEffects
import "../core"
import "../components"
import "../components/island"
import "../services"

PanelWindow {
    id: island
    
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 16
    anchors { top: true }

    SystemMonitor {
        id: systemMonitorService
    }

    ThemeEngine {
        id: themeEngine
    }

    property string timeString: "00:00"
    property int currentScreen: 0
    readonly property int totalScreens: 3

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            var date = new Date()
            var h = date.getHours().toString().padStart(2, '0')
            var m = date.getMinutes().toString().padStart(2, '0')
            island.timeString = h + ":" + m
        }
    }

    property bool isExpanded: hoverHandler.hovered

    // --- DIMENSIONS & PADDING LOGIC ---
    property real visualWidth: isExpanded ? 600 : 80
    property real visualHeight: isExpanded ? 320 : 24
    
    property real shadowPaddingTop: 4
    property real shadowPaddingBottom: 30
    property real shadowPaddingSides: 24

    implicitWidth: visualWidth + (shadowPaddingSides * 2)
    implicitHeight: visualHeight + shadowPaddingTop + shadowPaddingBottom
    color: "transparent"

    Behavior on visualWidth { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
    Behavior on visualHeight { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

    // --- UI LAYERS ---
    Item {
        width: island.visualWidth
        height: island.visualHeight
        
        anchors.horizontalCenter: parent.horizontalCenter
        y: shadowPaddingTop

        // ELEVATION SHADOW LAYER
        Rectangle {
            anchors.fill: parent
            color: Theme.surface
            radius: islandBackground.radius
            
            layer.enabled: true
            layer.effect: DropShadow {
                transparentBorder: true
                color: Qt.rgba(0, 0, 0, 0.4) 
                radius: 20     
                samples: 41    
                verticalOffset: 6
                horizontalOffset: 0
            }
        }

        // MAIN ISLAND CONTENT LAYER
        Rectangle {
            id: islandBackground
            anchors.fill: parent
            color: Theme.surface
            radius: island.isExpanded ? 30 : island.visualHeight / 2
            clip: true 

            Behavior on radius { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

            HoverHandler {
                id: hoverHandler
            }

            MouseArea {
                anchors.fill: parent
                
                acceptedButtons: Qt.NoButton 
                hoverEnabled: false          
                
                onWheel: (wheel) => {
                    if (!island.isExpanded) return;
                    
                    if (wheel.angleDelta.y > 0) {
                        island.currentScreen = Math.max(0, island.currentScreen - 1)
                    } else if (wheel.angleDelta.y < 0) {
                        island.currentScreen = Math.min(island.totalScreens - 1, island.currentScreen + 1)
                    }
                }
            }

            CompactState {
                anchors.fill: parent
                timeString: island.timeString
                
                opacity: island.isExpanded ? 0 : 1
                Behavior on opacity { NumberAnimation { duration: 200 } }
            }

            ExpandedState {
                anchors.fill: parent
                
                currentScreen: island.currentScreen
                totalScreens: island.totalScreens
                timeString: island.timeString
                
                sysMonitor: systemMonitorService 
                
                onPageRequested: (index) => { island.currentScreen = index }
                
                opacity: island.isExpanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
            }
        }
    }
}