#!/bin/bash

#################################################
# 💜 SOMBRA - Reconnaissance Orchestrator v3.0
# Author: [Seu Nome]
# Description: Intelligent reconnaissance automation
# Usage: ./sombra.sh <target> [options]
#################################################

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[1;35m'
readonly GRAY='\033[0;37m'
readonly NC='\033[0m'

SCRIPT_NAME=$(basename "$0")
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
OUTPUT_DIR="sombra_recon_${TIMESTAMP}"
RESULTS_DIR="${OUTPUT_DIR}/results"
REPORTS_DIR="${OUTPUT_DIR}/reports"
EVIDENCE_DIR="${OUTPUT_DIR}/evidence"

AGGRESSIVE_MODE=false
STEALTH_MODE=false
VERBOSE=false
TARGET=""

RUN_DISCOVERY=true
RUN_SERVICE_DETECTION=true
RUN_SMART_TESTING=true
RUN_VULN_SCAN=true
RUN_REPORT=true

TEST_HTTP=true
TEST_SSH=true
TEST_FTP=true
TEST_SMB=true
TEST_DNS=true
TEST_DATABASE=true

#################################################
# Service testing rules (Bash 3.2 compatible)
#################################################
get_service_test() {
    local port=$1
    case $port in
        80) echo "http_tests" ;;
        443|8443) echo "https_tests" ;;
        21) echo "ftp_tests" ;;
        22) echo "ssh_tests" ;;
        23) echo "telnet_tests" ;;
        25) echo "smtp_tests" ;;
        53) echo "dns_tests" ;;
        110) echo "pop3_tests" ;;
        143) echo "imap_tests" ;;
        445) echo "smb_tests" ;;
        993) echo "imaps_tests" ;;
        995) echo "pop3s_tests" ;;
        1433) echo "mssql_tests" ;;
        3306) echo "mysql_tests" ;;
        5432) echo "postgresql_tests" ;;
        6379) echo "redis_tests" ;;
        *) echo "" ;;
    esac
}

#################################################
# Core Functions
#################################################
print_banner() {
    echo -e "${PURPLE}\
   ███████  ██████  ███    ███ ██████  ██████   █████  
   ██      ██    ██ ████  ████ ██   ██ ██   ██ ██   ██ 
   ███████ ██    ██ ██ ████ ██ ██████  ██████  ███████ 
        ██ ██    ██ ██  ██  ██ ██   ██ ██   ██ ██   ██ 
   ███████  ██████  ██      ██ ██████  ██   ██ ██   ██ 
   R E C O N N A I S S A N C E   O R C H E S T R A T O R${NC}
${CYAN}\"Heh, did I scare you?\"${NC}\n"
}


print_error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
print_success() { echo -e "${CYAN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${MAGENTA}[WARNING]${NC} $1"; }
print_info() { echo -e "${PURPLE}[INFO]${NC} $1"; }
print_hack() { echo -e "${CYAN}[HACKING]${NC} $1"; }
print_vuln() { echo -e "${RED}[VULN]${NC} $1"; }

log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "${OUTPUT_DIR}/orchestrator.log"
}

show_help() {
    echo -e "${PURPLE}💜 SOMBRA - Reconnaissance Orchestrator v3.0${NC}\n"

    echo -e "${MAGENTA}USAGE:${NC}"
    echo -e "    $SCRIPT_NAME <target> [options]\n"

    echo -e "${MAGENTA}ARGUMENTS:${NC}"
    echo -e "    target          Single IP, hostname, or CIDR network\n"

    echo -e "${MAGENTA}SCAN MODE OPTIONS:${NC}"
    echo -e "    -a, --aggressive    Aggressive scanning mode (faster, noisier)"
    echo -e "    -s, --stealth       Stealth mode (slower, quieter)"
    echo -e "    -v, --verbose       Enable verbose output\n"

    echo -e "${MAGENTA}PHASE CONTROL OPTIONS:${NC}"
    echo -e "    --no-discovery      Skip port discovery phase"
    echo -e "    --no-services       Skip service detection phase"
    echo -e "    --no-testing        Skip smart service testing phase"
    echo -e "    --no-vulns          Skip vulnerability scanning phase"
    echo -e "    --no-report         Skip report generation\n"

    echo -e "${MAGENTA}SERVICE TESTING OPTIONS:${NC}"
    echo -e "    --no-http           Skip HTTP/HTTPS testing"
    echo -e "    --no-ssh            Skip SSH testing"
    echo -e "    --no-ftp            Skip FTP testing"
    echo -e "    --no-smb            Skip SMB testing"
    echo -e "    --no-dns            Skip DNS testing"
    echo -e "    --no-database       Skip database testing\n"

    echo -e "${MAGENTA}OUTPUT OPTIONS:${NC}"
    echo -e "    -o, --output-dir    Custom output directory name"
    echo -e "    --json              Generate JSON report additionally"
    echo -e "    --xml               Generate XML report additionally\n"

    echo -e "${MAGENTA}EXAMPLES:${NC}"
    echo -e "    # Full scan"
    echo -e "    $SCRIPT_NAME 192.168.1.100\n"
    echo -e "    # Only port discovery and services"
    echo -e "    $SCRIPT_NAME target.com --only-services\n"
}

#################################################
# Setup directories
#################################################
setup_directories() {
    mkdir -p "$RESULTS_DIR" "$REPORTS_DIR" "$EVIDENCE_DIR"
    log_message "Created directories: $OUTPUT_DIR"
}

#################################################
# Phase 1: Port Discovery
#################################################
port_discovery() {
    print_info "Running port discovery on $TARGET..."
    log_message "Phase: Port Discovery"
    nmap -Pn -p- "$TARGET" -oN "${RESULTS_DIR}/ports.txt"
}

#################################################
# Phase 2: Service Detection
#################################################
service_detection() {
    print_info "Detecting services on discovered ports..."
    log_message "Phase: Service Detection"
    nmap -sV "$TARGET" -oN "${RESULTS_DIR}/services.txt"
}

#################################################
# Phase 3: Smart Testing
#################################################
smart_testing() {
    print_info "Running smart service-specific tests..."
    log_message "Phase: Smart Testing"

    # Read ports from services.txt
    ports=$(grep -Eo '^[0-9]+/tcp' "${RESULTS_DIR}/services.txt" | cut -d'/' -f1)

    for port in $ports; do
        test_function=$(get_service_test "$port")
        if [[ -n "$test_function" ]]; then
            $test_function "$TARGET" "$port"
        fi
    done
}

# Example test functions (HTTP, SSH, FTP, SMB)
http_tests() {
    [[ "$TEST_HTTP" == true ]] || return
    local target=$1; local port=$2
    print_hack "Testing HTTP on $target:$port..."
    curl -k -I "$target:$port" -m 5 >> "${RESULTS_DIR}/http_${port}.txt" 2>/dev/null
}

ssh_tests() {
    [[ "$TEST_SSH" == true ]] || return
    local target=$1; local port=$2
    print_hack "Testing SSH on $target:$port..."
    nc -zv "$target" "$port" 2>&1 | tee -a "${RESULTS_DIR}/ssh_${port}.txt"
}

ftp_tests() {
    [[ "$TEST_FTP" == true ]] || return
    local target=$1; local port=$2
    print_hack "Testing FTP on $target:$port..."
    nc -zv "$target" "$port" 2>&1 | tee -a "${RESULTS_DIR}/ftp_${port}.txt"
}

smb_tests() {
    [[ "$TEST_SMB" == true ]] || return
    local target=$1; local port=$2
    print_hack "Testing SMB on $target:$port..."
    smbclient -L "$target" -p "$port" -N >> "${RESULTS_DIR}/smb_${port}.txt" 2>/dev/null
}

dns_tests() {
    [[ "$TEST_DNS" == true ]] || return
    local target=$1; local port=$2
    print_hack "Testing DNS on $target:$port..."
    dig @"$target" >> "${RESULTS_DIR}/dns_${port}.txt"
}

database_tests() {
    [[ "$TEST_DATABASE" == true ]] || return
    local target=$1; local port=$2
    print_hack "Testing Database on $target:$port..."
    # Placeholder: Add actual DB checks (MySQL, Postgres, MSSQL)
}

#################################################
# Phase 4: Vulnerability Scan
#################################################
vuln_scan() {
    print_info "Running vulnerability scan..."
    log_message "Phase: Vulnerability Scan"
    nmap --script vuln "$TARGET" -oN "${RESULTS_DIR}/vulns.txt"
}

#################################################
# Phase 5: Report Generation
#################################################
generate_report() {
    print_info "Generating final report..."
    log_message "Phase: Report Generation"

    report_file="${REPORTS_DIR}/report_${TIMESTAMP}.txt"
    echo -e "SOMBRA Reconnaissance Report\n==========================\n" > "$report_file"
    cat "${RESULTS_DIR}/ports.txt" >> "$report_file"
    cat "${RESULTS_DIR}/services.txt" >> "$report_file"
    [[ -f "${RESULTS_DIR}/vulns.txt" ]] && cat "${RESULTS_DIR}/vulns.txt" >> "$report_file"
    print_success "Report saved to $report_file"
}

#################################################
# Argument Parsing
#################################################
if [[ $# -lt 1 ]]; then
    show_help
    exit 1
fi

TARGET="$1"
shift

while [[ $# -gt 0 ]]; do
    case $1 in
        -a|--aggressive) AGGRESSIVE_MODE=true ;;
        -s|--stealth) STEALTH_MODE=true ;;
        -v|--verbose) VERBOSE=true ;;
        --no-discovery) RUN_DISCOVERY=false ;;
        --no-services) RUN_SERVICE_DETECTION=false ;;
        --no-testing) RUN_SMART_TESTING=false ;;
        --no-vulns) RUN_VULN_SCAN=false ;;
        --no-report) RUN_REPORT=false ;;
        --no-http) TEST_HTTP=false ;;
        --no-ssh) TEST_SSH=false ;;
        --no-ftp) TEST_FTP=false ;;
        --no-smb) TEST_SMB=false ;;
        --no-dns) TEST_DNS=false ;;
        --no-database) TEST_DATABASE=false ;;
        -o|--output-dir) shift; OUTPUT_DIR="$1" ;;
        -h|--help) show_help; exit 0 ;;
        *) print_warning "Unknown option $1" ;;
    esac
    shift
done

#################################################
# Execution
#################################################
print_banner
setup_directories

$RUN_DISCOVERY && port_discovery
$RUN_SERVICE_DETECTION && service_detection
$RUN_SMART_TESTING && smart_testing
$RUN_VULN_SCAN && vuln_scan
$RUN_REPORT && generate_report

print_success "SOMBRA reconnaissance completed!"
