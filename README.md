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

**Commands Used on CentOS Server:**

```
sudo useradd adminuser
sudo passwd adminuser  # Password: @dmin123!

sudo useradd devuser
sudo passwd devuser    # Password: devus3r!

sudo useradd guestuser
sudo passwd guestuser  # Password: gu3st123!
```

**Explanation:** These commands create three users on the CentOS server.

<img src="https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/user%20creation.png" width="200" alt="user creation"/>

### Step 2: Create Group

**Command Used:**

```
sudo groupadd developers
```

**Explanation:** This creates a group for users collaborating on development tasks.

![group creation](https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/group%20creation.png)

### Step 3: Assign Users to Groups

**Commands Used:**

```
sudo usermod -aG developers devuser
sudo usermod -aG wheel adminuser
```

**Explanation:** `devuser` is added to the `developers` group for shared access. `adminuser` is added to the `wheel` group for sudo privileges.

![user group assignments](https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/user%20group%20assignments.png)

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

![modify login defs](https://github.com/kentcanonigo/linux-project-documentation/blob/main/screenshots/modify%20login%20defs.gif)

### Step 2: Apply to All Users

**Commands Used:**

```
sudo chage --maxdays 60 --warndays 14 adminuser
sudo chage --maxdays 60 --warndays 14 devuser
sudo chage --maxdays 60 --warndays 14 guestuser
```

**Screenshot Placeholder:**
`![chage command output](https://github.com/kentcanonigo/linux-project-documentation/raw/main/screenshots/chage%20command%20output.png)`

---

## Shared Directory

### Step 1: Create Shared Directory

**Commands Used:**

```
sudo mkdir -p /srv/devshare
sudo chown root:developers /srv/devshare
sudo chmod 2060 /srv/devshare
```

**Explanation:** Prepares a directory owned by root but writable by the `developers` group with `setgid`.

### Step 2: Set ACL for guestuser

**Command Used:**

```
sudo setfacl -m u:guestuser:r /srv/devshare/
```

**Explanation:** Gives `guestuser` read-only access using ACL.

**Screenshot Placeholder:**
`![ACL verification](https://github.com/kentcanonigo/linux-project-documentation/raw/main/screenshots/ACL%20verification.png)`

---

## SSH Configuration

### Step 1: Generate SSH Keys on Client

**Commands Used:**

```
ssh-keygen -t rsa -C "devuser"
ssh-copy-id adminuser@192.168.1.25

ssh-keygen -t rsa -C "guestuser"
ssh-copy-id guestuser@192.168.1.25
```

**Explanation:** Enables passwordless SSH access using key authentication.

**Screenshot Placeholder:**
`![ssh-keygen and ssh-copy-id outputs](https://github.com/kentcanonigo/linux-project-documentation/raw/main/screenshots/ssh-keygen%20and%20ssh-copy-id%20outputs.png)`

### Step 2: Disable Password Login for adminuser

**File Created:** `/etc/ssh/sshd_config.d/admin-user-nologin.conf`

```
Match User adminuser
    PasswordAuthentication no
```

**Command:**

```
sudo systemctl restart sshd
```

**Explanation:** Restricts adminuser to use SSH key authentication only.

**Screenshot Placeholder:**
`![sshd config and restart](https://github.com/kentcanonigo/linux-project-documentation/raw/main/screenshots/sshd%20config%20and%20restart.png)`

---

## Firewall Setup

### Step 1: Networking in VirtualBox

Set the network adapter to `Bridged Adapter` for both CentOS and Ubuntu VMs.

**Screenshot Placeholder:**
`![VirtualBox network settings](https://github.com/kentcanonigo/linux-project-documentation/raw/main/screenshots/VirtualBox%20network%20settings.png)`

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

**Screenshot Placeholder:**
`![firewall-cmd confirmation](https://github.com/kentcanonigo/linux-project-documentation/raw/main/screenshots/firewall-cmd%20confirmation.png)`

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

**Screenshot Placeholder:**
`![apache status output](https://github.com/kentcanonigo/linux-project-documentation/raw/main/screenshots/apache%20status%20output.png)`

### Step 2: Test from Ubuntu Client

**Command Used:**

```
curl http://192.168.1.12:80
```

**Explanation:** Verifies that Apache is serving HTTP traffic.

**Screenshot Placeholder:**
`![curl output of default Apache page](https://github.com/kentcanonigo/linux-project-documentation/raw/main/screenshots/curl%20output%20of%20default%20Apache%20page.png)`

---

## Monitoring Scripts

### Memory Monitor Script

**Path:** `/usr/local/bin/mem_monitor.sh`
**Function:** Logs memory utilization level every 10 minutes with appropriate status code.

### CPU Monitor Script

**Path:** `/usr/local/bin/cpu_monitor.sh`
**Function:** Logs CPU utilization and categorizes by threshold.

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
