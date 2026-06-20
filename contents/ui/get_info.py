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

def get_dns_servers(interface):
    dns_servers = []
    if not interface:
        return dns_servers
    try:
        # Try nmcli first
        res = subprocess.run(["nmcli", "dev", "show", interface], capture_output=True, text=True, errors="replace", check=True)
        for line in res.stdout.splitlines():
            if "IP4.DNS" in line:
                parts = line.split(":", 1)
                if len(parts) == 2:
                    dns_servers.append(parts[1].strip())
    except Exception:
        pass
    
    if not dns_servers:
        try:
            res = subprocess.run(["resolvectl", "dns", interface], capture_output=True, text=True, errors="replace", check=True)
            ips = re.findall(r'\d+\.\d+\.\d+\.\d+', res.stdout)
            dns_servers.extend(ips)
        except Exception:
            pass
    return dns_servers

def get_public_ip():
    urls = [
        "https://api.ipify.org",
        "https://icanhazip.com",
        "https://ifconfig.me/ip"
    ]
    for url in urls:
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req, timeout=2.0) as response:
                ip = response.read().decode('utf-8', errors="replace").strip()
                if re.match(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$', ip):
                    return ip
        except Exception:
            continue
    return "Offline"

def main():
    iface = get_default_interface()
    local_ip = get_local_ip(iface)
    dns = get_dns_servers(iface)
    public_ip = get_public_ip()
    
    data = {
        "interface": iface or "None",
        "local_ip": local_ip or "None",
        "public_ip": public_ip,
        "dns": dns
    }
    print(json.dumps(data))

if __name__ == "__main__":
    main()
