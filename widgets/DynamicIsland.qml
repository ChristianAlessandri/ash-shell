import Quickshell
import QtQuick
import "../core"
import "../components/island"

PanelWindow {
    id: island
    
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 20

    anchors { top: true }
    margins { top: 4 }

    property string timeString: "00:00"
    
    // State management for pagination
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

    implicitWidth: isExpanded ? 400 : 80
    implicitHeight: isExpanded ? 160 : 24
    color: "transparent"

    Behavior on implicitWidth { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }
    Behavior on implicitHeight { NumberAnimation { duration: 350; easing.type: Easing.OutExpo } }

    Rectangle {
        anchors.fill: parent
        color: Theme.surface
        radius: island.isExpanded ? 30 : island.implicitHeight / 2
        border.color: Theme.primary
        border.width: 1
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
            
            // Sync state with the main window
            currentScreen: island.currentScreen
            totalScreens: island.totalScreens
            timeString: island.timeString
            
            // Listen to child's dot click events to update the main state
            onPageRequested: (index) => { island.currentScreen = index }
            
            opacity: island.isExpanded ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
        }
    }
}