# Systemd Service Deployment Script

This script deploys and manages a systemd service across multiple remote servers.

## Purpose
1. Deploys a systemd service configuration to remote servers
2. Sets up SELinux security context for service scripts
3. Enables and starts the deployed service
4. Works with both individual servers and server lists


## Prerequisites
- SSH access to target servers with appropriate credentials
- sudo privileges on target servers
- Consistent username and port access across servers
- Target servers must have systemd init system


## Usage

```
./script_name <server|file>
  
Where:
- <server>: IP address or hostname of a single server
- <file>:    Text file containing list of servers (one per line)

Examples:
  ./deploy_service.sh 192.168.1.100
  ./deploy_service.sh server_list.txt
```

## Functions

### add_service_to_server()

- Connects via SSH (port 22) as 'user'
- Appends service configuration to:
  /usr/local/lib/systemd/system/<service_name>.service
- Sets SELinux context for start/stop scripts
- Operates silently (output redirected to /dev/null)


### start_service()

- Connects via SSH (port 77) as 'sysadm'
- Enables and restarts the service using systemctl
- Shows service status after restart


## Important Notes
1. Requires replacement of placeholder values:
   - <service_name> in service file path
   - <Description> in service unit
   - <YourUser> in service configuration
   - Script paths (/Path/to/start/script, /path/to/stop/script)

2. Uses different ports and users for different operations:
   - Port 22/user for service deployment
   - Port 77/sysadm for service management

3. Includes SELinux context configuration:
   - Sets bin_t type for service scripts

4. Features formatted output with color highlighting

5. Includes error handling for:
   - Missing arguments
   - Invalid input types
   - SSH connection failures

## Security Considerations

- Store credentials securely (consider SSH keys)
- Limit sudo privileges to necessary commands
- Audit service scripts before deployment
- Maintain proper file permissions


## Maintenance

1. Update placeholders before use
2. Test with single server before batch deployment
3. Monitor service status on target servers
4. Consider adding rollback functionality
