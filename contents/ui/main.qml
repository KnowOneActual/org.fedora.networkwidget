import QtQuick
import QtQuick.Layouts
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid
import org.kde.kirigami as Kirigami
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.plasma5support as Plasma5Support

PlasmoidItem {
    id: root

    // Properties to store network data
    property string interfaceName: "wlp2s0"
    property string localIp: "..."
    property string publicIp: "..."
    property string dnsInfo: "..."
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
                    root.publicIp = parsed.public_ip || "Offline";
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
        implicitWidth: Kirigami.Units.gridUnit * 15
        implicitHeight: Kirigami.Units.gridUnit * 7.5

        ColumnLayout {
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
                }
            }

            // Muted divider line (fades out in floating mode)
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: root.textColor
                opacity: plasmoid.configuration.showBackground ? 0.15 : 0.05
                Layout.topMargin: Kirigami.Units.smallSpacing
                Layout.bottomMargin: Kirigami.Units.smallSpacing
            }

            // Grid of network details
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 2
                rowSpacing: Kirigami.Units.smallSpacing
                columnSpacing: Kirigami.Units.largeSpacing

                // Row 1: Interface
                PlasmaComponents.Label {
                    text: "Interface"
                    color: root.mutedTextColor
                    style: root.textStyle
                    styleColor: root.outlineColor
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                }
                PlasmaComponents.Label {
                    text: root.interfaceName
                    color: root.textColor
                    font.bold: true
                    style: root.textStyle
                    styleColor: root.outlineColor
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                }

                // Row 2: Local IP
                PlasmaComponents.Label {
                    text: "Local IP"
                    color: root.mutedTextColor
                    style: root.textStyle
                    styleColor: root.outlineColor
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                }
                PlasmaComponents.Label {
                    text: root.localIp
                    color: root.textColor
                    style: root.textStyle
                    styleColor: root.outlineColor
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                }

                // Row 3: Public IP
                PlasmaComponents.Label {
                    text: "Public IP"
                    color: root.mutedTextColor
                    style: root.textStyle
                    styleColor: root.outlineColor
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                }
                PlasmaComponents.Label {
                    text: root.publicIp
                    color: root.isOnline ? root.textColor : "#F56C6C"
                    style: root.textStyle
                    styleColor: root.outlineColor
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                }

                // Row 4: DNS
                PlasmaComponents.Label {
                    text: "DNS Servers"
                    color: root.mutedTextColor
                    style: root.textStyle
                    styleColor: root.outlineColor
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                }
                PlasmaComponents.Label {
                    text: root.dnsInfo
                    color: root.textColor
                    style: root.textStyle
                    styleColor: root.outlineColor
                    font.pixelSize: Kirigami.Theme.defaultFont.pixelSize
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    horizontalAlignment: Text.AlignRight
                    elide: Text.ElideLeft
                }
            }
        }

        // Entire widget can be clicked to refresh
        MouseArea {
            anchors.fill: parent
            onClicked: root.refresh()
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
        }
    }
}
