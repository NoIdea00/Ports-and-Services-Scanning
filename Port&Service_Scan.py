#!/usr/bin/env python3

import os
import re
import sys
import subprocess
from datetime import datetime

scanned_targets = []
scan_count = 0
scan_with_ports = 0

def is_valid_ip(ip):
    pattern = r"^(\d{1,3}\.){3}\d{1,3}$"
    if not re.match(pattern, ip):
        return False
    parts = ip.split('.')
    return all(0 <= int(part) <= 255 for part in parts)

def is_valid_domain(domain):
    pattern = r"^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$"
    return re.match(pattern, domain) is not None

def print_help():
    print(f"Usage: {sys.argv[0]} <target> | -f <target_file> | -h")
    print()
    print("  <target>          - Scan a single target domain or IP address.")
    print("  -f <target_file>  - Scan multiple targets from a file.")
    print("  -h, --help        - Display this help message.")
    print()
    print("Example:")
    print(f"  {sys.argv[0]} example.com")
    print(f"  {sys.argv[0]} -f targets.txt")
    sys.exit(0)

def log(message, logfile):
    timestamp = datetime.now().strftime('%H:%M:%S')
    line = f"[{timestamp}] {message}"
    print(line)
    with open(logfile, 'a') as f:
        f.write(line + '\n')

def run_scan(target):
    global scan_with_ports
    timestamp = datetime.now().strftime('%Y%m%d-%H%M')
    scan_dir = os.path.join("scans", target, timestamp)
    naabu_output = os.path.join(scan_dir, "naabu.txt")
    nmap_output = os.path.join(scan_dir, "nmap.txt")
    log_file = os.path.join(scan_dir, "scan.log")

    os.makedirs(scan_dir, exist_ok=True)

    log(f"[*] Running Naabu on {target}...", log_file)
    try:
        result = subprocess.run(["naabu", "-host", target, "-p", "80,81,8000,8080,8888,3000,5000,10000,2082,2095", "-silent"],
                        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, check=True, text=True)
        print(result.stdout)  # Show output in terminal
        with open(naabu_output, 'w') as out:
            out.write(result.stdout)
    except subprocess.CalledProcessError:
        log("[-] Naabu failed to run.", log_file)
        return False

    if os.path.getsize(naabu_output) == 0:
        log("[-] No open ports found by Naabu.", log_file)
        return False

    with open(naabu_output, 'r') as f:
        ports = []
        for line in f:
            parts = line.strip().split(":")
            if len(parts) == 2:
                ports.append(parts[1])
            elif len(parts) == 1:
                ports.append(parts[0])  # fallback if no colon

    port_str = ",".join(ports)
    log(f"[*] Running Nmap on {target} with ports: {port_str}", log_file)
    try:
        subprocess.run(["nmap", "-sS", "-sV", "-Pn", "-p", port_str, "-oN", nmap_output, target],
                       stderr=subprocess.STDOUT, check=True)
    except subprocess.CalledProcessError:
        log("[-] Nmap failed to run.", log_file)
        return False

    log(f"[+] Scan complete:", log_file)
    log(f"    - Naabu output: {naabu_output}", log_file)
    log(f"    - Nmap output:  {nmap_output}", log_file)
    log(f"    - Log file:     {log_file}", log_file)
    scan_with_ports += 1
    return True


def print_summary():
    print("\n[+] Summary Report")
    print(f"    Total scans completed: {scan_count}")
    print(f"    Total with open ports: {scan_with_ports}")
    print("\n[+] Detailed Scan Results:")
    for target in scanned_targets:
        print(f"    - Target: {target}")
        print(f"      Naabu Output: scans/{target}/*/naabu.txt")
        print(f"      Nmap Output:  scans/{target}/*/nmap.txt")
        print(f"      Log File:     scans/{target}/*/scan.log")


    
def compile_nmap_results():
    choice = input("\n[?] Do you want to compile all Nmap results into one file? (y/n): ").strip().lower()
    if choice != 'y':
        return

    compiled_file = "compiled_nmap_results.txt"
    with open(compiled_file, 'w') as outfile:
        outfile.write(f"# Compiled Nmap Results - {datetime.now()}\n\n")
        for target in scanned_targets:
            target_dir = os.path.join("scans", target)
            if not os.path.exists(target_dir):
                continue
            for root, dirs, files in os.walk(target_dir):
                for file in files:
                    if file == "nmap.txt":
                        filepath = os.path.join(root, file)
                        outfile.write(f"## {target} - {filepath}\n")
                        with open(filepath, 'r') as infile:
                            outfile.write(infile.read())
                            outfile.write("\n" + "#" * 60 + "\n\n")
    print(f"[+] Compiled Nmap results saved to: {compiled_file}")

def main():
    global scan_count
    if len(sys.argv) < 2:
        print_help()

    arg = sys.argv[1]

    if arg in ("-h", "--help"):
        print_help()
    elif arg == "-f":
        if len(sys.argv) < 3:
            print("[-] Please provide a file path.")
            sys.exit(1)

        filepath = sys.argv[2]
        if not os.path.isfile(filepath):
            print(f"[-] File '{filepath}' not found.")
            sys.exit(1)

        with open(filepath, 'r') as file:
            for line in file:
                target = line.strip()
                if not target:
                    continue
                if is_valid_ip(target) or is_valid_domain(target):
                    scan_count += 1
                    scanned_targets.append(target)
                    run_scan(target)
                else:
                    print(f"[-] Invalid input: '{target}' is not a valid IP or domain.")
    else:
        target = arg
        if is_valid_ip(target) or is_valid_domain(target):
            scan_count += 1
            scanned_targets.append(target)
            run_scan(target)
        else:
            print(f"[-] Invalid input: '{target}' is not a valid IP or domain.")
            sys.exit(1)

    print_summary()
    compile_nmap_results()


if __name__ == "__main__":
    main()
