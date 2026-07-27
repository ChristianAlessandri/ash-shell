import QtQuick
import "../../core"

Item {
    id: root
    
    property int currentScreen: 0
    property int totalScreens: 3
    property string timeString: "00:00"
    
    property var sysMonitor
    
    // Signal to request a page change when a pagination dot is clicked
    signal pageRequested(int index)

    // Container that slides horizontally to reveal different screens
    Item {
        id: screenContainer
        width: parent.width * root.totalScreens
        anchors.top: parent.top
        anchors.bottom: indicatorRow.top
        anchors.margins: 10
        
        // Horizontal offset based on the active screen index
        x: -root.currentScreen * root.width
        Behavior on x { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }

        OverviewScreen {
            width: root.width
            height: parent.height
            x: 0
            timeString: root.timeString
            
            sysMonitor: root.sysMonitor
        }

        MediaScreen {
            width: root.width
            height: parent.height
            x: root.width
        }

        SystemScreen {
            width: root.width
            height: parent.height
            x: root.width * 2
            
            sysMonitor: root.sysMonitor
        }
    }

    // Pagination Dots Indicator
    Row {
        id: indicatorRow
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 8

        Repeater {
            model: root.totalScreens
            
            Rectangle {
                width: 8
                height: 8
                radius: 4
                color: root.currentScreen === index ? Theme.primary : Theme.secondary
                opacity: root.currentScreen === index ? 1.0 : 0.4
                
                Behavior on color { ColorAnimation { duration: 200 } }
                Behavior on opacity { NumberAnimation { duration: 200 } }

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6 // Expand hit area for easier clicking
                    onClicked: root.pageRequested(index)
                }
            }
        }
    }
}