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

## Installation & Development

### Manual installation
If you have the `.plasmoid` package, install it using `kpackagetool6`:

```bash
# To install for the first time
kpackagetool6 --type Plasma/Applet --install org.fedora.networkwidget.plasmoid

# To upgrade an existing installation
kpackagetool6 --type Plasma/Applet --upgrade org.fedora.networkwidget.plasmoid
```

### Installation from source (Git)
If you just want to install the latest source directly:

```bash
# Clone the repository directly into your Plasma widgets directory
git clone https://github.com/KnowOneActual/org.fedora.networkwidget.git ~/.local/share/plasma/plasmoids/org.fedora.networkwidget

# Rebuild KDE configuration cache and restart the shell
kbuildsycoca6
systemctl --user restart plasma-plasmashell
```

### Development Setup (Recommended)
If you want to modify or develop the widget, it is best to clone it to your projects directory and create a symbolic link to the Plasma folder:

```bash
# 1. Clone to your development folder (e.g., ~/github/)
git clone https://github.com/KnowOneActual/org.fedora.networkwidget.git ~/github/org.fedora.networkwidget

# 2. Create a symbolic link in the local Plasma widgets directory
ln -s ~/github/org.fedora.networkwidget ~/.local/share/plasma/plasmoids/org.fedora.networkwidget

# 3. Rebuild KDE cache and restart the shell
kbuildsycoca6
systemctl --user restart plasma-plasmashell
```

With this setup, any changes you make in your development folder will be live immediately. You just need to run `systemctl --user restart plasma-plasmashell` to reload the widget.

### Packaging (Building `.plasmoid`)
To package the widget into a distributable `.plasmoid` file, zip the project contents from the root directory:

```bash
zip -r org.fedora.networkwidget.plasmoid metadata.json contents/
```

Once installed, right-click your desktop, select **Add Widgets...**, search for **"Network Info Widget"**, and drag it onto your desktop or panel!

## Configuration

To switch between the background card and floating text:
1. Right-click the widget.
2. Toggle the **"Show Card Background"** checkbox.
3. The layout switches and saves your setting automatically.

## License

GPL-3.0. Feel free to modify and share!
