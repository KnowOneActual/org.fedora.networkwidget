import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support
import org.kde.kquickcontrolsaddons as KQuickControlsAddons

PlasmoidItem {
    id: root

    // Stable sizing for the Plasma container
    implicitWidth: Kirigami.Units.gridUnit * 18
    implicitHeight: root.fullRepresentationItem ? root.fullRepresentationItem.implicitHeight : Kirigami.Units.gridUnit * 15

    // Properties to store network data
    property string interfaceName: "None"
    property string localIp: "..."
    property string localIpv6: "..."
    property string gateway: "..."
    property string publicIp: "..."
    property string publicIpv6: "..."
    property string dnsInfo: "..."
    property string wifiSsid: "None"
    property string wifiSignal: "None"
    property bool isRefreshing: false
    property bool isOnline: false
    property bool lldpActive: false
    property string switchName: "None"
    property string switchPort: "None"
    property string switchMac: "None"
    property bool vpnActive: false
    property string vpnName: "None"
    property string vpnType: "None"
    property string latency: "None"
    property string macAddress: "None"
    property string rxSpeed: "0 B/s"
    property string txSpeed: "0 B/s"
    property string totalRx: "0 B"
    property string totalTx: "0 B"
    property string wifiBand: "None"
    property string wifiChannel: "None"
    property string wifiRate: "None"
    property string wifiSecurity: "None"
    property string geoIsp: "None"
    property string geoCity: "None"
    property string geoCountry: "None"

    // Configuration change listeners
    readonly property bool showIPv6: plasmoid.configuration.showIPv6
    onShowIPv6Changed: root.refresh()
    readonly property bool showLldp: plasmoid.configuration.showLldp
    onShowLldpChanged: root.refresh()
    readonly property bool showVpn: plasmoid.configuration.showVpn
    onShowVpnChanged: root.refresh()
    readonly property bool showLatency: plasmoid.configuration.showLatency
    onShowLatencyChanged: root.refresh()
    readonly property bool showBandwidth: plasmoid.configuration.showBandwidth
    onShowBandwidthChanged: root.refresh()
    readonly property bool showMacAddress: plasmoid.configuration.showMacAddress
    onShowMacAddressChanged: root.refresh()
    readonly property bool showExtendedWifi: plasmoid.configuration.showExtendedWifi
    onShowExtendedWifiChanged: root.refresh()
    readonly property bool showGeo: plasmoid.configuration.showGeo
    onShowGeoChanged: root.refresh()

    // System theme colors
    readonly property color textColor: Kirigami.Theme.textColor
    readonly property color mutedTextColor: Kirigami.Theme.disabledTextColor
    readonly property color accentColor: Kirigami.Theme.highlightColor

    // Text outline configuration to ensure legibility when floating directly on wallpaper
    readonly property int textStyle: plasmoid.configuration.showBackground ? Text.Normal : Text.Outline
    readonly property color outlineColor: (root.textColor.r + root.textColor.g + root.textColor.b > 1.5) ? "#a0000000" : "#a0ffffff"

    // Set widget title and icon
    Plasmoid.title: "Fedora Network Info"
    Plasmoid.icon: isOnline ? "network-wired" : "network-disconnect"

    // Bind background depending on user config
    Plasmoid.backgroundHints: plasmoid.configuration.showBackground ? PlasmaCore.Types.DefaultBackground : PlasmaCore.Types.NoBackground

    // Keep it on full representation by default (desktop widget)
    preferredRepresentation: fullRepresentation

    // Context menu actions (Right-click menu on desktop)
    Plasmoid.contextualActions: [
        PlasmaCore.Action {
            text: "Show Card Background"
            icon.name: "view-background-color"
            checkable: true
            checked: plasmoid.configuration.showBackground
            onTriggered: {
                plasmoid.configuration.showBackground = !plasmoid.configuration.showBackground;
            }
        },
        PlasmaCore.Action {
            text: "Show IPv6 Addresses"
            icon.name: "network-wired"
            checkable: true
            checked: plasmoid.configuration.showIPv6
            onTriggered: {
                plasmoid.configuration.showIPv6 = !plasmoid.configuration.showIPv6;
            }
        }
    ]

    // Clipboard helper
    KQuickControlsAddons.Clipboard {
        id: clipboard
    }

    // Dynamic reactive model list to hold rows that should be displayed
    readonly property var detailsList: {
        var list = [];
        
        // Interface name and SSID/Signal
        var interfaceVal = root.interfaceName;
        if (root.wifiSsid !== "None") {
            interfaceVal += " (" + root.wifiSsid + ", " + root.wifiSignal + "%)";
        }
        list.push({ "label": "Interface", "value": interfaceVal, "rawValue": root.interfaceName });
        
        // Switch / LLDP details (if showLldp is enabled and lldp is active)
        if (plasmoid.configuration.showLldp && root.lldpActive) {
            var switchVal = root.switchPort + " (on " + root.switchName + ")";
            list.push({ "label": "Switch Port", "value": switchVal, "rawValue": root.switchPort });
            list.push({ "label": "Switch MAC", "value": root.switchMac, "rawValue": root.switchMac });
        }
        
        // Wi-Fi details (if showExtendedWifi is enabled and Wi-Fi SSID is active)
        if (plasmoid.configuration.showExtendedWifi && root.wifiSsid !== "None") {
            var wifiVal = root.wifiBand + ", Ch " + root.wifiChannel + ", " + root.wifiSecurity + ", " + root.wifiRate;
            list.push({ "label": "Wi-Fi Details", "value": wifiVal, "rawValue": wifiVal });
        }
        
        // Local IPs & Gateway
        list.push({ "label": "Local IPv4", "value": root.localIp, "rawValue": root.localIp });
        if (root.gateway !== "None" && root.gateway !== "") {
            list.push({ "label": "Default Gateway", "value": root.gateway, "rawValue": root.gateway });
        }
        if (plasmoid.configuration.showIPv6 && root.localIpv6 !== "None" && root.localIpv6 !== "") {
            list.push({ "label": "Local IPv6", "value": root.localIpv6, "rawValue": root.localIpv6 });
        }
        
        // MAC Address (if showMacAddress is enabled)
        if (plasmoid.configuration.showMacAddress && root.macAddress !== "None" && root.macAddress !== "") {
            list.push({ "label": "MAC Address", "value": root.macAddress, "rawValue": root.macAddress });
        }
        
        // VPN (if showVpn is enabled)
        if (plasmoid.configuration.showVpn) {
            var vpnVal = root.vpnActive ? "Active (" + root.vpnName + ")" : "Disconnected";
            list.push({ "label": "VPN Connection", "value": vpnVal, "rawValue": root.vpnActive ? root.vpnName : "Disconnected" });
        }
        
        // Public IPs
        list.push({ "label": "Public IPv4", "value": root.publicIp, "rawValue": root.publicIp });
        if (plasmoid.configuration.showIPv6 && root.publicIpv6 !== "Offline" && root.publicIpv6 !== "None" && root.publicIpv6 !== "") {
            list.push({ "label": "Public IPv6", "value": root.publicIpv6, "rawValue": root.publicIpv6 });
        }
        
        // ISP & Geolocation (if showGeo is enabled)
        if (plasmoid.configuration.showGeo && root.geoIsp !== "None" && root.geoIsp !== "") {
            list.push({ "label": "ISP", "value": root.geoIsp, "rawValue": root.geoIsp });
            var geoLoc = root.geoCity + ", " + root.geoCountry;
            list.push({ "label": "Location", "value": geoLoc, "rawValue": geoLoc });
        }
        
        // DNS
        list.push({ "label": "DNS Servers", "value": root.dnsInfo, "rawValue": root.dnsInfo });
        
        // Connection Latency (if showLatency is enabled)
        if (plasmoid.configuration.showLatency && root.latency !== "None" && root.latency !== "") {
            list.push({ "label": "Latency", "value": root.latency, "rawValue": root.latency });
        }
        
        // Bandwidth Speeds & Usage (if showBandwidth is enabled)
        if (plasmoid.configuration.showBandwidth) {
            var speedVal = "Rx: " + root.rxSpeed + " | Tx: " + root.txSpeed;
            list.push({ "label": "Bandwidth Speed", "value": speedVal, "rawValue": speedVal });
            var dataVal = "Down: " + root.totalRx + " | Up: " + root.totalTx;
            list.push({ "label": "Session Data", "value": dataVal, "rawValue": dataVal });
        }
        
        return list;
    }

    // The data source to run the python helper script
    Plasma5Support.DataSource {
        id: executable
        engine: "executable"
        connectedSources: []
        
        onNewData: (sourceName, data) => {
            disconnectSource(sourceName);
            var stdout = data["stdout"];
            if (stdout) {
                try {
                    var parsed = JSON.parse(stdout.trim());
                    root.interfaceName = parsed.interface || "None";
                    root.localIp = parsed.local_ip || "None";
                    root.localIpv6 = parsed.local_ipv6 || "None";
                    root.gateway = parsed.gateway || "None";
                    root.publicIp = parsed.public_ip || "Offline";
                    root.publicIpv6 = parsed.public_ipv6 || "Offline";
                    root.wifiSsid = parsed.wifi_ssid || "None";
                    root.wifiSignal = parsed.wifi_signal || "None";
                    
                    root.lldpActive = parsed.lldp_active || false;
                    root.switchName = parsed.switch_name || "None";
                    root.switchPort = parsed.switch_port || "None";
                    root.switchMac = parsed.switch_mac || "None";
                    
                    root.vpnActive = parsed.vpn_active || false;
                    root.vpnName = parsed.vpn_name || "None";
                    root.vpnType = parsed.vpn_type || "None";
                    
                    root.latency = parsed.latency || "None";
                    root.macAddress = parsed.mac_address || "None";
                    root.rxSpeed = parsed.rx_speed || "0 B/s";
                    root.txSpeed = parsed.tx_speed || "0 B/s";
                    root.totalRx = parsed.total_rx || "0 B";
                    root.totalTx = parsed.total_tx || "0 B";
                    root.wifiBand = parsed.wifi_band || "None";
                    root.wifiChannel = parsed.wifi_channel || "None";
                    root.wifiRate = parsed.wifi_rate || "None";
                    root.wifiSecurity = parsed.wifi_security || "None";
                    root.geoIsp = parsed.geo_isp || "None";
                    root.geoCity = parsed.geo_city || "None";
                    root.geoCountry = parsed.geo_country || "None";
                    
                    if (parsed.dns && parsed.dns.length > 0) {
                        root.dnsInfo = parsed.dns.join(", ");
                    } else {
                        root.dnsInfo = "None";
                    }
                    root.isOnline = (root.publicIp !== "Offline" && root.publicIp !== "None" && root.interfaceName !== "None");
                } catch (e) {
                    console.log("JSON Parse error: " + e);
                }
            }
            root.isRefreshing = false;
        }

        function runScript() {
            var scriptPath = Qt.resolvedUrl("get_info.py").toString();
            // QML resolved URL starts with file://, strip it for bash execution
            if (scriptPath.indexOf("file://") === 0) {
                scriptPath = scriptPath.substring(7);
            }
            var cmd = "python3 " + scriptPath + " --json";
            if (!plasmoid.configuration.showIPv6) {
                cmd += " --hide-ipv6";
            } else {
                cmd += " --show-ipv6";
            }
            if (plasmoid.configuration.showLatency) {
                cmd += " --show-latency";
            }
            if (plasmoid.configuration.showBandwidth) {
                cmd += " --show-bandwidth";
            }
            if (plasmoid.configuration.showMacAddress) {
                cmd += " --show-mac";
            }
            if (plasmoid.configuration.showExtendedWifi) {
                cmd += " --show-extended-wifi";
            }
            if (plasmoid.configuration.showGeo) {
                cmd += " --show-geo";
            }
            connectSource(cmd);
        }
    }

    // Refresh function
    function refresh() {
        if (root.isRefreshing) return;
        root.isRefreshing = true;
        executable.runScript();
    }

    // Auto refresh timer: 60 seconds
    Timer {
        id: refreshTimer
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // QML representation
    fullRepresentation: Item {
        id: panelItem
        implicitWidth: Kirigami.Units.gridUnit * 18
        implicitHeight: mainLayout.implicitHeight + Kirigami.Units.largeSpacing * 2

        ColumnLayout {
            id: mainLayout
            anchors.fill: parent
            anchors.margins: Kirigami.Units.largeSpacing
            spacing: Kirigami.Units.smallSpacing

            // Header Section
            RowLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                // Icon dynamically matches the type of interface or offline status
                Kirigami.Icon {
                    source: {
                        if (!root.isOnline) return "network-disconnect";
                        if (root.interfaceName.indexOf("wl") === 0) return "network-wireless";
                        if (root.interfaceName.indexOf("en") === 0 || root.interfaceName.indexOf("eth") === 0) return "network-wired";
                        return "network-vpn";
                    }
                    implicitWidth: Kirigami.Units.iconSizes.smallMedium
                    implicitHeight: Kirigami.Units.iconSizes.smallMedium
                    color: root.isOnline ? root.accentColor : root.mutedTextColor
                }

                // Title
                PlasmaComponents.Label {
                    text: "NETWORK SUMMARY"
                    font.bold: true
                    font.pixelSize: Kirigami.Theme.smallFont.pixelSize
                    font.letterSpacing: 1.2
                    color: root.textColor
                    style: root.textStyle
                    styleColor: root.outlineColor
                    Layout.fillWidth: true
                }

                // Status Indicator dot
                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: root.isRefreshing ? "#E6A23C" : (root.isOnline ? "#67C23A" : "#F56C6C")
                    
                    // Simple transition on color changes
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                    Layout.rightMargin: 4
                }

                // Dedicated Refresh Icon with spin animation
                Kirigami.Icon {
                    id: refreshIcon
                    source: "view-refresh"
                    implicitWidth: Kirigami.Units.iconSizes.small
                    implicitHeight: Kirigami.Units.iconSizes.small
                    color: root.textColor
                    opacity: refreshMouseArea.containsMouse ? 1.0 : 0.6
                    
                    Behavior on opacity { NumberAnimation { duration: 150 } }

                    RotationAnimation on rotation {
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: 1000
                        running: root.isRefreshing
                    }

                    MouseArea {
                        id: refreshMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.refresh()
                    }
                }
            }

            // Muted divider line
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.textColor
                opacity: plasmoid.configuration.showBackground ? 0.15 : 0.05
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
            }

            // Column of network details
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: root.detailsList

                    delegate: Item {
                        id: rowItem
                        Layout.fillWidth: true
                        implicitHeight: Kirigami.Units.gridUnit * 1.5

                        property bool isHovered: false
                        property bool isCopied: false

                        Timer {
                            id: copiedTimer
                            interval: 1500
                            onTriggered: rowItem.isCopied = false
                        }

                        // Background highlight on hover
                        Rectangle {
                            anchors.fill: parent
                            color: root.textColor
                            opacity: rowItem.isCopied ? 0.12 : (rowItem.isHovered ? 0.06 : 0.0)
                            radius: 4
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }

                        // Content layout
                        RowLayout {
                            anchors.fill: parent
                            anchors.rightMargin: 24 // Reserve space for copy icon to prevent shifting
                            spacing: Kirigami.Units.smallSpacing

                            // Label
                            PlasmaComponents.Label {
                                text: modelData.label
                                color: root.mutedTextColor
                                style: root.textStyle
                                styleColor: root.outlineColor
                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                                Layout.leftMargin: 6
                            }

                            // Spacer
                            Item {
                                Layout.fillWidth: true
                            }

                            // Value
                            PlasmaComponents.Label {
                                text: rowItem.isCopied ? "Copied!" : modelData.value
                                color: rowItem.isCopied ? root.accentColor : ((modelData.label.indexOf("Public") === 0 && modelData.value === "Offline") ? "#F56C6C" : root.textColor)
                                font.bold: (modelData.label === "Interface")
                                font.family: (modelData.label.indexOf("IPv") >= 0 || modelData.label.indexOf("Gateway") >= 0 || modelData.label === "DNS Servers") ? "monospace" : ""
                                style: root.textStyle
                                styleColor: root.outlineColor
                                font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                horizontalAlignment: Text.AlignRight
                                elide: Text.ElideLeft
                                // Let the text expand up to 70% of the row width
                                Layout.maximumWidth: parent.width * 0.7
                            }
                        }

                        // Copy icon (absolutely positioned on the right)
                        Kirigami.Icon {
                            source: "edit-copy-symbolic"
                            implicitWidth: Kirigami.Units.iconSizes.small
                            implicitHeight: Kirigami.Units.iconSizes.small
                            color: rowItem.isCopied ? root.accentColor : root.mutedTextColor
                            opacity: rowItem.isHovered || rowItem.isCopied ? 0.8 : 0.0
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                            anchors.right: parent.right
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        // Copy MouseArea
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: rowItem.isHovered = true
                            onExited: rowItem.isHovered = false
                            onClicked: {
                                clipboard.content = modelData.rawValue;
                                rowItem.isCopied = true;
                                copiedTimer.restart();
                            }
                        }
                    }
                }

                // Vertical spacer to push rows to the top if there are fewer active lines (e.g. IPv6 offline)
                Item {
                    Layout.fillHeight: true
                }
            }
        }
    }
}
