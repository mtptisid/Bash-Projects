#!/bin/bash

# Function to add the service configuration to the remote server
add_service_to_server() {
    server=$1

    echo "Adding service to $server..."

    # Append the service configuration to the remote server's systemd service file
    ssh -q -p 22 user@"$server" "
        # Append service content to the service file
        sudo bash -c 'tee -a /usr/local/lib/systemd/system/<service_name>.service <<EOF
[Unit]
Description=<Description>
After=network.target sssd.service
AssertPathExists=!/etc/noprod

[Service]
Type=forking
RemainAfterExit=yes
ExecStart=/Path/to/start/script
ExecReload=/bin/kill -HUP \$MAINPID
ExecStop=/path/to/stop/script
KillMode=process
Restart=on-failure
RestartSec=30
User=<YourUser>

[Install]
WantedBy=multi-user.target
EOF'

        # Change security context for start-ag and shut-ag
        sudo chcon system_u:object_r:bin_t:s0 /Path/to/start/script
        sudo chcon system_u:object_r:bin_t:s0 /path/to/stop/script
    "
} > /dev/null 2>&1


start_service () {
        server=$1
        echo "Starting $server..."
        ssh -q -p 77 sysadm@"$server" "
                        # Enable and start the service
                        sudo systemctl enable ctmagent
                        sudo systemctl restart ctmagent
                        sudo systemctl status ctmagent
"

}

# Check if the argument is a file or a single server
if [[ -f "$1" ]]; then
    # Argument is a file containing a list of servers
    for server in `cat "$1"`; do
        printf -- '-%.0s' {1..189};echo
        printf -- ' %.0s' {1..80};echo -e "\e[1;33m $server\e[0m\n"
        printf -- '-%.0s' {1..189};echo

        add_service_to_server "$server"
        start_service "$server"
        printf -- '-%.0s' {1..189};echo
    done
elif [[ -n "$1" ]]; then
    # Argument is a single server
    server="$1"
    printf -- '-%.0s' {1..189};echo
    printf -- ' %.0s' {1..80};echo -e "\e[1;33m $server\e[0m\n"
    printf -- '-%.0s' {1..189};echo

    add_service_to_server "$server"
    start_service "$server"
    printf -- '-%.0s' {1..189};echo
else
    echo "Usage: $0 <server|file>"
    echo "  - server: single server IP or hostname"
    echo "  - file: file containing a list of servers"
    exit 1
fi
