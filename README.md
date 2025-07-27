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

### Step 1: Create Users (on Server)

**Commands Used on CentOS Server and Ubuntu Client:**

```
sudo useradd adminuser
sudo passwd adminuser  # Password: @dmin123!

sudo useradd devuser
sudo passwd devuser    # Password: devus3r!

sudo useradd guestuser
sudo passwd guestuser  # Password: gu3st123!
```

**Explanation:** These commands create three users on the CentOS server and the Ubuntu client. The three users get their own user accounts on both server and client to separate each user's ssh keys and enforce the security practice of "principle of least privilege".

<img src="https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/user-creation.png" width="600" alt="user creation"/>

### Step 2: Create Group

**Command Used:**

```
sudo groupadd developers
```

**Explanation:** This creates a group for users collaborating on development tasks.

<img src="https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/group-creation.png" width="600" alt="group add developers"/>

### Step 3: Assign Users to Groups

**Commands Used:**

```
sudo usermod -aG developers devuser
sudo usermod -aG wheel adminuser
```

**Explanation:** `devuser` is added to the `developers` group for shared access. `adminuser` is added to the `wheel` group for sudo privileges (`wheel` for RHEL-based systems, `sudo` for debian-based systems).

<img src="https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/user-group-assignments.png" width="600" alt="group addition"/>

---

## Password Policies

### Step 1: Edit Login Definitions

**File Edited:** `/etc/login.defs`

**Commands Used:**

```
sudo vim /etc/login.defs
```

**Changes Made:**

```
PASS_MAX_DAYS 60
PASS_WARN_AGE 14
```

**Explanation:** Sets password expiration to 60 days and warning 14 days prior to expiration.

<img src="https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/modify-login-defs.gif" width="600" alt="passwerd expiration"/>

### Step 2: Apply to All Users

**Commands Used:**

```
sudo chage --maxdays 60 --warndays 14 adminuser
sudo chage --maxdays 60 --warndays 14 devuser
sudo chage --maxdays 60 --warndays 14 guestuser
```

<img src="https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/chage-command-output.png" width="600" alt="chage command output"/>

---

## Shared Directory

### Step 1: Create Shared Directory

**Commands Used:**

```
sudo mkdir -p /srv/devshare
sudo mkdir -p /srv/guestdocs
sudo chown root:developers /srv/devshare
sudo chown root:guestuser /srv/guestdocs
sudo chmod 2060 /srv/devshare
sudo chmod 2060 /srv/guestdocs
```

**Explanation:** Prepares a directory owned by root but writable by the `developers` group with `setgid`.

<img src="https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/directory-creation.png" width="600" alt="directory creation"/>

### Step 2: Set ACL for guestuser

**Command Used:**

```
sudo setfacl -m u:guestuser:r /srv/devshare/
```

**Explanation:** Gives `guestuser` read-only access using ACL.

<img src="https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/set-access-control.png" width="600" alt="ACL verification"/>

---

## SSH Configuration

### Step 1: Generate SSH Keys on Client (Different ssh key pair for each user)

**Commands Used:**

```
ssh-keygen
ssh-copy-id <user>@<centos server ip> # IP Address on CentOS host may vary on the network
```

**Explanation:** Enables passwordless SSH access using key authentication for adminuser and devuser.

<img src="https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/ssh-keygen-users.gif" width="600" alt="SSH Key generation"/>

### Step 2: Disable Password Login for adminuser

**Commands used:**
```
sudo vim /etc/ssh/sshd_config.d/admin-user-nologin.conf
sudo systemctl restart sshd
```

**File Created:** `/etc/ssh/sshd_config.d/admin-user-nologin.conf`

```
Match User adminuser
    PasswordAuthentication no
```

**Explanation:** Restricts adminuser to use SSH key authentication only.

<img src="https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/ssh-adminuser-fix.gif" width="600" alt="adminuser restriction"/>

---

## Firewall Setup

### Step 1: Networking in VirtualBox

Set the network adapter to `Bridged Adapter` for both CentOS and Ubuntu VMs.

<img src="https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/network-adapter.gif" width="600" alt="network adapter to bridged"/>

### Step 2: Enable Firewall and Open Required Ports

**Commands Used:**

```
sudo dnf install -y firewalld
sudo systemctl start firewalld
sudo firewall-cmd --zone=public --add-port=22/tcp --permanent
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --reload
```

**Explanation:** Enables firewalld, opens only necessary ports (SSH and HTTP).

<img src="https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/firewalld-ports.png" width="600" alt="firewalld setup"/>

---

## Web Server Deployment

### Step 1: Install Apache

**Commands Used:**

```
sudo yum install httpd -y
sudo systemctl enable --now httpd
sudo systemctl status httpd
```

**Explanation:** Installs and starts the Apache web server.

<img src="https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/httpd-setup.gif" width="600" alt="firewalld setup"/>

### Step 2: Test from Ubuntu Client

**Command Used:**

```
curl <centos server ip>:80 # IP Address may vary from your network
```

**Explanation:** Verifies that Apache is serving HTTP traffic on port 80 and is accessible from ubuntu client.

<img src="https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/curl-ubuntu.gif" width="600" alt="firewalld setup"/>

---

## Monitoring Scripts

### Memory Monitor Script

**Path:** `/usr/local/bin/mem_monitor.sh`
**Function:** Logs memory utilization level every 10 minutes with appropriate status code.

```
#!/bin/bash

#-----------------------------MEMORY UTILIZATION MONITOR---------------------------------#

 # color codes 
   GREEN='\033[0;32m'
   YELLOW='\033[1;33m'
   RED='\033[0;31m'
   NC='\033[0m'


#-----------VARIABLES------------
   timestamp=$(date "+%Y-%m-%d %H:%M:%S")
   total=$(grep MemTotal /proc/meminfo | awk '{print $2}') # returns the Total Memory kB
   available=$(grep MemAvailable /proc/meminfo | awk '{print $2}') # returns the Available Memory kB
   used_memory=$(echo "scale=2; ( $total - $available ) * 100 / total" | bc ] # Used Memory in %
#-------------------------------

if [ "$(echo "$used_memory < 80" | bc -l)" -eq 1 ]; then
    echo -e "${GREEN}$timestamp - OK - ${used_memory}%${NC}"
    exit 0
elif [ "$(echo "$used_memory < 90" | bc -l)" -eq 1 ]; then
    echo -e "${YELLOW}$timestamp - WARNING - ${used_memory}%${NC}"
    exit 1
else
    echo -e "${RED}$timestamp - CRITICAL - ${used_memory}%${NC}"
    exit 2
fi
```

<img src="https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/mem-test.gif" width="600" alt="memory test in action"/>

### CPU Monitor Script

**Path:** `/usr/local/bin/cpu_monitor.sh`
**Function:** Logs CPU utilization and categorizes by threshold.

```
#!/bin/bash

#-----------CPU UTILIZATION MONITOR-------------#
   # Color Codes
   GREEN='\033[0;32m'
   YELLOW='\033[1;33m'
   RED='\033[0;31m'
   NC='\033[0m' #no color 
#----------------------- Variables--------------------------
  timestamp=$(date "+%Y-%m-%d %H:%M:%S") 
  cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk -F',' '{print $4}' | awk '{print $1}') # Returns id,idle: time spent in the kernel idle handler
  cpu_usage=$(echo "100 - $cpu_idle" | bc) # bc for basic calculations, needed for acurate calculations with decimals 

#----------------------------------------------#
if [ "$(echo "$cpu_usage < 80" | bc -l)" -eq 1 ]; then
	echo -e "${GREEN}$timestamp - OK - ${cpu_usage}%${NC}"  # if usage < 80%
	exit 0
elif [ "$(echo "$cpu_usage < 90" | bc -l)" -eq 1 ]; then
	echo -e "${YELLOW}$timestamp - WARNING - ${cpu_usage}%${NC}"  # if usage >= 80% && usage < 90%
        exit 1
else 
	echo -e "${RED}$timestamp - CRITICAL - ${cpu_usage}%${NC}"   # if usage >= 90%
	exit 2
fi
```

### Crontab for Automation

**Commands Used:**

```
sudo crontab -e
```

**Crontab Entries:**

```
*/10 * * * * /usr/local/bin/mem_monitor.sh >> /var/log/mem_monitor.log 2>&1
*/10 * * * * /usr/local/bin/cpu_monitor.sh >> /var/log/cpu_monitor.log 2>&1
```

**Screenshot Placeholder:**
`![crontab -e output](https://github.com/kentcanonigo/linux-project-documentation/raw/main/screenshots/crontab%20-e%20output.png)`

---

## Notes

* Ensure monitor scripts are executable:

```
chmod +x /usr/local/bin/*_monitor.sh
```

* Restart SSH and firewall services after updates.

---

## End of Project
