# ASH Shell (Another SHell)

A highly interactive, responsive, and aesthetically pleasing "Dynamic Island" widget for Linux desktops, built with **Qt 6**, **QML**, and **Quickshell**. It features a compact default state that expands on hover to reveal a multi-screen dashboard with system metrics, media controls, and weather information.

## 🌟 Features

- **Fluid Animations & Responsive Design:** Built heavily on `RowLayout` and `ColumnLayout` for a Flexbox-like, fluid UI that scales beautifully.
- **Three Swipeable/Scrollable Screens:**
  - **Overview:** Displays time, interactive calendar, current weather (via `wttr.in`), user info, system uptime, and mini hardware gauges.
  - **Media Player:** Full MPRIS integration with playback controls, blurred album art backgrounds, and **real-time synchronized lyrics** fetched automatically via `lrclib.net`.
  - **System Monitor:** Advanced, live-updating metrics including CPU, GPU, RAM, Storage, and a live Network traffic history graph.
- **Chameleon Theme Engine (Zero Dependencies):** Automatically extracts the dominant color from your current wallpaper and dynamically generates a cohesive UI color palette (Primary, Secondary, and Surface colors). No external tools like `pywal` required!
- **Efficient Resource Usage:** Centralized bash processing ensures hardware metrics are only polled once globally, keeping CPU and RAM footprints minimal.

## 🛠 Prerequisites

- [Quickshell](https://quickshell.org//) installed and configured on your system.
- Qt 6 (specifically `qt6-declarative`, `qt6-5compat` for GraphicalEffects).
- Standard Linux utilities (`bash`, `awk`, `df`, etc.).
- An active internet connection (for weather and lyrics).

## 🚀 Installation

1. Clone this repository into your Quickshell configuration directory (usually `~/.config/quickshell/`).
2. Start or reload Quickshell.

---

## 🎨 Theming & Wallpaper Detection

The built-in `ThemeEngine` uses an invisible 1x1 QML Canvas to mathematically calculate the average color of your wallpaper. It natively supports **GNOME**, **KDE Plasma**, **swww** (Hyprland), and **hyprpaper** out of the box.

### Setting up Auto-Theming on Hyprland (or unsupported WMs)

If you are using a custom Wayland shell (like `caelestia-shell`), `swaybg`, `wbg`, or any other wallpaper utility that doesn't broadcast its current image to the system, the Theme Engine might not know what your wallpaper is.

To fix this, we've implemented a **Universal Symlink Method**. You just need to tell the widget where your wallpaper is located by creating a symbolic link in your `~/.config` folder.

**Tutorial:**
Whenever you set a new wallpaper, simply run this command in your terminal (replace `/path/to/your/image.jpg` with your actual wallpaper file):

```bash
ln -sf /path/to/your/image.jpg ~/.config/wallpaper
```

**How it works:**
The widget continuously checks `~/.config/wallpaper`. As soon as you update this symlink, the `ThemeEngine` will detect the change, load the new image into its background canvas, extract the dominant RGB values, and seamlessly transition your Dynamic Island's colors to match your new setup—all within 5 seconds!

## 📜 License

AGPL v3 License. See [LICENSE](LICENSE) for more information.
