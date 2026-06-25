# Network info widget for KDE Plasma 6

A minimal, native network info widget for KDE Plasma 6 (tested on Fedora). It displays connection details directly on your desktop or panels, using system fonts and colors that match your active theme.

![Widget preview](/asset/img/preview_default.webp)
![Widget preview full](/asset/img/preview_full_data.webp)

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

## 🚀 Installation & Setup

Choose the installation method that works best for you.

### Method 1: Quick Install from Source (Recommended)
This is the fastest way to get the latest features directly from GitHub.

```bash
# 1. Clone the repository into your local Plasma widgets directory
git clone https://github.com/KnowOneActual/org.fedora.networkwidget.git ~/.local/share/plasma/plasmoids/org.fedora.networkwidget

# 2. Rebuild the KDE configuration cache
kbuildsycoca6

# 3. Restart the Plasma shell to load the widget
systemctl --user restart plasma-plasmashell
```

### Method 2: Installing a `.plasmoid` Package
If you downloaded a pre-packaged `.plasmoid` file, install it via the terminal using `kpackagetool6`:

```bash
# To install for the first time
kpackagetool6 --type Plasma/Applet --install org.fedora.networkwidget.plasmoid

# To upgrade an existing installation
kpackagetool6 --type Plasma/Applet --upgrade org.fedora.networkwidget.plasmoid
```

### Method 3: Development Setup (Symbolic Link)
If you want to contribute or customize the widget locally, clone it to your development folder and link it:

```bash
# 1. Clone to your development folder
git clone https://github.com/KnowOneActual/org.fedora.networkwidget.git ~/projects/org.fedora.networkwidget

# 2. Symlink into your Plasma widgets directory
ln -s ~/projects/org.fedora.networkwidget ~/.local/share/plasma/plasmoids/org.fedora.networkwidget

# 3. Reload Plasma to apply changes
kbuildsycoca6
systemctl --user restart plasma-plasmashell
```
*Tip: With this setup, any changes you make in your dev folder are reflected immediately. Just run `systemctl --user restart plasma-plasmashell` to apply visual edits.*

---

## 🎨 How to Add the Widget
Once installed, follow these steps to add it to your desktop:
1. **Right-click** on your desktop wallpaper or panel.
2. Click **Add Widgets...** (or press `Meta+Alt+A`).
3. Search for **"Network Info Widget"**.
4. **Drag and drop** it onto your desktop or panel!

---

## ⚙️ Configuration & Advanced Features
To keep the widget minimal, advanced network details are **opt-in** and can be enabled through the configuration settings:

1. Right-click the widget on your desktop and select **Configure Network Info Widget...** (or click the gear icon).
2. Toggle any of the following features under the settings page:
   - **Show Switch/LLDP details:** Displays switch port name and switch MAC address.
   - **Show VPN connection status:** Displays active VPN profiles.
   - **Show connection latency (Ping):** Computes latency to check network quality.
   - **Show Subnet CIDR & MAC address:** Displays local CIDR (e.g. `/24`) and hardware address.
   - **Show real-time bandwidth (Speed & Usage):** Calculates real-time Rx/Tx bandwidth speeds and total session traffic.
   - **Show extended Wi-Fi information:** Displays band (5 GHz/2.4 GHz), channel, security protocols, and speed rate.
   - **Show ISP & Geolocation details:** Shows ISP name, city, and country.

---

## 💻 CLI Usage
The backend helper script can also be executed in the terminal. It pretty-prints colored status information when run interactively, and returns structured JSON when piped or run with `--json`.

```bash
python3 contents/ui/get_info.py [options]
```

### CLI Command Options:
- `--json`: Force JSON output formatting.
- `--hide-ipv6` / `--show-ipv6`: Control IPv6 visibility.
- `--show-latency`: Include ping latency.
- `--show-bandwidth`: Include real-time bandwidth speeds and usage stats.
- `--show-mac`: Include MAC addresses and CIDR subnet prefixes.
- `--show-extended-wifi`: Include detailed wireless configuration.
- `--show-geo`: Fetch ISP and location metadata.

---

## 📦 Packaging for Release
To package the widget into a distributable `.plasmoid` archive, zip the project contents from the root directory:

```bash
zip -r org.fedora.networkwidget.plasmoid metadata.json contents/ preview.webp
```

## 🔒 Security & Privacy

This widget is designed with security and privacy as first-class citizens:
- **Local-First Execution:** All network diagnostics (including interfaces, IPs, MAC addresses, VPNs, SSIDs, and LLDP details) are fetched locally using standard command-line tools.
- **No Data Harvesting or Telemetry:** The project does not track, collect, log, or transmit any user data or configuration details. No telemetry or analytics exist in this codebase.
- **Secure Lookups:** External connections are restricted to public IP and Geolocation resolution endpoints, and they only run if those features are explicitly enabled.
- **Static Analysis Compliance:** Codebase health and security are monitored, ensuring zero high-severity issues (like remote logging or unsanitized command injection).

For more detailed information or to report a vulnerability privately, please see our [SECURITY.md](SECURITY.md) policy.

## License
GPL-3.0. Feel free to modify and share!
