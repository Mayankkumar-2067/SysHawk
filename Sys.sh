#!/bin/bash

# Colors
RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; BLUE="\e[34m"; RESET="\e[0m"

# Log file
LOGFILE="syshawk_scan_$(date +%F_%T).log"

# Email settings (Customize these)
EMAIL_TO="your.email@example.com"
EMAIL_SUBJECT="SysHawk Alert: Suspicious Activity Detected on $(hostname)"

# Banner
clear
echo -e "${BLUE}"
echo "==========================================================="
echo "        SysHawk - Linux Antivirus-like Recon Tool"
echo "     Developed by Mayank (SOC + Red Team Utility)"
echo "==========================================================="
echo -e "${RESET}"

# Function to log and display message
log_echo() {
    echo -e "$1" | tee -a "$LOGFILE"
}

# Auto-fix example functions
enable_firewall() {
    log_echo "${YELLOW}[Auto-fix] Enabling UFW firewall...${RESET}"
    sudo ufw enable | tee -a "$LOGFILE"
}

disable_suspicious_service() {
    service_name=$1
    log_echo "${YELLOW}[Auto-fix] Disabling suspicious service: $service_name${RESET}"
    sudo systemctl stop "$service_name" | tee -a "$LOGFILE"
    sudo systemctl disable "$service_name" | tee -a "$LOGFILE"
}

send_email_alert() {
    if command -v mail &> /dev/null; then
        mail -s "$EMAIL_SUBJECT" "$EMAIL_TO" < "$LOGFILE"
        log_echo "${GREEN}[+] Email alert sent to $EMAIL_TO${RESET}"
    else
        log_echo "${RED}[-] mail command not found. Cannot send email.${RESET}"
    fi
}

# Check & Install Dependencies (Optional)
function check_tools() {
    for tool in chkrootkit rkhunter netstat ufw iptables mail; do
        if ! command -v $tool &> /dev/null; then
            log_echo "${YELLOW}Installing missing tool: $tool${RESET}"
            sudo apt install $tool -y &>> "$LOGFILE"
        fi
    done
}

check_tools

# MENU
echo -e "${YELLOW}Choose Scan Type:${RESET}"
echo "1. Quick Scan"
echo "2. Deep System Scan (Recommended)"
echo "3. Exit"
read -p "Enter option (1-3): " choice

suspicious_found=0

if [[ "$choice" == "1" ]]; then
    log_echo "${GREEN}\n[+] Running Quick Scan...${RESET}"
    
    log_echo "\n${YELLOW}[+] Checking Open Ports...${RESET}"
    netstat -tulpn 2>/dev/null | grep LISTEN | tee -a "$LOGFILE"

    log_echo "\n${YELLOW}[+] Firewall Rules...${RESET}"
    sudo iptables -L -n -v --line-numbers | tee -a "$LOGFILE"

    log_echo "\n${YELLOW}[+] Suspicious External Connections...${RESET}"
    netstat -antp | grep ESTABLISHED | grep -v 127.0.0.1 | tee -a "$LOGFILE"

    log_echo "\n${YELLOW}[+] Crontab Check...${RESET}"
    crontab -l 2>/dev/null | grep -v '^#' | tee -a "$LOGFILE"

    # Auto-fix example: enable firewall if ufw is inactive
    ufw_status=$(sudo ufw status | grep Status | awk '{print $2}')
    if [[ "$ufw_status" != "active" ]]; then
        suspicious_found=1
        enable_firewall
    fi

    log_echo "\n${GREEN}[+] Quick Scan Complete.${RESET}"

elif [[ "$choice" == "2" ]]; then
    log_echo "${GREEN}\n[+] Running Deep System Scan...${RESET}"

    log_echo "\n${YELLOW}[1] Running chkrootkit...${RESET}"
    chkrootkit | tee -a "$LOGFILE"

    log_echo "\n${YELLOW}[2] Running rkhunter...${RESET}"
    rkhunter --check --sk | tee -a "$LOGFILE"

    log_echo "\n${YELLOW}[3] Checking Suspicious Services...${RESET}"
    suspicious_services=$(systemctl list-units --type=service --state=running | grep -v 'systemd' | tee -a "$LOGFILE")
    
    # Auto-fix example: stop & disable suspicious services containing "telnet" or "ftp"
    for svc in $(echo "$suspicious_services" | awk '{print $1}'); do
        if [[ "$svc" =~ telnet|ftp ]]; then
            suspicious_found=1
            disable_suspicious_service "$svc"
        fi
    done

    log_echo "\n${YELLOW}[4] Checking All Startup Programs...${RESET}"
    ls -lah /etc/init.d/ | tee -a "$LOGFILE"
    ls -lah ~/.config/autostart/ 2>/dev/null | tee -a "$LOGFILE"

    log_echo "\n${YELLOW}[5] Crontab Entries...${RESET}"
    crontab -l 2>/dev/null | grep -v '^#' | tee -a "$LOGFILE"

    log_echo "\n${YELLOW}[6] External Connections...${RESET}"
    netstat -antp | grep ESTABLISHED | grep -v 127.0.0.1 | tee -a "$LOGFILE"

    log_echo "\n${YELLOW}[7] Hidden Running Processes...${RESET}"
    ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head | tee -a "$LOGFILE"

    log_echo "\n${YELLOW}[8] Suspicious Network Ports...${RESET}"
    netstat -tulpn | grep -Ev '127.0.0.1|localhost' | tee -a "$LOGFILE"

    # Auto-fix example: enable firewall if ufw is inactive
    ufw_status=$(sudo ufw status | grep Status | awk '{print $2}')
    if [[ "$ufw_status" != "active" ]]; then
        suspicious_found=1
        enable_firewall
    fi

    log_echo "\n${GREEN}[+] Deep Scan Complete. Review all suspicious entries.${RESET}"

else
    log_echo "${RED}Exiting SysHawk. Stay Secure.${RESET}"
    exit 0
fi

# Send email if suspicious activity detected
if [[ $suspicious_found -eq 1 ]]; then
    log_echo "${RED}[!] Suspicious activity detected. Sending email alert...${RESET}"
    send_email_alert
else
    log_echo "${GREEN}[+] No suspicious activity detected.${RESET}"
fi
