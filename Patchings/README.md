# checklastpatch Function Overview

## Purpose
The `checklastpatch` function is designed to collect important system and update-related information from a remote server. It uses SSH to connect to a specified server and gathers data regarding:
- System uptime
- Red Hat version
- YUM package history (especially updates)
- Kernel version
- Recent system patch actions

This function then formats the collected data and saves it to two output files: one for logging (`$output_file`) and one for sending via email (`$mailto_file`).

## Function Breakdown

### 1. Collecting System Uptime
The function begins by retrieving the system uptime from the remote server using the `uptime` command. It formats the output to extract the most relevant uptime information, including the duration of system operation. The uptime data is stored in the `suptime` variable.

**Command used:**
```
suptime=`ssh -q -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server uptime | awk -F, '{print $1}' | awk '{if (NF==4) print $(NF-1),$NF; else if (NF==3) print $NF}'`
```

### 2. Retrieving Red Hat Version
The function retrieves the Red Hat version by reading the `/etc/redhat-release` file from the remote server. The version number (e.g., `7.9`, `8.10`) is extracted using a regular expression.

**Command used:**
```
rhelver=$(ssh -q -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server cat /etc/redhat-release | grep -oP '\d+\.\d+')
```

### 3. Extracting YUM History Information
The function queries the YUM history to find the most recent package update information. The YUM history is filtered to exclude unwanted lines and then processed to extract the first matching record that shows a package update (i.e., actions like "Up", "Update", etc.).

**Command used:**
```
yumhist=`ssh -q -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo yum history | egrep -v "entitlement|plugins|subscription-manager|history|Uploading|^ID|^--" | awk -F'|' -v OFS='|' '{gsub(" ", "", $4); if ($4 ~ /^Up/ || ($4 ~ /U/)) {print $1, $3, $4; exit}}'`
```

### 4. Retrieving Kernel Information
The function retrieves the most recent kernel version by querying the RPM database. It lists all installed kernel packages and selects the most recent one.

**Command used:**
```
kerinfo=`ssh -q -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo rpm -qa --last kernel | head -1`
```

### 5. Parsing and Processing Information
Once the data is retrieved from the remote server, the function processes it:
- The kernel information is split into two variables (`kernel` and `datesk`).
- The YUM history is split into three variables (`id`, `dates`, and `actions`).
- If certain actions are detected (install, update, etc.), they are cleaned up and formatted by replacing commas with hyphens.
- Extra spaces from the `dates` string are trimmed.

**Command used:**
```
read kernel datesk <<< $(echo $kerinfo)
IFS='|' read id dates actions <<< $(echo $yumhist)
if [[ "$actions" == *"E,I,O,U"* || "$actions" == *"E,I,U"* || "$actions" == *"I,U"* ]]; then
    actions=$( echo $actions | sed 's/,/-/g')
fi
dates=$(echo "$dates" | awk '{$1=$1};1')
```

### 6. Output and Logging
The function then formats the gathered data into a CSV-like format and writes it to two output files:
- **$output_file**: This file is used for logging purposes.
- **$mailto_file**: This file can be used to send the collected data via email.

The formatted data includes the server name, Red Hat version, YUM update ID, date of update, actions taken, kernel version, and system uptime.

```
Fri Jan 31 15:11:53 CET 2025
+--------------------------+--------------+--------+------------------+-----------+-------------------------------------+---------------------------------+---------+
| SERVER                   | RHEL Version | Yum ID | Patch date       | Action(s) | latest Kernal info                  | kernel dates and time           | Uptime  |
+--------------------------+--------------+--------+------------------+-----------+-------------------------------------+---------------------------------+---------+
| MyOrgProdRHELServer00123 | 7.9          | 137    | 2025-01-07 19:07 | Update    | kernel-3.10.0-1160.129.1.el7.x86_64 | Tue 03 Dec 2024 07:06:21 PM CET | 23 days |
| MyOrgProdRHELServer00124 | 7.9          | 124    | 2025-01-06 07:03 | Update    | kernel-3.10.0-1160.129.1.el7.x86_64 | Mon 02 Dec 2024 07:03:27 AM CET | 25 days |
| MyOrgProdRHELServer00125 | 7.9          | 133    | 2025-01-06 12:05 | Update    | kernel-3.10.0-1160.129.1.el7.x86_64 | Mon 02 Dec 2024 12:06:23 PM CET | 25 days |
| MyOrgProdRHELServer00126 | 9.5          | 20     | 2025-01-05 10:27 | C-E-I-U   | kernel-5.14.0-503.19.1.el9_5.x86_64 | Sun 05 Jan 2025 10:27:30 AM CET | 26 days |
| MyOrgProdRHELServer00127 | 7.9          | 120    | 2025-01-02 07:02 | Update    | kernel-3.10.0-1160.129.1.el7.x86_64 | Thu 05 Dec 2024 07:02:48 AM CET | 29 days |
| MyOrgProdRHELServer00128 | 7.9          | 122    | 2025-01-02 07:02 | Update    | kernel-3.10.0-1160.129.1.el7.x86_64 | Thu 05 Dec 2024 07:02:52 AM CET | 29 days |
| MyOrgProdRHELServer00129 | 7.9          | 124    | 2025-01-02 07:02 | Update    | kernel-3.10.0-1160.129.1.el7.x86_64 | Thu 05 Dec 2024 07:02:43 AM CET | 29 days |
| MyOrgProdRHELServer00122 | 7.9          | 127    | 2025-01-02 07:02 | Update    | kernel-3.10.0-1160.129.1.el7.x86_64 | Thu 05 Dec 2024 07:02:54 AM CET | 29 days |
+--------------------------+--------------+--------+------------------+-----------+-------------------------------------+---------------------------------+---------+
```

**Command used:**
```
echo "$server,$rhelver,$id,$dates,$actions,$kernel,$datesk,$suptime" >> $output_file
echo "$server,$rhelver,$id,$dates,$actions,$kernel,$datesk,$suptime" >> $mailto_file
```

## Summary of Collected Information
The following data is gathered for each server:
1. **Uptime**: Duration the server has been running.
2. **Red Hat Version**: The version of Red Hat Enterprise Linux installed.
3. **YUM History**: The most recent package update, including the ID, date, and actions.
4. **Kernel Version**: The most recently installed kernel.
5. **System Uptime**: The duration of time since the system was last rebooted.

The function then outputs this information in a CSV format, which is saved in two separate files for logging and emailing purposes.

## Requirements
- **SSH**: The function uses SSH to connect to the remote server.
- **Root Privileges**: `sudo` is required to fetch certain information, such as YUM history and kernel information.
- **Access**: You must have appropriate access to the remote servers and their associated ports.

## Conclusion
The `checklastpatch` function is an efficient way to gather essential system and update-related information from remote servers. It ensures you can monitor the system uptime, Red Hat version, patch history, and kernel details, which is useful for auditing and reporting purposes.

