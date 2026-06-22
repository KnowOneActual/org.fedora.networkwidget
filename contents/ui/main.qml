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

    // Sizing propagation to the parent Plasma container
    implicitWidth: fullRepresentationItem ? fullRepresentationItem.implicitWidth : Kirigami.Units.gridUnit * 16
    implicitHeight: fullRepresentationItem ? fullRepresentationItem.implicitHeight : Kirigami.Units.gridUnit * 10

    // Properties to store network data
    property string interfaceName: "None"
    property string localIp: "..."
    property string localIpv6: "..."
    property string publicIp: "..."
    property string publicIpv6: "..."
    property string dnsInfo: "..."
    property string wifiSsid: "None"
    property string wifiSignal: "None"
    property bool isRefreshing: false
    property bool isOnline: false

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
        }
    ]

    // Clipboard helper
    KQuickControlsAddons.Clipboard {
        id: clipboard
    }

    // Dynamic model to hold rows that should be displayed
    ListModel {
        id: detailsModel
    }

    // Update details model dynamically based on active interfaces/addresses
    function updateModel() {
        detailsModel.clear();
        
        // Interface name and SSID/Signal
        var interfaceVal = root.interfaceName;
        if (root.wifiSsid !== "None") {
            interfaceVal += " (" + root.wifiSsid + ", " + root.wifiSignal + "%)";
        }
        detailsModel.append({ "label": "Interface", "value": interfaceVal, "rawValue": root.interfaceName });
        
        // Local IPs
        detailsModel.append({ "label": "Local IPv4", "value": root.localIp, "rawValue": root.localIp });
        if (root.localIpv6 !== "None" && root.localIpv6 !== "") {
            detailsModel.append({ "label": "Local IPv6", "value": root.localIpv6, "rawValue": root.localIpv6 });
        }
        
        // Public IPs
        detailsModel.append({ "label": "Public IPv4", "value": root.publicIp, "rawValue": root.publicIp });
        if (root.publicIpv6 !== "Offline" && root.publicIpv6 !== "None" && root.publicIpv6 !== "") {
            detailsModel.append({ "label": "Public IPv6", "value": root.publicIpv6, "rawValue": root.publicIpv6 });
        }
        
        // DNS
        detailsModel.append({ "label": "DNS Servers", "value": root.dnsInfo, "rawValue": root.dnsInfo });
    }

    Component.onCompleted: {
        updateModel();
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
                    root.publicIp = parsed.public_ip || "Offline";
                    root.publicIpv6 = parsed.public_ipv6 || "Offline";
                    root.wifiSsid = parsed.wifi_ssid || "None";
                    root.wifiSignal = parsed.wifi_signal || "None";
                    
                    if (parsed.dns && parsed.dns.length > 0) {
                        root.dnsInfo = parsed.dns.join(", ");
                    } else {
                        root.dnsInfo = "None";
                    }
                    root.isOnline = (root.publicIp !== "Offline" && root.publicIp !== "None" && root.interfaceName !== "None");
                    
                    // Update the model dynamically
                    root.updateModel();
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
            connectSource("python3 " + scriptPath);
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
        implicitWidth: Kirigami.Units.gridUnit * 16
        implicitHeight: mainLayout.implicitHeight + Kirigami.Units.largeSpacing * 2

        ColumnLayout {
            id: mainLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
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
                    model: detailsModel

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
                            spacing: Kirigami.Units.smallSpacing

                            // Label
                            PlasmaComponents.Label {
                                text: model.label
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

                            // Value and copy icon
                            RowLayout {
                                spacing: 6
                                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                                Layout.rightMargin: 6

                                PlasmaComponents.Label {
                                    text: rowItem.isCopied ? "Copied!" : model.value
                                    color: rowItem.isCopied ? root.accentColor : ((model.label.indexOf("Public") === 0 && model.value === "Offline") ? "#F56C6C" : root.textColor)
                                    font.bold: (model.label === "Interface")
                                    style: root.textStyle
                                    styleColor: root.outlineColor
                                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideLeft
                                    Layout.maximumWidth: Kirigami.Units.gridUnit * 10
                                }

                                Kirigami.Icon {
                                    source: "edit-copy-symbolic"
                                    implicitWidth: Kirigami.Units.iconSizes.small
                                    implicitHeight: Kirigami.Units.iconSizes.small
                                    color: rowItem.isCopied ? root.accentColor : root.mutedTextColor
                                    opacity: rowItem.isHovered || rowItem.isCopied ? 0.8 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 150 } }
                                }
                            }
                        }

                        // Copy MouseArea
                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: rowItem.isHovered = true
                            onExited: rowItem.isHovered = false
                            onClicked: {
                                clipboard.content = model.rawValue;
                                rowItem.isCopied = true;
                                copiedTimer.restart();
                            }
                        }
                    }
                }
            }
        }
    }
}
