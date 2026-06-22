# Changelog

All notable changes to this project will be documented in this file.

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
- Cleaned up build files by adding `*.plasmoid` to `.gitignore`.
