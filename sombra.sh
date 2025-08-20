#!/bin/bash

#################################################
# 💜 SOMBRA - Network Infiltrator
# Author: [m0uras]
# Version: 2.0
# Description: "Everything can be hacked... and everyone."
#              Advanced network reconnaissance and host discovery tool
# Usage: ./sombra.sh <network_cidr> [options]
#################################################

# Color codes for better output (Sombra themed)
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'      
readonly CYAN='\033[0;36m'        
readonly MAGENTA='\033[1;35m'     
readonly GRAY='\033[0;37m'        
readonly NC='\033[0m'

# Configuration variables
readonly SCRIPT_NAME=$(basename "$0")
readonly TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
readonly OUTPUT_DIR="scan_results_${TIMESTAMP}"
readonly HOSTS_FILE="${OUTPUT_DIR}/active_hosts.txt"
readonly LOG_FILE="${OUTPUT_DIR}/scan.log"

# Default values
VERBOSE=false
FAST_SCAN=false
OUTPUT_FORMAT="txt"

#################################################
# Functions
#################################################

# Print colored messages (Sombra themed)
print_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

print_success() {
    echo -e "${CYAN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${MAGENTA}[WARNING]${NC} $1"
}

print_info() {
    echo -e "${PURPLE}[INFO]${NC} $1"
}

print_hack() {
    echo -e "${CYAN}[HACKING]${NC} $1"
}

# Logging function
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# Display help
show_help() {
    echo -e "${PURPLE}💜 SOMBRA - Network Infiltrator v2.0${NC}"
    echo -e "${CYAN}\"Everything can be hacked... and everyone.\"${NC}"
    echo
    echo -e "${MAGENTA}USAGE:${NC}"
    echo "    $SCRIPT_NAME <network_cidr> [options]"
    echo
    echo -e "${MAGENTA}ARGUMENTS:${NC}"
    echo "    network_cidr    Network in CIDR notation (e.g., 192.168.1.0/24)"
    echo
    echo -e "${MAGENTA}OPTIONS:${NC}"
    echo "    -v, --verbose   Enable verbose output"
    echo "    -f, --fast      Use fast scan mode (less comprehensive)"
    echo "    -o, --output    Output format: txt, csv, json (default: txt)"
    echo "    -h, --help      Show this help message"
    echo
    echo -e "${MAGENTA}EXAMPLES:${NC}"
    echo "    $SCRIPT_NAME 192.168.1.0/24"
    echo "    $SCRIPT_NAME 10.0.0.0/8 --verbose --fast"
    echo "    $SCRIPT_NAME 172.16.0.0/12 -o csv"
    echo
    echo -e "${MAGENTA}OUTPUT:${NC}"
    echo "    Results are saved in: ${OUTPUT_DIR}/"
    echo "    - active_hosts.txt: List of discovered hosts"
    echo "    - scan.log: Detailed scan log"
}


# Validate dependencies
check_dependencies() {
    local deps=("nmap" "awk" "grep")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        print_info "Please install missing tools and try again"
        exit 1
    fi
}

# Validate CIDR notation
validate_cidr() {
    local network="$1"
    
    # Enhanced regex for CIDR validation
    if [[ ! "$network" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]{1,2}$ ]]; then
        print_error "Invalid CIDR notation: $network"
        print_info "Please use format: x.x.x.x/y (e.g., 192.168.1.0/24)"
        return 1
    fi
    
    # Validate IP octets (0-255) and subnet mask (0-32)
    IFS='/' read -r ip mask <<< "$network"
    IFS='.' read -ra octets <<< "$ip"
    
    for octet in "${octets[@]}"; do
        if [ "$octet" -lt 0 ] || [ "$octet" -gt 255 ]; then
            print_error "Invalid IP address in CIDR: $network"
            return 1
        fi
    done
    
    if [ "$mask" -lt 0 ] || [ "$mask" -gt 32 ]; then
        print_error "Invalid subnet mask in CIDR: $network (must be 0-32)"
        return 1
    fi
    
    return 0
}

# Create output directory
setup_output_dir() {
    if ! mkdir -p "$OUTPUT_DIR"; then
        print_error "Failed to create output directory: $OUTPUT_DIR"
        exit 1
    fi
    log_message "Created output directory: $OUTPUT_DIR"
}

# Perform host discovery
discover_hosts() {
    local network="$1"
    local nmap_opts="-sn"
    
    if [ "$FAST_SCAN" = true ]; then
        nmap_opts+=" -T4 --min-parallelism 100"
        print_hack "Initiating fast infiltration mode..."
    else
        nmap_opts+=" -T3"
    fi
    
    print_hack "Infiltrating network: $network"
    print_info "Scanning for vulnerable targets..."
    log_message "Starting nmap scan: nmap $nmap_opts $network"
    
    # Execute nmap scan
    if [ "$VERBOSE" = true ]; then
        nmap $nmap_opts "$network" | tee >(grep "Nmap scan report for" | awk '{print $5}' > "$HOSTS_FILE")
    else
        nmap $nmap_opts "$network" > "${OUTPUT_DIR}/raw_scan.txt" 2>&1
        grep "Nmap scan report for" "${OUTPUT_DIR}/raw_scan.txt" | awk '{print $5}' > "$HOSTS_FILE"
    fi
    
    local exit_code=${PIPESTATUS[0]}
    if [ $exit_code -ne 0 ]; then
        print_error "Nmap scan failed with exit code: $exit_code"
        log_message "Nmap scan failed with exit code: $exit_code"
        return 1
    fi
}

# Process and format results
process_results() {
    local host_count
    
    if [ ! -f "$HOSTS_FILE" ] || [ ! -s "$HOSTS_FILE" ]; then
        print_warning "No targets detected... they're good at hiding"
        log_message "No active hosts found"
        return 1
    fi
    
    host_count=$(wc -l < "$HOSTS_FILE")
    print_success "Hacked into $host_count target(s) successfully!"
    print_info "All systems compromised and catalogued"
    log_message "Found $host_count active hosts"
    
    # Generate additional output formats
    case "$OUTPUT_FORMAT" in
        "csv")
            {
                echo "IP_Address,Scan_Time"
                while read -r host; do
                    echo "$host,$TIMESTAMP"
                done < "$HOSTS_FILE"
            } > "${OUTPUT_DIR}/active_hosts.csv"
            print_info "CSV output saved to: ${OUTPUT_DIR}/active_hosts.csv"
            ;;
        "json")
            {
                echo "{"
                echo "  \"scan_info\": {"
                echo "    \"timestamp\": \"$TIMESTAMP\","
                echo "    \"network\": \"$1\","
                echo "    \"host_count\": $host_count"
                echo "  },"
                echo "  \"hosts\": ["
                local first=true
                while read -r host; do
                    if [ "$first" = true ]; then
                        first=false
                    else
                        echo ","
                    fi
                    echo -n "    \"$host\""
                done < "$HOSTS_FILE"
                echo ""
                echo "  ]"
                echo "}"
            } > "${OUTPUT_DIR}/active_hosts.json"
            print_info "JSON output saved to: ${OUTPUT_DIR}/active_hosts.json"
            ;;
    esac
    
    print_info "Results saved to: $OUTPUT_DIR"
    
    # Display first few hosts if verbose
    if [ "$VERBOSE" = true ] && [ "$host_count" -gt 0 ]; then
        print_info "First 10 compromised targets:"
        head -10 "$HOSTS_FILE" | while read -r host; do
            echo -e "  ${CYAN}→${NC} $host ${GRAY}[HACKED]${NC}"
        done
    fi
}

# Cleanup function
cleanup() {
    log_message "Script execution completed"
    if [ "$VERBOSE" = true ]; then
        print_info "Scan completed. Check $OUTPUT_DIR for detailed results"
    fi
}

#################################################
# Main Script Logic
#################################################

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -f|--fast)
            FAST_SCAN=true
            shift
            ;;
        -o|--output)
            OUTPUT_FORMAT="$2"
            if [[ ! "$OUTPUT_FORMAT" =~ ^(txt|csv|json)$ ]]; then
                print_error "Invalid output format: $OUTPUT_FORMAT"
                print_info "Supported formats: txt, csv, json"
                exit 1
            fi
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
        *)
            if [ -z "$NETWORK" ]; then
                NETWORK="$1"
            else
                print_error "Too many arguments"
                show_help
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if network argument is provided
if [ -z "$NETWORK" ]; then
    print_error "Network argument is required"
    show_help
    exit 1
fi

# Set trap for cleanup
trap cleanup EXIT

# Main execution flow
print_hack "💜 SOMBRA v2.0 - Initiating infiltration protocols..."
print_info "\"Apagando las luces...\" - Going dark"

# Validate dependencies
check_dependencies

# Validate CIDR notation
if ! validate_cidr "$NETWORK"; then
    exit 1
fi

# Setup output directory
setup_output_dir

# Perform host discovery
if discover_hosts "$NETWORK"; then
    process_results "$NETWORK"
else
    print_error "Host discovery failed"
    exit 1
fi