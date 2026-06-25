#!/usr/bin/env python3
import subprocess
import re
import json
import urllib.request
import sys
import argparse
import os

def get_default_interface():
    try:
        res = subprocess.run(["ip", "route", "show", "default"], capture_output=True, text=True, errors="replace", check=True)
        lines = res.stdout.strip().split('\n')
        if not lines or not lines[0]:
            return None
        match = re.search(r'dev\s+(\S+)', lines[0])
        if match:
            return match.group(1)
    except Exception:
        pass
def get_default_gateway():
    try:
        res = subprocess.run(["ip", "route", "show", "default"], capture_output=True, text=True, errors="replace", check=True)
        lines = res.stdout.strip().split('\n')
        if not lines or not lines[0]:
            return None
        match = re.search(r'via\s+(\S+)', lines[0])
        if match:
            return match.group(1)
    except Exception:
        pass
    return None


def get_local_ip(interface, show_cidr=False):
    if not interface:
        return None
    try:
        res = subprocess.run(["ip", "-4", "addr", "show", interface], capture_output=True, text=True, errors="replace", check=True)
        if show_cidr:
            match = re.search(r'inet\s+(\d+\.\d+\.\d+\.\d+/\d+)', res.stdout)
            if match:
                return match.group(1)
        match = re.search(r'inet\s+(\d+\.\d+\.\d+\.\d+)', res.stdout)
        if match:
            return match.group(1)
    except Exception:
        pass
    return None

def get_local_ipv6(interface, show_cidr=False):
    if not interface:
        return None
    try:
        res = subprocess.run(["ip", "-6", "addr", "show", interface], capture_output=True, text=True, errors="replace", check=True)
        for line in res.stdout.splitlines():
            if "inet6" in line and "scope global" in line:
                if show_cidr:
                    match = re.search(r'inet6\s+([a-fA-F0-9:]+/\d+)', line)
                    if match:
                        return match.group(1)
                match = re.search(r'inet6\s+([a-fA-F0-9:]+)', line)
                if match:
                    return match.group(1)
    except Exception:
        pass
    return None

def get_dns_servers(interface):
    dns_servers = []
    if not interface:
        return dns_servers
    try:
        # Try nmcli first
        res = subprocess.run(["nmcli", "dev", "show", interface], capture_output=True, text=True, errors="replace", check=True)
        for line in res.stdout.splitlines():
            if "IP4.DNS" in line or "IP6.DNS" in line:
                parts = line.split(":", 1)
                if len(parts) == 2:
                    dns_servers.append(parts[1].strip())
    except Exception:
        pass
    
    if not dns_servers:
        try:
            res = subprocess.run(["resolvectl", "dns", interface], capture_output=True, text=True, errors="replace", check=True)
            # Find both IPv4 and IPv6 addresses
            ips = re.findall(r'[a-fA-F0-9:.]+', res.stdout)
            for ip in ips:
                # Basic check for valid IP (either has dots or colons)
                if ("." in ip and re.match(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$', ip)) or (":" in ip and not ip.endswith(":") and not ip.startswith(":")):
                    dns_servers.append(ip)
        except Exception:
            pass
    return dns_servers

def get_public_ip(ipv6=False):
    if ipv6:
        urls = [
            "https://api6.ipify.org",
            "https://icanhazip.com",
            "https://ifconfig.co/ip"
        ]
    else:
        urls = [
            "https://api4.ipify.org",
            "https://icanhazip.com",
            "https://ifconfig.co/ip"
        ]
    for url in urls:
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=2.0) as response:  # nosec B310
                ip = response.read().decode('utf-8', errors="replace").strip()
                if ipv6:
                    if ":" in ip and not ip.endswith(":") and not ip.startswith(":"):
                        return ip
                else:
                    if re.match(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$', ip):
                        return ip
        except Exception:
            continue
    return "Offline"

def get_wifi_details(interface):
    if not interface or not interface.startswith("wl"):
        return None, None
    try:
        res = subprocess.run(["nmcli", "-t", "-f", "active,ssid,signal", "dev", "wifi"], capture_output=True, text=True, errors="replace", check=True)
        for line in res.stdout.splitlines():
            if line.startswith("yes:"):
                parts = line.split(":")
                if len(parts) >= 3:
                    return parts[1], parts[2]
    except Exception:
        pass
    return None, None

def get_lldp_details(interface):
    if not interface or interface == "None":
        return None
    try:
        res = subprocess.run(["nmcli", "-t", "device", "lldp", "list", "ifname", interface], capture_output=True, text=True, errors="replace", check=True)
        
        system_name = None
        port_desc = None
        port_id = None
        chassis_id = None
        
        for line in res.stdout.splitlines():
            line = line.strip()
            parts = line.split(":", 1)
            if len(parts) != 2:
                continue
            key, val = parts[0], parts[1]
            if "SYSTEM-NAME" in key:
                system_name = val
            elif "PORT-DESCRIPTION" in key:
                port_desc = val
            elif "PORT-ID" in key:
                port_id = val
            elif "CHASSIS-ID" in key:
                chassis_id = val
                
        port = port_desc or port_id
        
        if system_name or port or chassis_id:
            return {
                "lldp_active": True,
                "switch_name": system_name or "Unknown",
                "switch_port": port or "Unknown",
                "switch_mac": chassis_id or "Unknown"
            }
    except Exception:
        pass
    return {
        "lldp_active": False,
        "switch_name": "None",
        "switch_port": "None",
        "switch_mac": "None"
    }

def get_vpn_details():
    try:
        res = subprocess.run(["nmcli", "-t", "-f", "name,type,active", "connection", "show"], capture_output=True, text=True, errors="replace", check=True)
        for line in res.stdout.splitlines():
            parts = line.strip().split(":")
            if len(parts) >= 3:
                name, conn_type, active = parts[0], parts[1], parts[2]
                if active == "yes" and (conn_type in ("vpn", "wireguard", "tun")):
                    return {
                        "vpn_active": True,
                        "vpn_name": name,
                        "vpn_type": conn_type
                    }
    except Exception:
        pass
    return {
        "vpn_active": False,
        "vpn_name": "None",
        "vpn_type": "None"
    }

def get_mac_address(interface):
    if not interface or interface == "None":
        return None
    try:
        addr_path = f"/sys/class/net/{interface}/address"
        if os.path.exists(addr_path):
            with open(addr_path, "r", encoding="utf-8", errors="replace") as f:
                return f.read().strip()
    except Exception:
        pass
    return None

def get_latency(gateway=None):
    import time
    targets = ["1.1.1.1"]
    if gateway and gateway != "None":
        targets.append(gateway)
        
    for target in targets:
        try:
            res = subprocess.run(["ping", "-c", "1", "-W", "1", target], capture_output=True, text=True, errors="replace", timeout=1.5)
            if res.returncode == 0:
                match = re.search(r'time=(\d+(?:\.\d+)?)\s*ms', res.stdout)
                if match:
                    return f"{round(float(match.group(1)))} ms"
                match_rtt = re.search(r'rtt\s+min/avg/max/mdev\s*=\s*[\d\.]+/([\d\.]+)/', res.stdout)
                if match_rtt:
                    return f"{round(float(match_rtt.group(1)))} ms"
        except Exception:
            pass
    return "Timeout"

def get_bandwidth_details(interface):
    if not interface or interface == "None":
        return {
            "rx_speed": "0 B/s",
            "tx_speed": "0 B/s",
            "total_rx": "0 B",
            "total_tx": "0 B"
        }
        
    rx_path = f"/sys/class/net/{interface}/statistics/rx_bytes"
    tx_path = f"/sys/class/net/{interface}/statistics/tx_bytes"
    
    if not os.path.exists(rx_path) or not os.path.exists(tx_path):
        return {
            "rx_speed": "0 B/s",
            "tx_speed": "0 B/s",
            "total_rx": "0 B",
            "total_tx": "0 B"
        }
        
    try:
        with open(rx_path, "r") as f:
            rx_bytes = int(f.read().strip())
        with open(tx_path, "r") as f:
            tx_bytes = int(f.read().strip())
    except Exception:
        return {
            "rx_speed": "0 B/s",
            "tx_speed": "0 B/s",
            "total_rx": "0 B",
            "total_tx": "0 B"
        }
        
    import time
    current_time = time.time()
    
    def format_bytes(b):
        if b < 1024:
            return f"{b} B"
        elif b < 1024 * 1024:
            return f"{b / 1024:.1f} KB"
        elif b < 1024 * 1024 * 1024:
            return f"{b / (1024 * 1024):.1f} MB"
        else:
            return f"{b / (1024 * 1024 * 1024):.1f} GB"
            
    def format_speed(b_sec):
        if b_sec < 1024:
            return f"{b_sec:.0f} B/s"
        elif b_sec < 1024 * 1024:
            return f"{b_sec / 1024:.1f} KB/s"
        else:
            return f"{b_sec / (1024 * 1024):.1f} MB/s"
            
    total_rx_str = format_bytes(rx_bytes)
    total_tx_str = format_bytes(tx_bytes)
    
    cache_dir = os.path.expanduser("~/.cache")
    try:
        os.makedirs(cache_dir, mode=0o700, exist_ok=True)
    except Exception:
        pass
    cache_path = os.path.join(cache_dir, "org.fedora.networkwidget.state.json")
    rx_speed = 0.0
    tx_speed = 0.0
    
    try:
        cache_data = {}
        if os.path.exists(cache_path):
            with open(cache_path, "r") as f:
                cache_data = json.load(f)
                
        last_rx = cache_data.get("last_rx")
        last_tx = cache_data.get("last_tx")
        last_time = cache_data.get("last_time")
        last_interface = cache_data.get("last_interface")
        
        if (last_rx is not None and last_tx is not None and last_time is not None 
                and last_interface == interface and current_time > last_time):
            dt = current_time - last_time
            if dt > 0.1:
                diff_rx = rx_bytes - last_rx
                diff_tx = tx_bytes - last_tx
                if diff_rx >= 0 and diff_tx >= 0:
                    rx_speed = diff_rx / dt
                    tx_speed = diff_tx / dt
    except Exception:
        pass
        
    try:
        with open(cache_path, "w") as f:
            json.dump({
                "last_rx": rx_bytes,
                "last_tx": tx_bytes,
                "last_time": current_time,
                "last_interface": interface
            }, f)
    except Exception:
        pass
        
    return {
        "rx_speed": format_speed(rx_speed),
        "tx_speed": format_speed(tx_speed),
        "total_rx": total_rx_str,
        "total_tx": total_tx_str
    }

def get_extended_wifi_details(interface):
    if not interface or not interface.startswith("wl"):
        return None
    try:
        res = subprocess.run(["nmcli", "-t", "-f", "active,ssid,chan,freq,rate,signal,security", "dev", "wifi"], capture_output=True, text=True, errors="replace", check=True)
        for line in res.stdout.splitlines():
            if line.startswith("yes:"):
                parts = []
                current = []
                escaped = False
                for char in line:
                    if escaped:
                        current.append(char)
                        escaped = False
                    elif char == '\\':
                        escaped = True
                    elif char == ':':
                        parts.append("".join(current))
                        current = []
                    else:
                        current.append(char)
                parts.append("".join(current))
                
                if len(parts) >= 7:
                    active, ssid, chan, freq, rate, signal, security = parts[0], parts[1], parts[2], parts[3], parts[4], parts[5], parts[6]
                    freq_val = 0
                    match_freq = re.search(r'(\d+)', freq)
                    if match_freq:
                        freq_val = int(match_freq.group(1))
                    
                    band = "Unknown"
                    if 2400 <= freq_val <= 2500:
                        band = "2.4 GHz"
                    elif 5000 <= freq_val <= 6000:
                        band = "5 GHz"
                    elif 6000 <= freq_val <= 7200:
                        band = "6 GHz"
                    
                    return {
                        "ssid": ssid,
                        "channel": chan,
                        "frequency": freq,
                        "band": band,
                        "rate": rate,
                        "signal": signal,
                        "security": security if security else "Open"
                    }
    except Exception:
        pass
    return None

def get_geo_details():
    try:
        url = "http://ip-api.com/json/?fields=status,country,city,isp"
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req, timeout=1.5) as response:  # nosec B310
            data = json.loads(response.read().decode('utf-8', errors="replace"))
            if data.get("status") == "success":
                return {
                    "isp": data.get("isp", "Unknown"),
                    "city": data.get("city", "Unknown"),
                    "country": data.get("country", "Unknown")
                }
    except Exception:
        pass
    return {
        "isp": "Unknown",
        "city": "Unknown",
        "country": "Unknown"
    }

def is_ipv6_hidden_by_config():
    try:
        config_path = os.path.expanduser("~/.config/plasma-org.kde.plasma.desktop-appletsrc")
        if not os.path.exists(config_path):
            return False
            
        with open(config_path, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()
            
        # Find all applet ID sections matching org.fedora.networkwidget
        applet_ids = []
        sections = re.split(r'^\[', content, flags=re.MULTILINE)
        for sec in sections:
            if "plugin=org.fedora.networkwidget" in sec:
                match = re.search(r'Containments\]\[\d+\]\[Applets\]\[(\d+)\]', sec)
                if match:
                    applet_ids.append(match.group(1))
                    
        for applet_id in applet_ids:
            # Look for the corresponding General config section
            pattern = rf'\[Containments\]\[\d+\]\[Applets\]\[{applet_id}\]\[Configuration\]\[General\].*?\n(.*?)(?=\n\[|$)'
            match = re.search(pattern, content, re.DOTALL)
            if match:
                section_lines = match.group(1).splitlines()
                for line in section_lines:
                    if line.strip().startswith("showIPv6=false"):
                        return True
                    if line.strip().startswith("showIPv6=true"):
                        return False
    except Exception:
        pass
    return False

def main():
    parser = argparse.ArgumentParser(description="Network Info Helper")
    parser.add_argument("--json", action="store_true", help="Force JSON output format")
    parser.add_argument("--hide-ipv6", action="store_true", help="Hide IPv6 addresses")
    parser.add_argument("--show-ipv6", action="store_true", help="Force show IPv6 addresses")
    parser.add_argument("--show-latency", action="store_true", help="Show connection latency (Ping)")
    parser.add_argument("--show-bandwidth", action="store_true", help="Show real-time bandwidth")
    parser.add_argument("--show-mac", action="store_true", help="Show MAC address & Subnet CIDR")
    parser.add_argument("--show-extended-wifi", action="store_true", help="Show extended Wi-Fi info")
    parser.add_argument("--show-geo", action="store_true", help="Show ISP and Geolocation")
    args = parser.parse_args()

    iface = get_default_interface()
    local_ip = get_local_ip(iface, show_cidr=args.show_mac)
    gateway = get_default_gateway()
    dns = get_dns_servers(iface)
    ssid, signal = get_wifi_details(iface)
    lldp_details = get_lldp_details(iface)
    vpn_details = get_vpn_details()
    
    # Determine IPv6 visibility
    hide_ipv6_opt = args.hide_ipv6
    if not hide_ipv6_opt and not args.show_ipv6:
        hide_ipv6_opt = is_ipv6_hidden_by_config()
        
    local_ipv6 = "None" if hide_ipv6_opt else get_local_ipv6(iface, show_cidr=args.show_mac)
    
    public_ip = get_public_ip(ipv6=False)
    public_ipv6 = "None" if hide_ipv6_opt else get_public_ip(ipv6=True)
    
    # Fetch conditional advanced details
    latency = get_latency(gateway) if args.show_latency else "None"
    mac_address = get_mac_address(iface) if args.show_mac else "None"
    
    bandwidth = get_bandwidth_details(iface) if args.show_bandwidth else None
    rx_speed = bandwidth["rx_speed"] if bandwidth else "0 B/s"
    tx_speed = bandwidth["tx_speed"] if bandwidth else "0 B/s"
    total_rx = bandwidth["total_rx"] if bandwidth else "0 B"
    total_tx = bandwidth["total_tx"] if bandwidth else "0 B"
    
    ext_wifi = get_extended_wifi_details(iface) if args.show_extended_wifi else None
    wifi_band = ext_wifi["band"] if ext_wifi else "None"
    wifi_channel = ext_wifi["channel"] if ext_wifi else "None"
    wifi_rate = ext_wifi["rate"] if ext_wifi else "None"
    wifi_security = ext_wifi["security"] if ext_wifi else "None"
    
    geo = get_geo_details() if args.show_geo else None
    geo_isp = geo["isp"] if geo else "None"
    geo_city = geo["city"] if geo else "None"
    geo_country = geo["country"] if geo else "None"
    
    data = {
        "interface": iface or "None",
        "local_ip": local_ip or "None",
        "local_ipv6": "None" if hide_ipv6_opt else (local_ipv6 or "None"),
        "gateway": gateway or "None",
        "public_ip": public_ip,
        "public_ipv6": public_ipv6,
        "dns": dns,
        "wifi_ssid": ssid or "None",
        "wifi_signal": signal or "None",
        "lldp_active": lldp_details["lldp_active"] if lldp_details else False,
        "switch_name": lldp_details["switch_name"] if lldp_details else "None",
        "switch_port": lldp_details["switch_port"] if lldp_details else "None",
        "switch_mac": lldp_details["switch_mac"] if lldp_details else "None",
        "vpn_active": vpn_details["vpn_active"],
        "vpn_name": vpn_details["vpn_name"],
        "vpn_type": vpn_details["vpn_type"],
        # Advanced details
        "latency": latency,
        "mac_address": mac_address,
        "rx_speed": rx_speed,
        "tx_speed": tx_speed,
        "total_rx": total_rx,
        "total_tx": total_tx,
        "wifi_band": wifi_band,
        "wifi_channel": wifi_channel,
        "wifi_rate": wifi_rate,
        "wifi_security": wifi_security,
        "geo_isp": geo_isp,
        "geo_city": geo_city,
        "geo_country": geo_country
    }
    
    # Default behavior: print JSON if not a TTY or if requested, otherwise print human-readable
    if args.json or not sys.stdout.isatty():
        print(json.dumps(data))
    else:
        # Beautiful, human-readable terminal output
        use_colors = sys.stdout.isatty()
        GREEN = "\033[92m" if use_colors else ""
        RED = "\033[91m" if use_colors else ""
        BOLD = "\033[1m" if use_colors else ""
        RESET = "\033[0m" if use_colors else ""
        
        print(f"{BOLD}{GREEN}=== Network Information ==={RESET}")
        
        iface_str = data["interface"]
        if iface_str == "None":
            iface_str = f"{RED}None{RESET}"
        elif data["wifi_ssid"] != "None":
            iface_str += f" (SSID: {data['wifi_ssid']}, Signal: {data['wifi_signal']}%)"
        # codeql[py/clear-text-logging-sensitive-data]
        print(f"{BOLD}Interface:{RESET}       {iface_str}")
        
        if data["lldp_active"]:
            # codeql[py/clear-text-logging-sensitive-data]
            print(f"{BOLD}Switch Port:{RESET}     {data['switch_port']} (on {data['switch_name']})")
            # codeql[py/clear-text-logging-sensitive-data]
            print(f"{BOLD}Switch MAC:{RESET}      {data['switch_mac']}")
            
        if args.show_extended_wifi and data["wifi_ssid"] != "None" and data["wifi_band"] != "None":
            # codeql[py/clear-text-logging-sensitive-data]
            print(f"{BOLD}Wi-Fi Details:{RESET}   {data['wifi_band']}, Ch {data['wifi_channel']}, {data['wifi_security']}, {data['wifi_rate']}")
            
        # codeql[py/clear-text-logging-sensitive-data]
        print(f"{BOLD}Local IPv4:{RESET}      {data['local_ip']}")
        if data["gateway"] != "None":
            # codeql[py/clear-text-logging-sensitive-data]
            print(f"{BOLD}Default Gateway:{RESET} {data['gateway']}")
            
        if not hide_ipv6_opt and data["local_ipv6"] != "None":
            # codeql[py/clear-text-logging-sensitive-data]
            print(f"{BOLD}Local IPv6:{RESET}      {data['local_ipv6']}")
            
        if args.show_mac and data["mac_address"] != "None":
            # codeql[py/clear-text-logging-sensitive-data]
            print(f"{BOLD}MAC Address:{RESET}     {data['mac_address']}")
            
        if data["vpn_active"]:
            # codeql[py/clear-text-logging-sensitive-data]
            print(f"{BOLD}VPN:{RESET}             Active ({data['vpn_name']})")
        else:
            print(f"{BOLD}VPN:{RESET}             Disconnected")
            
        pub_ip = data["public_ip"]
        if pub_ip == "Offline":
            pub_ip = f"{RED}Offline{RESET}"
        # codeql[py/clear-text-logging-sensitive-data]
        print(f"{BOLD}Public IPv4:{RESET}     {pub_ip}")
        
        if not hide_ipv6_opt and data["public_ipv6"] not in ["None", "Offline"]:
            # codeql[py/clear-text-logging-sensitive-data]
            print(f"{BOLD}Public IPv6:{RESET}     {data['public_ipv6']}")
            
        if args.show_geo and data["geo_isp"] != "None":
            # codeql[py/clear-text-logging-sensitive-data]
            print(f"{BOLD}ISP:{RESET}             {data['geo_isp']}")
            # codeql[py/clear-text-logging-sensitive-data]
            print(f"{BOLD}Location:{RESET}        {data['geo_city']}, {data['geo_country']}")
            
        if data["dns"]:
            # codeql[py/clear-text-logging-sensitive-data]
            print(f"{BOLD}DNS Servers:{RESET}     {', '.join(data['dns'])}")
        else:
            print(f"{BOLD}DNS Servers:{RESET}     None")
            
        if args.show_latency:
            print(f"{BOLD}Latency:{RESET}         {data['latency']}")
            
        if args.show_bandwidth:
            print(f"{BOLD}Bandwidth:{RESET}       Rx: {data['rx_speed']}, Tx: {data['tx_speed']}")
            print(f"{BOLD}Session Data:{RESET}    Down: {data['total_rx']}, Up: {data['total_tx']}")

if __name__ == "__main__":
    main()
