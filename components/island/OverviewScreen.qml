import QtQuick
import "../../core"

Item {
    id: root
    property string timeString: "00:00"

    Column {
        anchors.centerIn: parent
        spacing: 15
        
        Text {
            text: "Overview"
            color: Theme.primary 
            font.pixelSize: 22
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Text {
            text: "Local Time: " + root.timeString
            color: Theme.secondary 
            font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}