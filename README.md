# SysHawk
A powerful Linux system scanner &amp; auto-fix tool for SOC Analysts and Red Teamers


SysHawk is a powerful Linux system scanner and auto-fix tool designed for SOC Analysts and Red Teamers. It performs quick and deep scans of the system to detect firewall loopholes, suspicious processes, unusual network activity, and potential malware traces. It can auto-fix common issues, generate detailed logs, and send email alerts.

## Features
- Quick scan for open ports, firewall status, and crontab
- Deep scan with rootkit checks (chkrootkit, rkhunter)
- Auto-enable firewall if disabled
- Auto-disable suspicious services (e.g. telnet, ftp)
- Log generation with timestamp
- Email alerts for suspicious activity

## Usage

1. Make the script executable:
```bash
chmod +x syshawk.sh
