#!/bin/bash
###########################################################################
######## Script to modify the uid and gid in fstab fro CIFS entries      ##
######## Created By    : MATHAPATI Siddharamayya                         ##
######## Creation Date : 21st January 2025                               ##
######## Email         : msidrm455@gmail.com                             ##
######## Version       : 2.0                                             ##
###########################################################################

FSUF="$(id -u)_$$"

# Define color codes for easier reading
BLUE='\e[1;34;47m'
RED='\e[1;31m'
WHITE='\e[1;37;0;5m'
BLACK='\e[1;33;0;47m'
CYAN='\e[1;36;0;5m'
YELLOW='\e[33m'
MAGENTA='\e[35m'
GREEN='\e[32m'
RESET='\e[0m'


SCRDIR=/home/myuser/scripts
touch $SCRDIR/INPUTFILES/my_input_$FSUF
FILE=$SCRDIR/INPUTFILES/my_input_$FSUF
vi $FILE

if [ -s $FILE ];then
        echo
        echo -e "${YELLOW}using the $(basename "$FILE") as input for the script ${RESET}"
        echo
else
        echo -e "${RED}The $(basename "$FILE") has no values${RESET}"
        echo ""
        echo "Please paste your data to the  file once you run a Script."
        exit 1

fi
echo -e -n "${MAGENTA}Do you wanna receive a output in mail[Yes/No}: ${RESET}"
read MAILCONF
echo

MAILCONF=$(echo "$MAILCONF" | xargs)
#echo $MAILCONF

if [[ "${MAILCONF,,}" =~ ^(y|yes) ]]; then
        SENDER=root@$(uname -n).myorga.com
        EXECUTER=$(getent passwd `whoami`| awk -F: '{print $5}')
        RECEIVER="$(getent passwd `whoami`| awk -F: '{print $5}'|awk '{up=""; low=""; for(i=1;i<=NF;i++) {gsub(/[^A-Za-z]/, "", $i); if (toupper($i) == $i) up = up $i; else low = low $i;} print up ":" low }'|awk -F: '{print tolower($0)}'| awk -F: '{OFS="."; print $2, $1}')-@myorga.com"

        CHARACTERCOUNT=${#RECEIVER}
        if [ $CHARACTERCOUNT -lt 30 ]; then
                RECEIVER=""
                echo -e -n "${GREEN}Enter your Email Address: ${RESET}"
                read NEWEMAIL
                RECEIVER=$NEWEMAIL
                echo
        else
        echo "mail will be sent to $RECEIVER"
        fi

fi


output_file=$SCRDIR/INPUTFILES/my_output_$FSUF
mailto_file=$SCRDIR/INPUTFILES/RESULTS_LIST_$FSUF.csv
>$output_file
>$mailto_file

echo -e "SERVER,SHARE NAME,MOUNT NAME,USER,GROUP,UID,GID,STATUS" >> $mailto_file
echo -e "SERVER,SHARE NAME,MOUNT NAME,USER,GROUP,UID,GID,STATUS" >> $output_file


# Function to format the table
format_table() {
  local file=$1

  # Read the header row and calculate the number of columns
  local header=$(head -n 1 "$file")
  local num_cols=$(awk -F',' '{print NF}' <<< "$header")

  # Calculate the maximum width for each column (including padding)
  local col_widths=()
  for ((i=1; i<=num_cols; i++)); do
    col_widths+=($(awk -F',' -v col="$i" '{
      gsub(/^ +| +$/, "", $col);
      if (length($col) > max) max = length($col)
    } END { print max }' "$file"))
  done

  # Add padding of 5 characters to each column width
  for i in "${!col_widths[@]}"; do
    col_widths[$i]=$((col_widths[$i] + 1))
  done

  # Calculate the total width of the table (including borders and separators)
  local total_width=0
  for width in "${col_widths[@]}"; do
    total_width=$((total_width + width + 1)) #added sep space val
  done
  total_width=$((total_width + 7)) # Include leftmost and rightmost border for this script may change for others.

  # Print a border
  print_border() {
    printf "+%s+\n" "$(printf '%*s' "$total_width" '' | tr ' ' '-')"
  }

  # Print a row (aligned to column widths)
  print_row() {
    local row="$1"
    printf "|"
    IFS=',' read -r -a cols <<< "$row"
    for ((i=0; i<num_cols; i++)); do
      printf " %-${col_widths[$i]}s|" "${cols[$i]}"
    done
    printf "\n"
  }

  # Print the entire table
  print_border
  print_row "$header"
  print_border
  tail -n +2 "$file" | while IFS= read -r row; do
    print_row "$row"
  done
  print_border
}



# Function to modify the FStab with right UID and GID
modify_fstab() {
    # Backup fstab
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo cp -p /etc/fstab /etc/fstab_$(date +%d%m%y).bkp > /dev/null 2>&1

    # Get the CIFS entries from /etc/fstab
    cifslist=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo cat /etc/fstab | grep -i cifs | grep -v "^#"|awk 'BEGIN { FS=" "; OFS=":" }{print $1,$2,$3,$4}') > /dev/null 2>&1

        while IFS=: read -r share mount type options ;do
        read USER GROUP <<< $(echo "$options" | grep -oP 'uid=[^,]+|gid=[^,]+' | tr '\n' ' ' | sed 's/uid=//;s/gid=//')

   # Getting UID and GID from the remote server
        UIDGOT=$(ssh -n -tt -q -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo id -u "$USER")
        GIDGOT=$(ssh -n -q -tt -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo getent group "$GROUP" | cut -d: -f3)

        uidpat="uid=$USER"
        gidpat="gid=$GROUP"

        # Remove any carriage return characters from the variables
        uidpat=$(echo "$uidpat" | tr -d '\r')
        gidpat=$(echo "$gidpat" | tr -d '\r')

        # Set substitution values
        uidsub="uid=$UIDGOT"
        gidsub="gid=$GIDGOT"

        # Remove carriage returns from substitution values as well
        uidsub=$(echo "$uidsub" | tr -d '\r')
        gidsub=$(echo "$gidsub" | tr -d '\r')



        ssh -n -tt -q -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server \
                "sudo sed -i -e '/^[^#]/s/$uidpat/$uidsub/' -e '/^[^#]/s/$gidpat/$gidsub/' /etc/fstab"

        #echo "$output"| grep -i $uidsub

        echo -e "$server,`echo $share|sed 's/\/\///g'`,$mount,$USER,$GROUP,` echo $UIDGOT|tr -d '\r'`,`echo $GIDGOT|tr -d '\r'`,Changed" >> $mailto_file
        echo -e "$server,`echo $share|sed 's/\/\///g'`,$mount,$USER,$GROUP,`echo $UIDGOT|tr -d '\r'`,`echo $GIDGOT|tr -d '\r'`,Changed" >> $output_file

        #echo

        done <<< "$cifslist"


}


CNT=1
for server in `cat $FILE`;do
        ssh -n -o ConnectTimeout=4 -o BatchMode=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -p 77 -l sysadm $server sudo uptime > /dev/null 2>&1
        if [ $? = 0 ] ; then
                PORT=77
                printf "\033[0;32m%s %s\033[0m |%n" "$CNT.[  $server ]"
                modify_fstab
                echo -e "${GREEN}  Completed... ${RESET} "
                else
                       ssh -n -o ConnectTimeout=4 -o BatchMode=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -p 22 -l sysadm $server sudo uptime > /dev/null 2>&1
                       if [ $? = 0 ];then
                       PORT=22
                       printf "\033[0;32m%s %s\033[0m |%n" "$CNT.[  $server ]"
                       modify_fstab
                       echo -e "${GREEN}  Completed... ${RESET} "
                        else
                                #echo -e "==================================The \033[41;30m $server \033[40;37m is not accessible====================="
                                printf "\033[0;32m%s %s\033[0m |%n" "$CNT.[  $server ]"
                                echo -e "${RED}  Not Reachable... ${RESET} "
                                echo -e "$server" >> $SCRDIR/INPUTFILES/errorlogs_$FSUF.txt
                                echo "$server,,,,,,,Connection KO" >> $mailto_file
                     fi
        fi
        CNT=`expr $CNT + 1`
done





if [[ "${MAILCONF}" =~ ^[Yy] ]];then
        echo
        echo -e "${GREEN}Sending mail ........ ${RESET}"
        echo -e "\n\n--------------------------------------------------------------- \n find the attachments; $(if [[ -f "$SCRDIR/INPUTFILES/errorlogs_$FSUF.txt" ]];then cat $SCRDIR/INPUTFILES/errorlogs_$FSUF.txt; fi)"|mailx -a $mailto_file -r $SENDER -c "msidrm455@myorga.com" -s " $0 output file for $DATE" $RECEIVER > /dev/null 2>&1
        echo ""
        echo -e -n "${RED}Mail has been sent successfully do want to print the output table as well on screen[Yes/No}: ${RESET}"
        read OUTCONF
        OUTCONF=$(echo "$OUTCONF" | xargs)
        if [[ "${OUTCONF}" =~ ^[Yy] ]];then
                echo
                format_table $output_file
        fi
        echo ""
        echo -e "                You have received mail from \033[36m $SENDER\033[0m  on \033[32m $RECEIVER \033[0m "
        echo ""
        echo -e "                                                \033[4;35m The script is finished for all the servers \033[0m"
else
        echo
        format_table $output_file
        echo
        echo -e "                                                \033[4;35m The script is finished for all the servers \033[0m"
fi
echo ""
if [ -e "$SCRDIR/INPUTFILES/errorlogs_$FSUF.txt" ];then
        echo "---------------------------------------------"
        cat $SCRDIR/INPUTFILES/errorlogs_$FSUF.txt
        echo -e "\nThese above servers were not accessible"
        echo ""
else
        echo ""
fi
rm -rf $SCRDIR/INPUTFILES/errorlogs_$FSUF.txt > /dev/null 2>&1
