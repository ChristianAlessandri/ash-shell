import QtQuick
import "../../core"

Item {
    id: root
    property string timeString: "00:00"
    
    Text {
        anchors.centerIn: parent
        text: root.timeString 
        color: Theme.surfaceText
        font.pixelSize: 14
        font.bold: true
    }
}