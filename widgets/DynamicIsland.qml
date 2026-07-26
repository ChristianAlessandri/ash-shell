// widgets/DynamicIsland.qml
import Quickshell
import QtQuick
import Qt5Compat.GraphicalEffects // Required for the DropShadow effect
import "../core"
import "../components/island"

PanelWindow {
    id: island
    
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 20

    anchors { top: true }

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

    property bool isExpanded: mouseArea.containsMouse

    // --- DIMENSIONS & PADDING LOGIC ---
    property real visualWidth: isExpanded ? 600 : 80
    property real visualHeight: isExpanded ? 200 : 24
    
    // Asymmetric padding: small gap at the top to stay close to the screen edge,
    // large gap at the bottom/sides to prevent the shadow from being clipped.
    property real shadowPaddingTop: 4
    property real shadowPaddingBottom: 30
    property real shadowPaddingSides: 24

    // The Wayland window size accounts for the uneven padding
    implicitWidth: visualWidth + (shadowPaddingSides * 2)
    implicitHeight: visualHeight + shadowPaddingTop + shadowPaddingBottom
    color: "transparent"

    Behavior on visualWidth { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
    Behavior on visualHeight { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

    // --- UI LAYERS ---
    Item {
        width: island.visualWidth
        height: island.visualHeight
        
        // Center horizontally, but explicitly position near the top instead of centering vertically
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

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true

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
                
                onPageRequested: (index) => { island.currentScreen = index }
                
                opacity: island.isExpanded ? 1 : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
            }
        }
    }
}