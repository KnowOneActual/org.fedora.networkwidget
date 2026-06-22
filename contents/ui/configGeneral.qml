import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page
    width: childrenRect.width
    height: childrenRect.height

    property alias cfg_showBackground: showBackgroundCheckbox.checked
    property alias cfg_showIPv6: showIPv6Checkbox.checked
    property alias cfg_showVlan: showVlanCheckbox.checked
    property alias cfg_showVpn: showVpnCheckbox.checked
    property alias cfg_showLatency: showLatencyCheckbox.checked
    property alias cfg_showBandwidth: showBandwidthCheckbox.checked
    property alias cfg_showMacAddress: showMacAddressCheckbox.checked
    property alias cfg_showExtendedWifi: showExtendedWifiCheckbox.checked
    property alias cfg_showGeo: showGeoCheckbox.checked

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right

        CheckBox {
            id: showBackgroundCheckbox
            Kirigami.FormData.label: i18n("Appearance:")
            text: i18n("Show background card")
        }

        CheckBox {
            id: showIPv6Checkbox
            text: i18n("Show IPv6 addresses")
        }

        CheckBox {
            id: showVlanCheckbox
            Kirigami.FormData.label: i18n("Advanced Features:")
            text: i18n("Show VLAN details")
        }

        CheckBox {
            id: showVpnCheckbox
            text: i18n("Show VPN connection status")
        }

        CheckBox {
            id: showLatencyCheckbox
            text: i18n("Show connection latency (Ping)")
        }

        CheckBox {
            id: showMacAddressCheckbox
            text: i18n("Show Subnet CIDR & MAC address")
        }

        CheckBox {
            id: showBandwidthCheckbox
            text: i18n("Show real-time bandwidth (Speed & Usage)")
        }

        CheckBox {
            id: showExtendedWifiCheckbox
            text: i18n("Show extended Wi-Fi information")
        }

        CheckBox {
            id: showGeoCheckbox
            text: i18n("Show ISP & Geolocation details")
        }
    }
}
