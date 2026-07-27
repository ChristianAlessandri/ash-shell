import QtQuick
import Quickshell
import Quickshell.Io
import "../../core"

Item {
    id: root
    visible: false 
    
    property string currentWallpaperPath: ""

    onCurrentWallpaperPathChanged: {
        var url = currentWallpaperPath.trim();
        
        // Sanity check: ignore error paths
        if (url !== "" && !url.toLowerCase().startsWith("error")) {
            if (!url.startsWith("file://") && !url.startsWith("http")) {
                url = "file://" + url;
            }
            colorCanvas.loadImage(url);
        }
    }

    Process {
        id: wallpaperFinder
        running: true
        command: ["bash", "-c", `
            while true; do
                # 1. Symlink
                if [ -f "$HOME/.config/wallpaper" ]; then
                    readlink -f "$HOME/.config/wallpaper"
                
                # 2. Hyprland support: SWWW
                elif command -v swww >/dev/null 2>&1 && swww query >/dev/null 2>&1; then
                    swww query | grep "image:" | head -n 1 | sed 's/.*image: //'
                
                # 3. Hyprland support: Hyprpaper
                elif command -v hyprctl >/dev/null 2>&1; then
                    # Ignore any errors from hyprctl and only takes the first valid path
                    hyprctl hyprpaper listloaded 2>/dev/null | grep "^/" | head -n 1
                
                # 4. GNOME / GTK
                elif command -v gsettings >/dev/null 2>&1 && [ -n "$(gsettings get org.gnome.desktop.background picture-uri 2>/dev/null)" ]; then
                    URI=$(gsettings get org.gnome.desktop.background picture-uri-dark 2>/dev/null || gsettings get org.gnome.desktop.background picture-uri)
                    echo "$URI" | sed -e "s/'//g" -e "s/^file:\/\///g"
                
                # 5. KDE Plasma
                elif [ -f "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" ]; then
                    grep 'Image=' "$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc" | tail -n 1 | cut -d '=' -f 2 | sed -e "s/^file:\/\///g"
                fi
                sleep 5
            done
        `]
        stdout: SplitParser {
            onRead: (line) => {
                var cleanLine = line.trim();
                // Clean up quotes if present (e.g., 'path/to/wallpaper' -> path/to/wallpaper)
                cleanLine = cleanLine.replace(/^["'](.*)["']$/, '$1'); 
                
                // Update the currentWallpaperPath only if it's different from the last known path
                if (cleanLine.startsWith("/") && root.currentWallpaperPath !== cleanLine) {
                    root.currentWallpaperPath = cleanLine;
                }
            }
        }
    }

    Canvas {
        id: colorCanvas
        width: 1
        height: 1
        opacity: 0 

        property string loadedUrl: ""

        onImageLoaded: {
            var url = currentWallpaperPath.trim();
            if (!url.startsWith("file://") && !url.startsWith("http")) {
                url = "file://" + url;
            }
            loadedUrl = url;
            requestPaint();
        }

        onPaint: {
            if (loadedUrl === "") return;
            
            var ctx = getContext("2d");
            ctx.reset();
            
            try {
                ctx.drawImage(loadedUrl, 0, 0, 1, 1);
                var data = ctx.getImageData(0, 0, 1, 1).data;
                
                Theme.setPalette(data[0], data[1], data[2]);
            } catch(e) {
            }
        }
    }
}