import QtQuick
import "../core"

Rectangle {
    property int customRadius: 16
    
    color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.04)
    radius: customRadius
    border.color: Qt.rgba(Theme.surfaceText.r, Theme.surfaceText.g, Theme.surfaceText.b, 0.08)
    border.width: 1
    clip: true
}