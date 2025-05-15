#!/bin/bash

print_help() {
    echo "Usage: $0 <target> | -f <target_file> | -h"
    echo
    echo "  <target>          - Scan a single domain or IP."
    echo "  -f <target_file>  - Scan multiple targets from a file."
    echo "  -h, --help        - Show this help message."
    echo
    echo "Example:"
    echo "  $0 example.com"
    echo "  $0 -f targets.txt"
    exit 0
}

is_valid_ip() {
    [[ $1 =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] && {
        IFS='.' read -r o1 o2 o3 o4 <<< "$1"
        [[ $o1 -le 255 && $o2 -le 255 && $o3 -le 255 && $o4 -le 255 ]]
    }
}

is_valid_domain() {
    [[ $1 =~ ^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$ ]]
}

run_scan() {
    local target="$1"
    local timestamp
    timestamp=$(date +%Y%m%d-%H%M)
    local scan_dir="scans/$target/$timestamp"
    local naabu_output="$scan_dir/naabu.txt"
    local nmap_output="$scan_dir/nmap.txt"
    local log_file="$scan_dir/scan.log"

    mkdir -p "$scan_dir"

    echo "[*] $(date +%T) Running Naabu on $target..." | tee -a "$log_file"
    if naabu -host "$target" -p 80,81,8000,8080,8888,3000,5000,10000,2082,2095 -silent > "$naabu_output"; then
        cat "$naabu_output"
    else
        echo "[-] $(date +%T) Naabu failed to run." | tee -a "$log_file"
        return 1
    fi

    if [[ ! -s "$naabu_output" ]]; then
        echo "[-] $(date +%T) No open ports found by Naabu." | tee -a "$log_file"
        return 1
    fi

    ports=$(awk -F: '{print $2 ? $2 : $1}' "$naabu_output" | paste -sd, -)

    echo "[*] $(date +%T) Running Nmap on $target with ports: $ports" | tee -a "$log_file"
    if nmap -sS -sV -Pn -p "$ports" -oN "$nmap_output" "$target"; then
        echo "[+] $(date +%T) Scan complete:" | tee -a "$log_file"
        echo "    - Naabu output: $naabu_output" | tee -a "$log_file"
        echo "    - Nmap output:  $nmap_output" | tee -a "$log_file"
        echo "    - Log file:     $log_file" | tee -a "$log_file"
    else
        echo "[-] $(date +%T) Nmap failed to run." | tee -a "$log_file"
    fi
}

compile_nmap_results() {
    read -rp $'\n[?] Do you want to compile all Nmap results into one file? (y/n): ' choice
    [[ "$choice" != "y" ]] && return

    output="compiled_nmap_results.txt"
    echo "# Compiled Nmap Results - $(date)" > "$output"

    find scans -type f -name "nmap.txt" | while read -r file; do
        echo -e "\n## $(dirname "$file")\n" >> "$output"
        cat "$file" >> "$output"
        echo -e "\n############################################################\n" >> "$output"
    done

    echo "[+] Compiled Nmap results saved to: $output"
}

main() {
    [[ $# -lt 1 ]] && print_help

    arg="$1"
    scan_count=0
    scan_with_ports=0
    scanned_targets=()

    if [[ "$arg" == "-h" || "$arg" == "--help" ]]; then
        print_help
    elif [[ "$arg" == "-f" ]]; then
        [[ $# -lt 2 ]] && { echo "[-] Please provide a file path."; exit 1; }
        file="$2"
        [[ ! -f "$file" ]] && { echo "[-] File '$file' not found."; exit 1; }

        while read -r target; do
            target=$(echo "$target" | xargs)
            [[ -z "$target" ]] && continue

            if is_valid_ip "$target" || is_valid_domain "$target"; then
                scanned_targets+=("$target")
                ((scan_count++))
                run_scan "$target" && ((scan_with_ports++))
            else
                echo "[-] Invalid input: '$target' is not a valid IP or domain."
            fi
        done < "$file"
    else
        target="$arg"
        if is_valid_ip "$target" || is_valid_domain "$target"; then
            scanned_targets+=("$target")
            ((scan_count++))
            run_scan "$target" && ((scan_with_ports++))
        else
            echo "[-] Invalid input: '$target' is not a valid IP or domain."
            exit 1
        fi
    fi

    echo -e "\n[+] Summary Report"
    echo "    Total scans completed: $scan_count"
    echo "    Total with open ports: $scan_with_ports"
    echo -e "\n[+] Detailed Scan Results:"
    for target in "${scanned_targets[@]}"; do
        echo "    - Target: $target"
        echo "      Naabu Output: scans/$target/*/naabu.txt"
        echo "      Nmap Output:  scans/$target/*/nmap.txt"
        echo "      Log File:     scans/$target/*/scan.log"
    done

    compile_nmap_results
}

main "$@"
