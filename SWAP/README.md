# Remote Swap Management Script

This project provides a script for managing swap space on remote servers. It includes functionalities for:

- **Listing current swap and memory usage**
- **Extending swap space**
- **Creating swap files**
- **Round floating-point numbers** (used for various calculations)
  
The script automates several tasks related to swap management to ensure that swap space is sufficient for server operation. You can extend swap partitions, create new swap files, and check current swap/memory usage on your remote servers.

## Project Features

- **Swap Space Management**: Extends or creates new swap space based on server memory and available volume group space.
- **Memory Usage Information**: Fetches and reports current memory and swap usage, as well as available memory for swap off/on operations.
- **Remote Server Management**: Allows managing multiple servers remotely using SSH.
- **Swap Reporting**: Creates CSV reports of swap and memory usage for later analysis.
  
## Functions Overview

### 1. `round_float()`

**Purpose**: This function rounds a floating-point number to the nearest integer based on its decimal part.

#### How it works:
- Accepts a number as input.
- Splits the number into integer and decimal parts.
- If the decimal part is greater than or equal to 5, it rounds up the integer part.
- Otherwise, it returns the integer part unchanged.

#### Example Usage:
```bash
round_float 12.54  # Returns 13
round_float 12.49  # Returns 12
```

---

### 2. `swaplisting()`

**Purpose**: This function checks the swap and memory usage on a remote server and stores the results into a CSV file.

#### How it works:
- Retrieves the current volume group (`vg00` or `root`) information from the remote server.
- Fetches swap usage information (total, used, and free) from the `free -mh` command.
- Fetches memory usage information (total, used, free, and available) from the `free -mh` command.
- Outputs the collected data into a CSV format.

#### Example Usage:
```bash
swaplisting
```

This function outputs the following details for each server:
- Total swap space
- Used swap space
- Free swap space
- Free space in volume group
- Available memory
- Server name

---

### 3. `swapextend()`

**Purpose**: This function extends the swap space on a remote server if there is enough free space in the volume group and sufficient available memory.

#### How it works:
- **Step 1**: Checks if the desired swap size (`DESIREDVALUE`) is equal to the current swap size.
  - If yes, it outputs that the swap is already at the desired size.
  - If no, it checks the available space in the volume group (`VG`) and ensures there is enough memory to perform a `swapoff` operation.
  
- **Step 2**: If there is enough free space and memory, it extends the swap space by a certain amount.
  - **If successful**, it extends the swap, formats the swap, and enables it.
  - Outputs a confirmation message and updates CSV files.

#### Example Usage:
```bash
swapextend
```

**Note**: This function handles the entire process of swap space extension and ensures that your system is prepared before extending the swap.

---

### 4. `create_swapfile()`

**Purpose**: This function creates a new swap file on the remote server.

#### How it works:
- Creates a swap file of the specified size on the remote server.
- Sets the correct permissions and formats the file as swap space.
- Activates the swap file.

#### Example Usage:
```bash
create_swapfile 2G
```

This will create a 2 GB swap file on the remote server.

---

## Setup & Installation

### Prerequisites

Before using the script, ensure that:
- You have SSH access to the remote server(s).
- You have `sudo` privileges on the remote server(s).
- You have `awk`, `ssh`, and `free` commands available on your system.

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/swap-management.git
   cd swap-management
   ```

2. Make the script executable:
   ```bash
   chmod +x swap_management.sh
   ```

3. Edit the script to set your desired `DESIREDVALUE`, server information, and other configurations.

4. Optionally, create a cron job to schedule regular swap management tasks.

---

## Configuration

You need to configure the following variables before using the script:

- **PORT**: SSH port for remote access.
- **server**: The target server or a list of servers to manage.
- **DESIREDVALUE**: The desired swap size in GB for extension.
- **mailto_file**: The CSV file where the output will be logged.
- **output_file**: The output log file that will include swap and memory information.

---

## Usage

1. **Listing Swap and Memory Usage**
   To check the swap and memory usage for a remote server, run:
   ```bash
   ./swap_management.sh swaplisting
   ```

2. **Extending Swap Space**
   To extend the swap space to a desired size, run:
   ```bash
   ./swap_management.sh swapextend
   ```

3. **Creating a New Swap File**
   To create a swap file, run:
   ```bash
   ./swap_management.sh create_swapfile <size>
   ```

   Example:
   ```bash
   ./swap_management.sh create_swapfile 1G
   ```

---

## Logging & Output

The script generates two types of output:

1. **CSV Output**: This file logs the swap and memory status for each server, including the current swap and memory details. This file is saved in the `mailto_file` location.

2. **Detailed Output**: The script will also generate a detailed output log of the operations, which includes the results of swap extension or creation tasks.

---

## Advanced Usage

You can extend the script to automate swap management across multiple servers by modifying the `server` variable or using a configuration file with server details.

1. **Manage Multiple Servers**
   - To manage multiple servers, create a text file containing the list of server IPs or hostnames, one per line. Modify the script to read the server list and perform tasks on each server.

2. **Automate via Cron**
   - You can automate the script by scheduling it to run periodically using a cron job:
   ```bash
   crontab -e
   ```

   Add the following entry to run the script every day at midnight:
   ```bash
   0 0 * * * /path/to/swap_management.sh swapextend
   ```

---

## Contribution

Feel free to fork this repository and submit pull requests for improvements, bug fixes, or new features.

---



