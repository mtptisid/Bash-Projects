# System Resource Usage Monitoring Script

## Overview
This script is designed to monitor and report system resource usage, including CPU, memory (RAM and swap), and swap usage by individual processes. It performs the following tasks:

- Displays system uptime.
- Retrieves the top processes by CPU usage.
- Shows the current memory and swap usage.
- Reports on swap usage per process.
- Formats the data in a user-friendly table format.
- Outputs the data into CSV files for further processing or review.

## Prerequisites

Ensure the following dependencies are installed on your system:

- `ps` command (usually pre-installed on most Linux systems).
- `top` command (for gathering system statistics).
- `awk` and `bc` for parsing and calculations.
- `mktemp` (used for creating temporary directories).

## Usage

1. **Download the Script:**
   Download the script to your desired directory.

  ```bash
   wget https://example.com/resource_usage_monitor.sh
   ```

2. **Give Execute Permissions:**
   Make the script executable.

   ```bash
   chmod +x resource_usage_monitor.sh
   ```

3. **Run the Script:**
   Simply run the script to monitor the system resources.

   ```bash
   ./resource_usage_monitor.sh
   ```

## Script Details

### 1. **Uptime Section**
This section retrieves the system uptime and displays it in a formatted manner.

```bash
echo "+-------------------------------- Uptime --------------------------------+"
echo "| `uptime` |"
echo "+------------------------------------------------------------------------+"
```

### 2. **Top Processes by CPU Usage**
The script fetches the top processes by CPU usage using the `top` command and formats the output into a table.

```bash
top -b -n 1 | awk 'NR>7 {print $1","$2","$3","$4","$5","$6","$7","$8","$9","$10","$11","$12}' | head -7 >> $TOPF
format_table $TOPF
```

### 3. **Memory Usage Section**
The script fetches the memory usage statistics (`free` command) and formats them into a CSV table.

```bash
free -h | awk '
  NR==2 {mem_total=$2; mem_used=$3; mem_free=$4; mem_shared=$5; mem_buff_cache=$6; mem_available=$7}
  NR==3 {swap_total=$2; swap_used=$3; swap_free=$4}
  END {
    print ",MEM,SWAP"
    print "total," mem_total "," swap_total
    print "Used," mem_used "," swap_used
    print "free," mem_free "," swap_free
    print "shared," mem_shared ","
    print "buff/cache," mem_buff_cache ","
    print "available," mem_available ","
  }
' > $FREEF
```

### 4. **Swap Usage by Process**
The script processes `/proc/[PID]/smaps` to gather swap usage information for each process. It sorts the processes based on swap usage and displays the top processes.

```bash
# Process and gather information for swap
for DIR in $(find /proc/ -maxdepth 1 -type d -regex "^/proc/[0-9]+"); do
    PID=$(echo $DIR | cut -d / -f 3)
    PROGNAME=$(ps -p $PID -o comm --no-headers)

    for SWAP in $(grep Swap $DIR/smaps 2>/dev/null | awk '{ print $2 }'); do
        let SUM=$SUM+$SWAP
    done

    if (( $SUM > 0 )); then
        # Save the raw swap usage in KB, no conversion yet
        echo -n "."  # Indicate progress
        echo -e "${PID},${SUM},${PROGNAME}" >> ${TMP}/${SCRIPT_NAME}.pid
        echo -e "${SUM},${PID},${PROGNAME}" >> ${TMP}/${SCRIPT_NAME}.kb
        echo -e "${PROGNAME},${SUM},${PID}" >> ${TMP}/${SCRIPT_NAME}.name
    fi
    let OVERALL=$OVERALL+$SUM
    SUM=0
done
```

### 5. **Top Swap Programs**
The script identifies the top 7 programs based on swap usage in KB, using `grep` and `sort` to filter the programs.

'''bash
TOP_PROGRAMS=$(cat ${TMP}/${SCRIPT_NAME}.pid | sort -t, -k2,2nr | head -n 7 | cut -d',' -f3 | paste -sd '|' -)

# Save swap usage details to separate CSV file
echo "PID,SwapUsed(kB),ProgramName" > $SWAPF
cat ${TMP}/${SCRIPT_NAME}.pid | grep -i -E "$TOP_PROGRAMS" >> $SWAPF  # Top 7 programs by swap usage (in KB)
'''

### 6. **Human-readable Conversion**
The script provides a helper function to convert the raw swap usage from KB into a human-readable format (GB, MB, or KB).

```bash
convert_to_human_readable() {
    local size_kb=$1
    if (( size_kb >= 1048576 )); then  # More than or equal to 1GB
        size_gb=$(echo "scale=2; $size_kb/1048576" | bc)
        echo "${size_gb} GB"
    elif (( size_kb >= 1024 )); then  # More than or equal to 1MB but less than 1GB
        size_mb=$(echo "scale=2; $size_kb/1024" | bc)
        echo "${size_mb} MB"
    else  # Less than 1MB
        echo "${size_kb} KB"
    fi
}
```

### 7. **Cleanup**
After collecting the data, the script deletes temporary files to keep the system clean.

```bash
rm -fr "${TMP}/"
rm -rf $MEMFILE $SWAPF $TOPF $FREEF
```

## Output Files

- **Top Processes (CPU, RAM)**: Displays top processes based on CPU and RAM usage.
- **Memory and Swap Usage**: Shows memory and swap usage in a human-readable format.
- **CSV Files**: The script outputs memory and swap usage data to CSV files for easy viewing or further processing.

## Output 

```
------------------------------MYPRODSERVER123--------------------------------

+-------------------------------- Uptime --------------------------------+
|  15:00:24 up 3 days, 16:23,  0 users,  load average: 3.87, 3.85, 4.38 |
+------------------------------------------------------------------------+

Top Output:
+--------+-------+----+-----+--------+--------+-------+---+-------+------+---------+------------+
|   PID  | USER  | PR | NI  | VIRT   | RES    | SHR   | S | %CPU  | %MEM | TIME+   | COMMAND    |
+--------+-------+----+-----+--------+--------+-------+---+-------+------+---------+------------+
| 72022  | mysql | 20 | 0   | 153.5g | 113.9g | 25256 | S | 406.2 | 51.5 | 9156:33 | mysqld     |
| 2897   | root  | 20 | 0   | 657084 | 43152  | 4240  | S | 6.2   | 0.0  | 4:34.64 | oneagentp+ |
| 129655 | root  | 20 | 0   | 176496 | 3216   | 1872  | R | 6.2   | 0.0  | 0:00.01 | top        |
| 1      | root  | 20 | 0   | 194644 | 5184   | 2680  | S | 0.0   | 0.0  | 2:09.27 | systemd    |
| 2      | root  | 20 | 0   | 0      | 0      | 0     | S | 0.0   | 0.0  | 0:00.33 | kthreadd   |
| 4      | root  | 0  | -20 | 0      | 0      | 0     | S | 0.0   | 0.0  | 0:00.00 | kworker/0+ |
| 6      | root  | 20 | 0   | 0      | 0      | 0     | S | 0.0   | 0.0  | 0:02.50 | ksoftirqd+ |
+--------+-------+----+-----+--------+--------+-------+---+-------+------+---------+------------+

Memory Usage:
+------------+------+------+
|            | MEM  | SWAP |
+------------+------+------+
| total      | 221G | 10G  |
| Used       | 117G | 107M |
| free       | 1.0G | 9.9G |
| shared     | 6.4M |      |
| buff/cache | 102G |      |
| available  | 102G |      |
+------------+------+------+

Overall RAM Usage
+------+------+------------+-------------------------------------------------------------------------------+
| CPU% | MEM% | MEM in MB  | PROCESS                                                                       |
+------+------+------------+-------------------------------------------------------------------------------+
| %CPU | %MEM | 0 MB       | COMMAND                                                                       |
| 174  | 51.4 | 116609 MB  | /tools/list/mysql/product/8.0.33/bin/mysqld                                   |
| 10.3 | 0.0  | 164.184 MB | oneagentnetwork                                                               |
| 0.4  | 0.0  | 151.426 MB | /tools/list/mysql/product/filebeat/filebeat-8.8.2-linux-x86_64/filebeat       |
| 2.3  | 0.0  | 77.2773 MB | /tools/list/mysql/product/metricbeat/metricbeat-8.8.2-linux-x86_64/metricbeat |
| 0.0  | 0.0  | 59.4961 MB | /usr/sbin/nsrexecd                                                            |
| 0.9  | 0.0  | 44.25 MB   | oneagentos                                                                    |
| 0.0  | 0.0  | 42.1406 MB | oneagentplugin                                                                |
| 0.0  | 0.0  | 30.5898 MB | /usr/bin/python2                                                              |
| 0.0  | 0.0  | 14.957 MB  | /opt/managesoft/libexec/fnms-docker-monitor                                   |
+------+------+------------+-------------------------------------------------------------------------------+

Overall swap used: 100.63 MB
+-------+--------------+---------------+
| PID   | SwapUsed(kB) | ProgramName   |
+-------+--------------+---------------+
| 1519  | 2.88 MB      | systemd-udevd |
| 1520  | 5.23 MB      | lvmetad       |
| 2408  | 1.59 MB      | VGAuthService |
| 2411  | 1.14 MB      | sssd          |
| 2494  | 1.04 MB      | ndtask        |
| 2533  | 1.28 MB      | sssd_be       |
| 2595  | 984 KB       | sssd_nss      |
| 2596  | 860 KB       | sssd_pam      |
| 2597  | 980 KB       | sssd_sudo     |
| 72022 | 77.26 MB     | mysqld        |
+-------+--------------+---------------+
```

### Temporary Files:
- `/tmp/ram_$$.csv`: Contains the RAM usage details of the top processes.
- `/tmpswap_$$.csv`: Contains swap usage details of the top processes.
- `/tmp/top_$$.csv`: Contains the top processes by CPU usage.
- `/tmp/free_$$.csv`: Contains overall memory and swap usage statistics.

## Screenshots

![de05ced2-524e-4d77-b7bb-a3db98989bb0](https://github.com/user-attachments/assets/3560dc24-8384-458b-87b6-fd62a8588f50)


![c5a5a31e-c102-4554-941a-34bca2e69a00](https://github.com/user-attachments/assets/7fa0fa63-d59f-4a5d-b990-17e73f749656)


## Conclusion

This script is a simple and effective way to monitor system resources in real-time, providing valuable insights into resource usage by different processes. It can be easily customized and extended as per your needs.

