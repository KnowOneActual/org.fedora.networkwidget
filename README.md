# Network info widget for KDE Plasma 6

A minimal, native network info widget for KDE Plasma 6 (tested on Fedora). It displays connection details directly on your desktop or panels, using system fonts and colors that match your active theme.

![Widget preview](https://raw.githubusercontent.com/username/org.fedora.networkwidget/main/preview.png)

## Features

- 🌐 **Interface Detection:** Automatically displays the active interface name (WiFi, Ethernet, or VPN) with matching system icons.
- 🏠 **Dual-Stack IP Info:** Displays local and public IPv4 and IPv6 addresses.
- 🔑 **Default Gateway:** Shows the default network gateway in standard info.
- 📋 **DNS Servers:** Resolves active DNS addresses from `systemd-resolved` or `NetworkManager` (`nmcli`).
- 📶 **WiFi Tracking:** Displays wireless SSID and signal strength percentage in real-time.
- ✂️ **Click-to-Copy:** Click any detail row to copy its raw value to the system clipboard (with hover highlighting and visual feedback).
- ⚙️ **Context Customization:** Right-click the widget to toggle:
  - **Show Card Background:** Toggle background container/borders off to let text float on your wallpaper (includes text outlines for readability).
  - **Show IPv6 Addresses:** Toggle IPv6 visibility. Automatically adapts layout height.
- ⚡ **Auto & Manual Refresh:** Updates on a 60-second timer or immediately when clicking the refresh icon.

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

## CLI Usage

The backend helper script can be executed directly in the terminal to inspect network details. It automatically pretty-prints colored text when run in a TTY, and outputs JSON when piped or run in scripts.

```bash
python3 contents/ui/get_info.py
```

### CLI Options

- `--json`: Force raw JSON output format.
- `--hide-ipv6`: Hide IPv6 details.
- `--show-ipv6`: Force show IPv6 details (overrides desktop configuration).

## Configuration

To switch between the background card and floating text:
1. Right-click the widget.
2. Toggle the **"Show Card Background"** checkbox.
3. The layout switches and saves your setting automatically.

## License

GPL-3.0. Feel free to modify and share!
