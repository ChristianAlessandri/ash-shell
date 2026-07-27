import QtQuick
import "../core"

Item {
    property real value: 0.0
    property string iconText: ""
    property real gaugeWidth: 4
    property bool showText: true
    
    onValueChanged: canvas.requestPaint()
    
    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.clearRect(0, 0, width, height);
            var cx = width / 2;
            var cy = height / 2;
            var r = (width / 2) - gaugeWidth;
            
            // Background arc
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.lineWidth = parent.gaugeWidth;
            ctx.strokeStyle = Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.15);
            ctx.stroke();
            
            // Foreground arc
            ctx.beginPath();
            var startAngle = -Math.PI / 2;
            ctx.arc(cx, cy, r, startAngle, startAngle + (Math.PI * 2 * parent.value));
            ctx.strokeStyle = Theme.primary;
            ctx.lineCap = "round";
            ctx.stroke();
        }
    }
    
    Text {
        visible: parent.showText
        anchors.centerIn: parent
        text: parent.iconText
        color: Theme.surfaceText
        font.pixelSize: parent.width > 40 ? 14 : 11
        font.bold: parent.width > 40
    }
}