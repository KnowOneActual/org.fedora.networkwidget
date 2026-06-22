# Changelog

All notable changes to this project will be documented in this file.

## [1.3.0] - 2026-06-22

### Added
- **Latency / Ping Check:** Measures and displays connection ping to check network quality.
- **Subnet CIDR & MAC Address:** Exposes local subnet CIDR (e.g., `/22`) and hardware MAC address.
- **Real-time Bandwidth (Speed & Usage):** Calculates real-time Rx/Tx speeds and formats total session data downloaded/uploaded.
- **Extended Wi-Fi Details:** Shows frequency band (2.4 GHz/5 GHz/6 GHz), channel, max transfer rate, and security protocol of the active Wi-Fi.
- **ISP & Geolocation:** Displays public network ISP provider, city, and country.
- **Pre-packaged Widget Archive:** Added `org.fedora.networkwidget.plasmoid` directly to the repository for quick manual installations.

### Fixed
- **Safe Sizing and Reference Error Fix:** Resolved a `ReferenceError` when binding the root widget height by referencing `fullRepresentationItem` instead of `mainLayout` before initialization.
- **Ignore Rule Update:** Updated `.gitignore` to no longer ignore `.plasmoid` files.

## [1.2.1] - 2026-06-21

### Fixed
- **IPv6 Visibility Toggle:** Fixed a bug where toggling "Show IPv6 Addresses" had no effect because the widget did not trigger a refresh of the network script when the configuration changed.
- **CLI Configuration Override:** Modified the script runner in QML to explicitly pass `--show-ipv6` to `get_info.py` when enabled, bypassing stale or cached on-disk configurations.

## [1.2] - 2026-06-21

### Added
- **Default Gateway:** Added default gateway to the standard network info in both widget UI and terminal.
- **Monospace Typography:** Local IPs, Public IPs, Default Gateway, and DNS servers are now rendered in a clean system monospace font for optimal visual alignment and readability.
- **Beautiful Terminal CLI Output:** Running `get_info.py` directly in a terminal now prints a beautifully formatted, colored summary table of network info instead of raw JSON.
- **CLI Options:** Added `--json`, `--hide-ipv6`, and `--show-ipv6` to `get_info.py` to allow manual execution overriding.

### Changed
- **Reactive Model Binding:** Converted the widget to use a reactive `detailsList` JavaScript array property instead of an imperative QML `ListModel`, resolving synchronization/update lag completely.
- **Layout Sizing & Alignment:** The widget now dynamically recalculates its height based on the number of active rows (with/without IPv6), eliminating layout sizing bugs.
- **Stable Alignment:** Positioned the row copy icons absolutely on the right to prevent values from shifting horizontally when hovered.

### Optimized
- **IPv6 Network Optimization:** The python script now completely skips DNS and HTTP API queries for local/public IPv6 if IPv6 visibility is toggled off, avoiding network lookup delays.

## [1.1] - 2026-06-21

### Added
- **Dual-Stack IPv6 Support:** Display local and public IPv6 addresses alongside IPv4.
- **SSID and WiFi Signal Tracking:** Shows connected wireless network name (SSID) and signal strength percentage in real-time.
- **Click-to-Copy functionality:** Copy IP addresses, DNS, or interface name to the system clipboard on click.
- **Interactive UI Feedback:** Rows glow softly on hover, showing a copy icon (`edit-copy-symbolic`), and show a temporary "Copied!" feedback in accent color when clicked.
- **Dedicated Refresh Button:** A new refresh icon in the header with an infinite spin animation during network queries.
- **Dynamic Sizing:** The widget now auto-sizes its height to fit exactly the active rows (e.g. hides IPv6 rows if inactive).

### Changed
- Replaced manual background hint settings with robust layout-managed elements.
- Optimized README formatting for development, manual packaging, and symbolic link setup.

### Fixed
- Fixed QML warning regarding anchors used directly inside a `RowLayout` delegate.
- Fixed widget container height clipping, ensuring the card background wraps correctly around all lines of text.
- Cleaned up build files by adding `*.plasmoid` to `.gitignore`.
