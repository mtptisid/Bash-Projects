# User Disabling Script

## Overview
This script is designed to disable and lock user accounts on remote servers, take backups of essential system files, and send a report about the actions performed. It supports multiple servers and users, performing the following operations:

- Backing up user-related files (e.g., `/etc/passwd`, `/etc/shadow`) before making any changes.
- Locking the specified user accounts by disabling their shell access and locking their passwords.
- Generating an HTML and CSV report about the actions taken, including any errors or failed actions.
- Sending an email with the generated report and log files as attachments.

## Features
- **User Locking**: The script disables user accounts by locking the password and changing the user's shell to `/sbin/nologin`.
- **Backup**: It creates backups of important system files like `/etc/passwd` and `/etc/shadow` before making any modifications.
- **Error Logging**: If a server is inaccessible or the user cannot be found, it logs errors in a text file.
- **HTML & CSV Report**: After processing, the script generates an HTML report and a CSV file summarizing the actions and results.
- **Email Notification**: The script sends an email with the generated report and log files attached.

## Requirements
- SSH access to remote servers.
- A valid list of servers and users in a CSV format (tab-separated).
- `mailx` utility installed for email notifications.
- Sufficient permissions (e.g., `sudo`) to modify user accounts and read system files.

## Usage
1. Prepare a CSV file containing the list of servers and users to be processed. Each row should contain a server name and a user account, separated by a tab.
2. Run the script with the following command:
   '''
   ./user_disabling_script.sh <path_to_csv_file>
   '''
   Example:
   '''
   ./user_disabling_script.sh users_list.csv
   '''

3. The script will:
   - Connect to each server in the CSV file.
   - Lock the specified user account.
   - Take backups of relevant files.
   - Generate and send a report via email.

## Email Configuration
- **Sender**: The script uses the `root` account of the local machine for sending emails. 
- **Receiver**: The email address is determined automatically based on the logged-in user's details. If the auto-determined email is invalid, the script will prompt you to enter a new email address.

## Output Files
- **`USERDISLOGS/`**: This directory stores the log files for each server processed.
- **`errorlogs.txt`**: Contains the list of servers that could not be reached.
- **`USES_LOCK_OUTPUT.html`**: An HTML report summarizing the results of the user disabling operations.
- **`USES_LOCK_OUTPUT.csv`**: A CSV file containing server, user, shell status, and whether the user was disabled.

## Example of Report
The HTML report will contain:
- A table with columns for the server name, user, shell status, and whether the user was successfully disabled.
- Each server has a corresponding box displaying either a success or failure message with details.

## Notes
- The script checks both port 22 and port 77 for connectivity to each server.
- If a server is not reachable on both ports, it will be logged as inaccessible.
- If a user cannot be found on a server, an error is logged for that user.

## Troubleshooting
- **"Connection KO"**: This indicates that the server could not be accessed on both ports. Ensure that the server is running and accessible.
- **"User not found"**: This means the specified user does not exist on the server.

## Example Output

- **HTML Report**: The HTML report will display a visual summary of the user lock status for each server.
- **Email**: The email will contain the generated HTML report and any error logs.

## Author
Created by: **Siddharamayya Mathapathi**  
Email: [msidrm455@gmail.com](mailto:msidrm455@gmail.com)

## License
This script is provided as-is. Use it at your own risk.
