# Network info widget for KDE Plasma 6

A minimal, native network info widget for KDE Plasma 6 (tested on Fedora). It displays connection details directly on your desktop or panels, using system fonts and colors that match your active theme.

![Widget preview](https://raw.githubusercontent.com/username/org.fedora.networkwidget/main/preview.png)

## Features

- 🌐 **Interface detection:** Automatically displays the active interface name (WiFi, Ethernet, or VPN) and shows matching icons.
- 🏠 **Local IP address:** Displays your machine's current local network address.
- 🌍 **Public IP address:** Queries your external IP using multi-source fallbacks. Displays `Offline` if you're offline.
- 📋 **DNS servers:** Resolves active DNS server addresses from `systemd-resolved` or `NetworkManager` (`nmcli`).
- 🎨 **Minimal layout:**
  - Respects your light or dark theme and system typography.
  - **Floating text mode:** Right-click the widget and toggle off "Show Card Background" to remove borders, margins, and boxes. The text floats directly on your wallpaper.
  - Adds outlines to text in floating mode to keep it readable against any wallpaper.
- ⚡ **Auto and manual refresh:** Runs on a 60-second timer or updates when you click the widget.

## Requirements

- KDE Plasma 6.0+
- Python 3.x
- `NetworkManager` (`nmcli`) or `systemd-resolved` (`resolvectl`)

## Installation

### Manual installation
If you've got the `.plasmoid` package, install it using `kpackagetool6`:

```bash
kpackagetool6 --type Plasma/Applet --install org.fedora.networkwidget.plasmoid
```

### Installation from source (Git)
Clone the repository directly into your local Plasma widgets directory:

```bash
# Clone the repository
git clone https://github.com/KnowOneActual/org.fedora.networkwidget.git ~/.local/share/plasma/plasmoids/org.fedora.networkwidget

# Rebuild KDE configuration cache
kbuildsycoca6

# Restart the desktop shell
systemctl --user restart plasma-plasmashell
```

Once installed, right-click your desktop, select **Add Widgets...**, search for **"Network Info Widget"**, and drag it onto your desktop or panel!

## Configuration

To switch between the background card and floating text:
1. Right-click the widget.
2. Toggle the **"Show Card Background"** checkbox.
3. The layout switches and saves your setting automatically.

## License

GPL-3.0. Feel free to modify and share!
