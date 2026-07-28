import QtQuick
import QtQuick.Layouts
import "../core"

Item {
    id: sliderRoot
    
    property real value: 0.5
    property color activeColor: Theme.primary
    property string icon: ""
    
    readonly property bool isDragging: mouseArea.pressed

    signal userChangedValue(real newValue)

    Layout.fillHeight: true
    Layout.fillWidth: true

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        Text {
            text: sliderRoot.icon
            color: sliderRoot.isDragging ? sliderRoot.activeColor : Theme.surfaceText
            font.pixelSize: 18
            Layout.alignment: Qt.AlignHCenter
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Item {
            Layout.fillHeight: true
            Layout.preferredWidth: 32
            Layout.alignment: Qt.AlignHCenter

            Rectangle {
                anchors.fill: parent
                radius: 16
                color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)

                Rectangle {
                    width: parent.width
                    height: Math.max(16, parent.height * sliderRoot.value)
                    anchors.bottom: parent.bottom
                    radius: 16
                    color: sliderRoot.activeColor
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                
                onPositionChanged: (mouse) => updateValue(mouse.y)
                onClicked: (mouse) => updateValue(mouse.y)
                
                function updateValue(mouseY) {
                    var val = 1.0 - (mouseY / height);
                    val = Math.max(0.0, Math.min(1.0, val));
                    sliderRoot.value = val;
                    sliderRoot.userChangedValue(val);
                }
            }
        }
    }
}