import Quickshell
import QtQuick
import "../core"

PanelWindow {
    id: island
    
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: 20

    anchors { top: true }
    margins { top: 4 }

    property string timeString: "00:00"

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
        }

        // Compact state
        Text {
            anchors.centerIn: parent
            text: island.timeString 
            color: Theme.surfaceText
            font.pixelSize: 14
            font.bold: true
            
            opacity: island.isExpanded ? 0 : 1
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        // Expanded state
        Item {
            anchors.fill: parent
            anchors.margins: 20
            
            opacity: island.isExpanded ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }

            Column {
                anchors.centerIn: parent
                spacing: 15

                Text {
                    text: "NXT Shell"
                    color: Theme.primary 
                    font.pixelSize: 22
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }

                Text {
                    text: "Local time: " + island.timeString
                    color: Theme.secondary 
                    font.pixelSize: 14
                    horizontalAlignment: Text.AlignHCenter
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }
        }
    }
}