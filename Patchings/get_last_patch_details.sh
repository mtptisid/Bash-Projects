#!/bin/bash
###########################################################################
######## Script for finding the patch details of the servers             ##
######## Created By    : MATHAPATI Siddharamayya                         ##
######## Creation Date : 31st January 2025	                             ##
######## Email         : msidrm455@gmail.com                             ##
######## Version       : 4.0                                             ##
###########################################################################

SCRDIR=/home/MY_TEAM/Patching
touch $SCRDIR/IPOPFILES/my_input_$(id -u)
FILE=$SCRDIR/IPOPFILES/my_input_$(id -u)
vi $FILE

if [ -s $FILE ];then
        echo " using the $FILE as input for the script"
else
        echo "The $FILE has no values"
        echo ""
        echo "Please paste your data to the  file once you run a Script."
        exit 1

fi


SENDER=root@$(uname -n).myorg.domain
EXECUTER=$(getent passwd `whoami`| awk -F: '{print $5}')
RECEIVER="$(getent passwd `whoami`| awk -F: '{print $5}'|awk '{up=""; low=""; for(i=1;i<=NF;i++) {gsub(/[^A-Za-z]/, "", $i); if (toupper($i) == $i) up = up $i; else low = low $i;} print up ":" low }'|awk -F: '{print tolower($0)}'| awk -F: '{OFS="."; print $2, $1}')@myorg.domain"

CHARACTERCOUNT=${#RECEIVER}
if [ $CHARACTERCOUNT -lt 30 ]; then
        RECEIVER=""
        read -p "Enter your Email Address:" NEWEMAIL
        RECEIVER=$NEWEMAIL
else
        echo "mail will be sent to $RECEIVER"
fi


read -p "Do you wanna receive a output in mail[Yes/No}:" MAILCONF


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

  # Add padding of 1 character to each column width
  for i in "${!col_widths[@]}"; do
    col_widths[$i]=$((col_widths[$i] + 1))
  done

  # Print a border with column separators and an additional '-' in each column
  print_border() {
    printf "+"
    for width in "${col_widths[@]}"; do
      printf "%0.s-" $(seq 1 "$((width + 1))")  # Add an extra '-' for each column
      printf "+"
    done
    printf "\n"
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


output_file=$SCRDIR/IPOPFILES/my_output_$(id -u)
mailto_file=$SCRDIR/IPOPFILES/LAST_PATCH_LIST$(id -u).csv
>$output_file
>$mailto_file

echo -e "SERVER,RHEL Version,Yum ID,Patch date,Action(s),latest Kernal info,kernel dates and time,Uptime" > $output_file
echo -e "SERVER,RHEL Version,Yum ID,patch date,Action(s),latest Kernal info,kernel dates and time,uptime" >> $mailto_file
function checklastpatch {
               suptime=`ssh -q -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server uptime |awk -F, '{print $1}'| awk '{if (NF==4) print $(NF-1),$NF; else if (NF==3) print $NF}'`
               rhelver=$(ssh -q -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server cat /etc/redhat-release|grep -oP '\d+\.\d+')
                yumhist=`ssh -q -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo yum history | egrep -v "entitlement|plugins|subscription-manager|history|Uploading|^ID|^--" |awk -F'|' -v OFS='|' '{gsub(" ", "", $4); if ($4 ~ /^Up/ || ($4 ~ /U/)) {print $1, $3, $4; exit}}'`
                kerinfo=`ssh -q -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo rpm -qa --last kernel | head -1`
                read kernel datesk <<< $(echo $kerinfo)
                IFS='|' read id dates actions <<< $(echo $yumhist)
                if [[ "$actions" == *"E,I,O,U"* || "$actions" == *"E,I,U"* || "$actions" == *"I,U"* ]];then
                        actions=$( echo $actions | sed 's/,/-/g')
                fi
                dates=$(echo "$dates"|awk '{$1=$1};1')
                echo "$server,$rhelver,$id,$dates,$actions,$kernel,$datesk,$suptime" >> $output_file
                echo "$server,$rhelver,$id,$dates,$actions,$kernel,$datesk,$suptime" >> $mailto_file


}


for server in `cat $FILE`;do
        ssh -q -n -o ConnectTimeout=4 -o BatchMode=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -p 77 -l sysadm $server sudo uptime > /dev/null 2>&1
        if [ $? = 0 ] ; then
                PORT=77
                checklastpatch
                else
                       ssh -q -n -o ConnectTimeout=4 -o BatchMode=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -p 22 -l sysadm $server sudo uptime > /dev/null 2>&1
                       if [ $? = 0 ];then
                       PORT=22
                       checklastpatch
                        else
                                #echo -e "==================================The \033[41;30m $server \033[40;37m is not accessible====================="
                                echo -e "$server" >> $SCRDIR/IPOPFILES/errorlogs_$(id -u).txt
                                echo "$server,,,,,Connection KO" >> $mailto_file
                     fi
        fi
done

#cat $output_file | awk 'NR==1 {print $0 | "column -t -s ','"} NR==2; NR>2 {print $0 | "column -t -s ','"}'
#column -t -s ',' < $output_file



echo ""
if [[ "${MAILCONF}" =~ ^[Yy] ]];then
        echo -e "\n\n--------------------------------------------------------------- \n find the attchments;`cat $SCRDIR/IPOPFILES/errorlogs_$(id -u).txt`"|mailx -a $mailto_file -r $SENDER -s " $0 output file for $DATE" $RECEIVER > /dev/null 2>&1
        echo ""
        date
        format_table $output_file
        echo ""
        echo -e "                You have received mail from \033[36m $SENDER\033[0m  on \033[32m $RECEIVER \033[0m "
        echo ""
        echo -e "                                                \033[4;35m The script is finished for all the servers \033[0m"
else
        date
        format_table $output_file
fi
echo ""
if [ -s "$SCRDIR/IPOPFILES/errorlogs_$(id -u).txt" ];then
        echo "---------------------------------------------"
        cat $SCRDIR/IPOPFILES/errorlogs_$(id -u).txt
        echo -e "\nThese above servers were not accessible"
        echo ""
else
        echo ""
fi
rm -rf $SCRDIR/IPOPFILES/errorlogs_$(id -u).txt


