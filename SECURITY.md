# Security Policy & Privacy details

## Security & Privacy Commitment

The Network Info Widget prioritizes user privacy and system security. Since this widget displays network configuration details (such as local/public IP addresses, gateways, DNS servers, SSIDs, and active VPN connection names), it is built to operate under strict safety guidelines.

---

## 🔒 Privacy & Data Architecture

1. **Local-First Processing**: Nearly all data gathering is performed entirely on your local machine using standard system command line tools (`nmcli`, `ip`, `resolvectl`).
2. **No Data Collection**: The widget does not log, track, or collect your data. There are no tracking scripts, telemetry, or backend servers connected to this project.
3. **External Network Queries**:
   * **Public IP Resolution**: To display your public IPv4 and IPv6 addresses, the Python backend makes HTTP GET queries to external lookup services (such as `ip-api.com/json` and `icanhazip.com`).
   * No local metadata, MAC addresses, interface names, or configuration details are transmitted during these requests.
   * If you choose to turn off public IP lookups (e.g. by disabling IPv6 or disconnecting from the internet), the script gracefully skips network queries and runs instantly.

---

## 🛡️ Supported Versions

Only the latest release version is supported with security updates:

| Version | Supported |
| ------- | --------- |
| 1.2.x   | Yes       |
| < 1.2   | No        |

---

## 🚨 Reporting a Vulnerability

If you discover a security vulnerability or privacy leak, please **do not open a public GitHub issue**. Instead, report it privately:

1. Send an email to **Beau Bremer** (the author listed in [metadata.json](file:///home/user/github/org.fedora.networkwidget/metadata.json)).
2. Describe the vulnerability, including instructions on how to reproduce it or a proof of concept.
3. We will review the report and attempt to coordinate a fix within 72 hours.
