# Secure Multi-User Linux Server Project (CentOS Stream 9)

## Project Overview

This project simulates a real-world Linux system administration task involving the configuration of a secure, multi-user server environment. The server runs on CentOS Stream 9 and is accessed via an Ubuntu client. It covers user management, SSH configuration, file permissions, firewall setup, and system monitoring.

---

## Objectives

* Configure a CentOS 9 server for multi-user access
* Set up secure SSH access from an Ubuntu client
* Implement user and group management
* Configure file permissions and shared directories
* Set up firewall rules (firewalld)
* Create monitoring scripts for CPU and memory usage

---

## User and Group Management

### Create Users

```bash
sudo useradd adminuser
sudo passwd adminuser  # Password: @dmin123!

sudo useradd devuser
sudo passwd devuser    # Password: devus3r!

sudo useradd guestuser
sudo passwd guestuser  # Password: gu3st123!
```

### Create Group

```bash
sudo groupadd developers
```

### Group Assignments

```bash
sudo usermod -aG developers devuser
sudo usermod -aG wheel adminuser
```

---

## Password Policies

Edit `/etc/login.defs`:

* Set password expiry:

  ```bash
  PASS_MAX_DAYS 60
  PASS_WARN_AGE 14
  ```

* Apply policies to users:

  ```bash
  sudo chage --maxdays 60 --warndays 14 adminuser
  sudo chage --maxdays 60 --warndays 14 devuser
  sudo chage --maxdays 60 --warndays 14 guestuser
  ```

---

## Shared Directory Setup

### Create and Configure Directory

```bash
sudo mkdir -p /srv/devshare
sudo chown root:developers /srv/devshare
sudo chmod 2060 /srv/devshare
```

### Read-Only Access for guestuser

```bash
sudo setfacl -m u:guestuser:r /srv/devshare/
```

---

## SSH Configuration

### Key-based Login from Ubuntu Client

On Ubuntu client:

```bash
sudo su - devuser
ssh-keygen -t rsa -C "devuser"
ssh-copy-id adminuser@192.168.1.25

sudo su - guestuser
ssh-keygen -t rsa -C "guestuser"
ssh-copy-id guestuser@192.168.1.25
```

### Disable Password Login for adminuser

Create file `/etc/ssh/sshd_config.d/admin-user-nologin.conf`:

```conf
Match User adminuser
    PasswordAuthentication no
```

Restart SSH:

```bash
sudo systemctl restart sshd
```

---

## Firewall Configuration

### Ensure Bridged Networking in VirtualBox

Set both CentOS and Ubuntu network adapters to "Bridged Adapter".

### Allow Only SSH and HTTP

```bash
sudo dnf install -y firewalld
sudo systemctl start firewalld

sudo firewall-cmd --zone=public --add-port=22/tcp --permanent
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --reload
```

---

## Web Server Deployment

### Install and Enable Apache

```bash
sudo yum install httpd -y
sudo systemctl enable --now httpd
sudo systemctl status httpd
```

### Test HTTP Access

From Ubuntu client:

```bash
curl http://192.168.1.12:80
```

---

## System Monitoring Scripts

### 1. Memory Utilization Monitor

`/usr/local/bin/mem_monitor.sh`

```bash
#!/bin/bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
timestamp=$(date "+%Y-%m-%d %H:%M:%S")
total=$(grep MemTotal /proc/meminfo | awk '{print $2}')
available=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
used_memory=$(echo "scale=2; ($total - $available) * 100 / $total" | bc)

if (( $(echo "$used_memory < 80" | bc -l) )); then
    echo -e "$timestamp - OK - ${used_memory}%"
    exit 0
elif (( $(echo "$used_memory < 90" | bc -l) )); then
    echo -e "$timestamp - WARNING - ${used_memory}%"
    exit 1
else
    echo -e "$timestamp - CRITICAL - ${used_memory}%"
    exit 2
fi
```

### 2. CPU Utilization Monitor

`/usr/local/bin/cpu_monitor.sh`

```bash
#!/bin/bash
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'
timestamp=$(date "+%Y-%m-%d %H:%M:%S")
cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk -F',' '{print $4}' | awk '{print $1}')
cpu_usage=$(echo "100 - $cpu_idle" | bc)

if (( $(echo "$cpu_usage < 80" | bc -l) )); then
    echo -e "$timestamp - OK - ${cpu_usage}%"
    exit 0
elif (( $(echo "$cpu_usage < 90" | bc -l) )); then
    echo -e "$timestamp - WARNING - ${cpu_usage}%"
    exit 1
else
    echo -e "$timestamp - CRITICAL - ${cpu_usage}%"
    exit 2
fi
```

### Logging and Cron Job

Place logs in `/var/log/`:

```bash
sudo crontab -e
```

Add:

```cron
*/10 * * * * /usr/local/bin/mem_monitor.sh >> /var/log/mem_monitor.log 2>&1
*/10 * * * * /usr/local/bin/cpu_monitor.sh >> /var/log/cpu_monitor.log 2>&1
```

---

## Notes

* Ensure correct file permissions for monitor scripts:

  ```bash
  chmod +x /usr/local/bin/*_monitor.sh
  ```
* Reboot the system or restart affected services after critical configuration changes.

---

## End of Project
