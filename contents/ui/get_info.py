#!/usr/bin/env python3
import subprocess
import re
import json
import urllib.request

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

def main():
    iface = get_default_interface()
    local_ip = get_local_ip(iface)
    local_ipv6 = get_local_ipv6(iface)
    gateway = get_default_gateway()
    dns = get_dns_servers(iface)
    public_ip = get_public_ip(ipv6=False)
    public_ipv6 = get_public_ip(ipv6=True)
    ssid, signal = get_wifi_details(iface)
    
    data = {
        "interface": iface or "None",
        "local_ip": local_ip or "None",
        "local_ipv6": local_ipv6 or "None",
        "gateway": gateway or "None",
        "public_ip": public_ip,
        "public_ipv6": public_ipv6,
        "dns": dns,
        "wifi_ssid": ssid or "None",
        "wifi_signal": signal or "None"
    }
    print(json.dumps(data))

if __name__ == "__main__":
    main()
