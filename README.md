*Looking for the Italian version? [Click here to read the README in Italian](./README_IT.md)*

---

# IT Lab Project: Corporate Network with Windows Server and Linux

## 1. Project Overview
This repository contains my personal project where I simulated a small company IT network from scratch. The main goal was to put into practice what I studied, creating a mixed network environment with Windows and Linux servers. 

I focused on centralized user management through Active Directory, automatic account creation using scripts, automated software deployment, file sharing, and continuous monitoring. Furthermore, I implemented advanced security protocols for local administrator accounts and successfully executed a cross-hypervisor migration of the entire infrastructure.

Initially, I used Oracle VirtualBox to build the environment on a NAT network. Later, I migrated the entire laboratory to VMware Workstation Pro to test an enterprise-grade hypervisor.

## 2. Network Architecture
The network uses the 10.0.2.0/24 subnet, simulating the local LAN of the "ACME Corp" company. I assigned a static IP address to each server to ensure they are always reachable.

| Computer Name | IP Address | Operating System | Purpose |
| :--- | :--- | :--- | :--- |
| **SRV-DC01** | 10.0.2.10 | Windows Server 2022 | Domain Controller, DNS Server, and Active Directory |
| **SRV-WEB01** | 10.0.2.11 | Ubuntu Server 24.04 | Web Server (Nginx) for the internal company page |
| **CLIENT-W11** | 10.0.2.50 | Windows 11 Pro | Employee PC and network monitoring station |

## 3. Server Configurations

### 3.1 Windows Server (Domain and DNS)
I configured the main Windows server as a Domain Controller to create the acmecorp.local domain. 
* **DNS:** I set up the local DNS server. To allow computers on the network to browse the internet, I added Forwarders pointing to Google's DNS servers (8.8.8.8).
* **Active Directory:** I created and managed users and computers directly from the server.

### 3.2 PowerShell Script for Users
Instead of creating users manually one by one, I wrote a PowerShell script (Create-AdUsers.ps1). The script works like this:
* It reads the first names and last names of the employees from a .csv file.
* It automatically creates the user account (using the first letter of the name and the full last name).
* It assigns a generic temporary password.
* It enables the setting that forces the employee to change the password at their first login on Windows 11, for security reasons.

### 3.3 Linux Web Server (Ubuntu)
I used a Linux server without a graphical user interface (command line only) to host the company website.
* **Network:** I set the static IP by modifying the Netplan configuration files.
* **Firewall:** I enabled the UFW firewall to keep only port 80 open, which is required for the website.
* **Website:** I installed Nginx to run the internal web page.

## 4. Corporate Infrastructure Management

### 4.1 File Server and Network Drive (Drive Z:)
To provide employees with a centralized and secure place to save their work, I configured a File Server.
* **Shared Folder:** I created a folder named Dati_Aziendali on the Server and shared it.
* **NTFS Permissions:** I assigned "Modify" permissions to the Domain Users group. This ensures only authenticated employees can access and modify these files.
* **Drive Mapping:** I used a Group Policy Object (GPO) so that when a user logs into Windows 11, the shared folder automatically appears as Drive Z: in "This PC".

<details>
<summary>Click to expand GPO details for Drive Mapping</summary>

* GPO Path: User Configuration > Preferences > Windows Settings > Drive Maps
* Action: Create
* Location: \\SRV-DC01\Dati_Aziendali
* Drive Letter: Z:
</details>

### 4.2 Automatic Software Deployment
To avoid installing programs manually on every client, I automated the process.
* I created a shared folder called Deploy_Software on the Server and placed the 7-Zip.msi installer inside.
* I configured a GPO (Computer Configuration > Policies > Software Settings) linked to the computers. When the Windows 11 PC boots up, it automatically installs 7-Zip over the network before the user reaches the desktop.

### 4.3 Advanced Security: LAPS
To prevent hacker attacks that exploit standard local administrator passwords, I implemented LAPS (Local Administrator Password Solution). LAPS generates a random, complex password for every PC and stores it securely in Active Directory.

* **Version Conflict Resolution:** Windows 11 has a modern "Native LAPS", while Server 2022 uses the older "Legacy" system. I resolved this mismatch by configuring the local policy on Windows 11 to force communication with the Active Directory backup directory.
* **Account Activation:** Since Windows 11 disables the local Administrator account by default, I created a specific GPO on the Server to enable it, making the LAPS password actually usable in an emergency.

<details>
<summary>Click to expand LAPS technical configuration steps</summary>

1. Active Directory Preparation: Ran Update-AdmPwdADSchema and Set-AdmPwdComputerSelfPermission via PowerShell on the Server.
2. Enable Local Admin (Server GPO): Computer Configuration > Policies > Windows Settings > Security Settings > Local Policies > Security Options > Accounts: Administrator account status set to Enabled.
3. Local Policy (Windows 11): Computer Configuration > Administrative Templates > System > LAPS > Configure password backup directory set to Active Directory.
</details>

## 5. Network Monitoring and Testing

### 5.1 Web-Based Monitoring (OpenManage)
To check that everything runs smoothly, I used OpenManage via a web browser on the Windows 11 PC, acting as the network administrator station. I added the servers to the web dashboard to monitor if they respond to Pings (ICMP) and if the website port (TCP) is open.

**Web Server Alarm Test:**
To prove the monitoring works, I did a practical test:
1. **Problem:** From the Ubuntu terminal, I intentionally stopped the website service using the command sudo systemctl stop nginx.
2. **Result:** After a few minutes, the OpenManage web dashboard showed a critical red alarm warning that the site was unreachable.
3. **Solution:** I restarted Nginx, and the alarm on OpenManage turned green automatically.

### 5.2 Offline Disaster Recovery Test
To verify the LAPS configuration, I performed a disaster simulation:
1. I disconnected the network adapter of the Windows 11 client.
2. I retrieved the generated password from the LAPS UI application on the Server.
3. I logged into the offline Windows 11 PC using the local .\Administrator account and the LAPS password.
4. The login was successful, proving I can maintain administrative access even when the Domain Controller is completely unreachable.

## 6. Cross-Hypervisor Migration (VirtualBox to VMware)
To upgrade the laboratory environment, I successfully migrated all virtual machines from Oracle VirtualBox to VMware Workstation Pro. 

This required careful preparation to prevent hardware conflicts (such as BSODs on Windows or Kernel Panics on Linux) and network issues (Ghost NICs).

**Migration Steps Performed:**
1. **Preparation (Driver Removal):** Before exporting, I uninstalled the VirtualBox Guest Additions from all machines. Note: Since I had previously applied a GPO blocking the Control Panel for standard users on Windows 11, I bypassed the restriction by running the uninst.exe file directly from the C: drive as a Domain Administrator.
2. **Exporting:** I exported each virtual machine from VirtualBox into the universal .ova (Open Virtualization Format) standard.
3. **Importing:** I imported the .ova files into VMware Workstation Pro.
4. **Network Reconfiguration:** To maintain the static IPs and domain communication, I replaced the default NAT network with a custom "LAN Segment" in VMware, acting as an isolated virtual switch.
5. **Finalization:** I booted the machines and installed VMware Tools on all operating systems to ensure optimal performance and integration.

## 7. Repository Files
* /scripts/Create-AdUsers.ps1: My PowerShell script to import users.
* /data/utenti.csv: The text file containing the fake employee data.
* /images/: Screenshots of the completed work (Active Directory, OpenManage dashboard alarms, Ubuntu terminal, 7-Zip deployment, Drive Z:, LAPS UI, and VMware Dashboard).

## 8. Conclusion
This project helped me understand how different operating systems (Windows and Linux) can communicate and work together in the same network. I learned the importance of using scripts to reduce manual labor, implementing advanced security measures like LAPS, and utilizing monitoring tools to detect problems immediately. Finally, migrating the infrastructure taught me how to safely move enterprise environments across different virtualization platforms.
