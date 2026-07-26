import QtQuick
import "../../core"

Item {
    Column {
        anchors.centerIn: parent
        spacing: 15
        
        Text {
            text: "Media"
            color: Theme.primary 
            font.pixelSize: 22
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Text {
            text: "No media playing"
            color: Theme.secondary 
            font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}