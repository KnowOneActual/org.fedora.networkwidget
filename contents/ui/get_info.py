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


def get_local_ip(interface):
    if not interface:
        return None
    try:
        res = subprocess.run(["ip", "-4", "addr", "show", interface], capture_output=True, text=True, errors="replace", check=True)
        match = re.search(r'inet\s+(\d+\.\d+\.\d+\.\d+)', res.stdout)
        if match:
            return match.group(1)
    except Exception:
        pass
    return None

def get_local_ipv6(interface):
    if not interface:
        return None
    try:
        res = subprocess.run(["ip", "-6", "addr", "show", interface], capture_output=True, text=True, errors="replace", check=True)
        for line in res.stdout.splitlines():
            if "inet6" in line and "scope global" in line:
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
            with urllib.request.urlopen(req, timeout=2.0) as response:
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
    args = parser.parse_args()

    iface = get_default_interface()
    local_ip = get_local_ip(iface)
    gateway = get_default_gateway()
    dns = get_dns_servers(iface)
    ssid, signal = get_wifi_details(iface)
    
    # Determine IPv6 visibility
    hide_ipv6_opt = args.hide_ipv6
    if not hide_ipv6_opt and not args.show_ipv6:
        hide_ipv6_opt = is_ipv6_hidden_by_config()
        
    local_ipv6 = "None" if hide_ipv6_opt else get_local_ipv6(iface)
    
    public_ip = get_public_ip(ipv6=False)
    public_ipv6 = "None" if hide_ipv6_opt else get_public_ip(ipv6=True)
    
    data = {
        "interface": iface or "None",
        "local_ip": local_ip or "None",
        "local_ipv6": "None" if hide_ipv6_opt else (local_ipv6 or "None"),
        "gateway": gateway or "None",
        "public_ip": public_ip,
        "public_ipv6": public_ipv6,
        "dns": dns,
        "wifi_ssid": ssid or "None",
        "wifi_signal": signal or "None"
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
        print(f"{BOLD}Interface:{RESET}       {iface_str}")
        
        print(f"{BOLD}Local IPv4:{RESET}      {data['local_ip']}")
        if data["gateway"] != "None":
            print(f"{BOLD}Default Gateway:{RESET} {data['gateway']}")
            
        if not hide_ipv6_opt and data["local_ipv6"] != "None":
            print(f"{BOLD}Local IPv6:{RESET}      {data['local_ipv6']}")
            
        pub_ip = data["public_ip"]
        if pub_ip == "Offline":
            pub_ip = f"{RED}Offline{RESET}"
        print(f"{BOLD}Public IPv4:{RESET}     {pub_ip}")
        
        if not hide_ipv6_opt and data["public_ipv6"] not in ["None", "Offline"]:
            print(f"{BOLD}Public IPv6:{RESET}     {data['public_ipv6']}")
            
        if data["dns"]:
            print(f"{BOLD}DNS Servers:{RESET}     {', '.join(data['dns'])}")
        else:
            print(f"{BOLD}DNS Servers:{RESET}     None")

if __name__ == "__main__":
    main()
