pragma Singleton
import QtQuick

QtObject {
    // --- DEFAULT COLORS ---
    property color surface: "#0c0a09"
    property color surfaceText: "#fbfaf9" 
    property color primary: "#be123c"
    property color primaryText: "#fbfaf9" 
    property color secondary: "#be185d" 
    property color secondaryText: "#fbfaf9"
    property color success: "#047857"
    property color warning: "#b45309"
    property color errorColor: "#b91c1c"

    // --- PALETTE UPDATE LOGIC ---
    function setPalette(r, g, b) {
        if (r === 0 && g === 0 && b === 0) { r = 33; g = 33; b = 33; } // Avoid pure black
        
        var hsl = rgbToHsl(r, g, b);
        var h = hsl[0];
        var s = hsl[1];
        var l = hsl[2];

        if (s < 0.2) s = 0.5;
        var primaryL = Math.max(0.5, Math.min(0.7, l));
        
        primary = hslToHex(h, s, primaryL);
        var secondaryH = (h + (30 / 360)) % 1.0;
        secondary = hslToHex(secondaryH, s, primaryL - 0.1);
        surface = hslToHex(h, 0.15, 0.08);
    }

    // --- UTILITIES JS ---
    function rgbToHsl(r, g, b) {
        r /= 255; g /= 255; b /= 255;
        var max = Math.max(r, g, b), min = Math.min(r, g, b);
        var h, s, l = (max + min) / 2;
        if (max === min) { h = s = 0; } 
        else {
            var d = max - min;
            s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
            switch (max) {
                case r: h = (g - b) / d + (g < b ? 6 : 0); break;
                case g: h = (b - r) / d + 2; break;
                case b: h = (r - g) / d + 4; break;
            }
            h /= 6;
        }
        return [h, s, l];
    }

    function hslToHex(h, s, l) {
        var r, g, b;
        if (s === 0) { r = g = b = l; } 
        else {
            var hue2rgb = function(p, q, t) {
                if (t < 0) t += 1; if (t > 1) t -= 1;
                if (t < 1/6) return p + (q - p) * 6 * t;
                if (t < 1/2) return q;
                if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
                return p;
            };
            var q = l < 0.5 ? l * (1 + s) : l + s - l * s;
            var p = 2 * l - q;
            r = hue2rgb(p, q, h + 1/3); g = hue2rgb(p, q, h); b = hue2rgb(p, q, h - 1/3);
        }
        var toHex = function(x) {
            var hex = Math.round(x * 255).toString(16);
            return hex.length === 1 ? "0" + hex : hex;
        };
        return "#" + toHex(r) + toHex(g) + toHex(b);
    }
}