# Network Info Widget (KDE Plasma 6)

A minimal, native network information widget designed for KDE Plasma 6 (fully tested on Fedora desktop). It displays critical connection details directly on your desktop or panels, using system fonts and colors to match your theme.

![Widget Preview Image](https://raw.githubusercontent.com/username/org.fedora.networkwidget/main/preview.png) *(Replace with your screenshot)*

## Features

- 🌐 **Interface Detection:** Automatically displays the active network interface name (WiFi, Ethernet, or VPN) and shows matching dynamic icons.
- 🏠 **Local IP Address:** Displays your machine's current local network address.
- 🌍 **Public IP Address:** Performs asynchronous queries using multi-source fallbacks to fetch your external IP. Displays `Offline` if you lose connection.
- 📋 **DNS Servers:** Resolves active DNS server addresses directly from `systemd-resolved` or `NetworkManager` (`nmcli`).
- 🎨 **Minimal & Adaptive Design:**
  - Automatically respects light/dark theme schemes and native typography.
  - **Floating Text Mode:** Right-click the widget and toggle off "Show Card Background" to remove borders, margins, and boxes, leaving only clean text floating on your wallpaper.
  - Automatically adds text outlines in floating mode to ensure legibility against any dark or light desktop wallpapers.
- ⚡ **Auto & Manual Refresh:** Runs on a 60-second background timer or immediately updates when you click anywhere on the widget.

## Requirements

- KDE Plasma 6.0+
- Python 3.x
- `NetworkManager` (`nmcli`) or `systemd-resolved` (`resolvectl`) — standard on Fedora and most modern Linux distros.

## Installation

### Manual Installation
If you have the `.plasmoid` package file, you can install it using `kpackagetool6`:

```bash
kpackagetool6 --type Plasma/Applet --install org.fedora.networkwidget.plasmoid
```

### Installation from Source (Git)
Clone the repository directly into your local Plasma widgets directory:

```bash
# Clone the repository
git clone https://github.com/YOUR_GITHUB_USERNAME/org.fedora.networkwidget.git ~/.local/share/plasma/plasmoids/org.fedora.networkwidget

# Rebuild KDE configuration cache
kbuildsycoca6

# Restart the desktop shell to load the widget
systemctl --user restart plasma-plasmashell
```

Once installed, right-click your desktop, select **Add Widgets...**, search for **"Network Info Widget"**, and drag it onto your desktop or panel!

## Configuration

To switch between **Card Background** and **Floating Text** mode:
1. Right-click the widget on your desktop.
2. Toggle the **"Show Card Background"** checkbox.
3. The layout will immediately switch and persist across reboots.

## License

GPL-3.0 License. Feel free to modify and share!
