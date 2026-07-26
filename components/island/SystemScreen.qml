import QtQuick
import "../../core"

Item {
    Column {
        anchors.centerIn: parent
        spacing: 15
        
        Text {
            text: "System"
            color: Theme.primary 
            font.pixelSize: 22
            font.bold: true
            anchors.horizontalCenter: parent.horizontalCenter
        }
        
        Text {
            text: "Battery: 100%"
            color: Theme.secondary 
            font.pixelSize: 14
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}