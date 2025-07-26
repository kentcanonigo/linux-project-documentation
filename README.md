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

### Step 1: Create Users

**Commands Used:**

```bash
sudo useradd adminuser
sudo passwd adminuser  # Password: @dmin123!

sudo useradd devuser
sudo passwd devuser    # Password: devus3r!

sudo useradd guestuser
sudo passwd guestuser  # Password: gu3st123!
```

**Explanation:** These commands create three users on the server, each with a unique password.

**Screenshot Placeholder:**
`[Screenshot: user creation]`

### Step 2: Create Group

**Command Used:**

```bash
sudo groupadd developers
```

**Explanation:** This creates a group for users collaborating on development tasks.

**Screenshot Placeholder:**
`[Screenshot: group creation]`

### Step 3: Assign Users to Groups

**Commands Used:**

```bash
sudo usermod -aG developers devuser
sudo usermod -aG wheel adminuser
```

**Explanation:** `devuser` is added to the `developers` group for shared access. `adminuser` is added to the `wheel` group for sudo privileges.

**Screenshot Placeholder:**
`[Screenshot: user group assignments]`

---

## Password Policies

### Step 1: Edit Login Definitions

**File Edited:** `/etc/login.defs`
**Changes Made:**

```bash
PASS_MAX_DAYS 60
PASS_WARN_AGE 14
```

**Explanation:** Sets password expiration to 60 days and warning 14 days prior to expiration.

### Step 2: Apply to All Users

**Commands Used:**

```bash
sudo chage --maxdays 60 --warndays 14 adminuser
sudo chage --maxdays 60 --warndays 14 devuser
sudo chage --maxdays 60 --warndays 14 guestuser
```

**Screenshot Placeholder:**
`[Screenshot: chage command output]`

---

## Shared Directory

### Step 1: Create Shared Directory

**Commands Used:**

```bash
sudo mkdir -p /srv/devshare
sudo chown root:developers /srv/devshare
sudo chmod 2060 /srv/devshare
```

**Explanation:** Prepares a directory owned by root but writable by the `developers` group with `setgid`.

### Step 2: Set ACL for guestuser

**Command Used:**

```bash
sudo setfacl -m u:guestuser:r /srv/devshare/
```

**Explanation:** Gives `guestuser` read-only access using ACL.

**Screenshot Placeholder:**
`[Screenshot: ACL verification]`

---

## SSH Configuration

### Step 1: Generate SSH Keys on Client

**Commands Used:**

```bash
ssh-keygen -t rsa -C "devuser"
ssh-copy-id adminuser@192.168.1.25

ssh-keygen -t rsa -C "guestuser"
ssh-copy-id guestuser@192.168.1.25
```

**Explanation:** Enables passwordless SSH access using key authentication.

**Screenshot Placeholder:**
`[Screenshot: ssh-keygen and ssh-copy-id outputs]`

### Step 2: Disable Password Login for adminuser

**File Created:** `/etc/ssh/sshd_config.d/admin-user-nologin.conf`

```conf
Match User adminuser
    PasswordAuthentication no
```

**Command:**

```bash
sudo systemctl restart sshd
```

**Explanation:** Restricts adminuser to use SSH key authentication only.

**Screenshot Placeholder:**
`[Screenshot: sshd config and restart]`

---

## Firewall Setup

### Step 1: Networking in VirtualBox

Set the network adapter to `Bridged Adapter` for both CentOS and Ubuntu VMs.

**Screenshot Placeholder:**
`[Screenshot: VirtualBox network settings]`

### Step 2: Enable Firewall and Open Required Ports

**Commands Used:**

```bash
sudo dnf install -y firewalld
sudo systemctl start firewalld
sudo firewall-cmd --zone=public --add-port=22/tcp --permanent
sudo firewall-cmd --zone=public --add-port=80/tcp --permanent
sudo firewall-cmd --reload
```

**Explanation:** Enables firewalld, opens only necessary ports (SSH and HTTP).

**Screenshot Placeholder:**
`[Screenshot: firewall-cmd confirmation]`

---

## Web Server Deployment

### Step 1: Install Apache

**Commands Used:**

```bash
sudo yum install httpd -y
sudo systemctl enable --now httpd
sudo systemctl status httpd
```

**Explanation:** Installs and starts the Apache web server.

**Screenshot Placeholder:**
`[Screenshot: apache status output]`

### Step 2: Test from Ubuntu Client

**Command Used:**

```bash
curl http://192.168.1.12:80
```

**Explanation:** Verifies that Apache is serving HTTP traffic.

**Screenshot Placeholder:**
`[Screenshot: curl output of default Apache page]`

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

```bash
sudo crontab -e
```

**Crontab Entries:**

```cron
*/10 * * * * /usr/local/bin/mem_monitor.sh >> /var/log/mem_monitor.log 2>&1
*/10 * * * * /usr/local/bin/cpu_monitor.sh >> /var/log/cpu_monitor.log 2>&1
```

**Screenshot Placeholder:**
`[Screenshot: crontab -e output]`

---

## Notes

* Ensure monitor scripts are executable:

```bash
chmod +x /usr/local/bin/*_monitor.sh
```

* Restart SSH and firewall services after updates.

---

## End of Project
