#!/bin/bash

# Function to validate IP address (IPv4)
is_valid_ip() {
  local ip=$1
  if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
    # Ensure that each octet is between 0 and 255
    IFS='.' read -r -a octets <<< "$ip"
    if [ "${octets[0]}" -le 255 ] && [ "${octets[1]}" -le 255 ] && [ "${octets[2]}" -le 255 ] && [ "${octets[3]}" -le 255 ]; then
      return 0
    fi
  fi
  return 1
}

# Function to validate domain name
is_valid_domain() {
  local domain=$1
  if [[ "$domain" =~ ^([a-zA-Z0-9-]+\.)+[a-zA-Z]{2,}$ ]]; then
    return 0
  fi
  return 1
}

print_help() {
  echo "Usage: $0 <target> | -f <target_file> | -h"
  echo
  echo "  <target>          - Scan a single target domain or IP address."
  echo "  -f <target_file>  - Scan multiple targets from a file (one domain/IP per line)."
  echo "  -h, --help        - Display this help message."
  echo
  echo "Example usage:"
  echo "  $0 example.com"
  echo "  $0 -f targets.txt"
  echo "  targets.txt contains one domain or IP per line (e.g., google.com, 192.168.1.1)."
  exit 0
}

run_scan() {
  local TARGET=$1
  local TIMESTAMP=$(date '+%Y%m%d-%H%M')
  local SCAN_DIR="scans/$TARGET/$TIMESTAMP"
  local NAABU_OUTPUT="$SCAN_DIR/naabu.txt"
  local NMAP_OUTPUT="$SCAN_DIR/nmap.txt"
  local LOG_FILE="$SCAN_DIR/scan.log"

  mkdir -p "$SCAN_DIR"

  log() {
    echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"
  }

  log "[*] Running Naabu on $TARGET..."
  naabu -host "$TARGET" -silent -o "$NAABU_OUTPUT" 2>&1 | tee -a "$LOG_FILE"

  if [ ! -s "$NAABU_OUTPUT" ]; then
    log "[-] No open ports found by Naabu."
    return 1
  fi

  PORTS=$(cut -d: -f2 "$NAABU_OUTPUT" | paste -sd, -)

  log "[*] Running Nmap on $TARGET with ports: $PORTS"
  nmap -sS -sV -Pn -p "$PORTS" -oN "$NMAP_OUTPUT" "$TARGET" 2>&1 | tee -a "$LOG_FILE"

  log "[+] Scan complete:"
  log "    - Naabu output: $NAABU_OUTPUT"
  log "    - Nmap output:  $NMAP_OUTPUT"
  log "    - Log file:     $LOG_FILE"

  return 0
}

print_summary() {
  echo "[+] Summary Report"
  echo "    Total scans completed: $SCAN_COUNT"
  
  echo
  echo "[+] Detailed Scan Results:"
  for TARGET in "${SCANNED_TARGETS[@]}"; do
    echo "    - Target: $TARGET"
    echo "      Naabu Output: ${TARGET}_naabu.txt"
    echo "      Nmap Output:  ${TARGET}_nmap.txt"
    echo "      Log File:     ${TARGET}_scan.log"
  done
}

# Main logic
SCAN_COUNT=0
SCAN_WITH_PORTS=0
SCANNED_TARGETS=()

if [[ "$1" = "-h" || "$1" = "--help" ]]; then
  print_help
elif [ "$1" = "-f" ] && [ -n "$2" ]; then
  FILE="$2"
  if [ ! -f "$FILE" ]; then
    echo "[-] File '$FILE' not found."
    exit 1
  fi
  while IFS= read -r target || [ -n "$target" ]; do
    [ -z "$target" ] && continue
    if is_valid_ip "$target" || is_valid_domain "$target"; then
      SCAN_COUNT=$((SCAN_COUNT + 1))
      SCANNED_TARGETS+=("$target")
      if run_scan "$target"; then
        SCAN_WITH_PORTS=$((SCAN_WITH_PORTS + 1))
      fi
    else
      echo "[-] Invalid input: '$target' is neither a valid IP address nor domain."
    fi
  done < "$FILE"
elif [ -n "$1" ]; then
  if is_valid_ip "$1" || is_valid_domain "$1"; then
    SCAN_COUNT=1
    SCANNED_TARGETS+=("$1")
    if run_scan "$1"; then
      SCAN_WITH_PORTS=1
    fi
  else
    echo "[-] Invalid input: '$1' is neither a valid IP address nor domain."
    exit 1
  fi
else
  echo "Usage:"
  echo "  $0 <target>"
  echo "  $0 -f <target_file>"
  echo "  $0 -h | --help"
  exit 1
fi

print_summary
