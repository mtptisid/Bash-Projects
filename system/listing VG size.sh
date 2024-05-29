#!/bin/bash
###########################################################################
######## Script to genrate a list of VG free size                        ##
######## Created By    : MATHAPATI Siddharamayya                         ##
######## Creation Date : 30th January 2024                               ##
######## Email         : msidrm455@gamil.com                             ##
######## Version       : 2.0                                             ##
###########################################################################


FSUF="$(id -u)_$$"
touch IPOPFILES/my_input_$FSUF
FILE=IPOPFILES/my_input_$FSUF
vi $FILE

if [ -s $FILE ];then
        echo " using the $FILE as input for the script"
else
        echo "The $FILE has no values"
        echo ""
        echo "Please paste your data to the  file once you run a Script."
        exit 1

fi


SENDER=root@$(uname -n).example.com
EXECUTER=$(getent passwd `whoami`| awk -F: '{print $5}')
RECEIVER="$(getent passwd `whoami`| awk -F: '{print $5}'|awk '{up=""; low=""; for(i=1;i<=NF;i++) {gsub(/[^A-Za-z]/, "", $i); if (toupper($i) == $i) up = up $i; else low = low $i;} print up ":" low }'|awk -F: '{print tolower($0)}'| awk -F: '{OFS="."; print $2, $1}')-@gmail.com"

CHARACTERCOUNT=${#RECEIVER}
if [ $CHARACTERCOUNT -lt 30 ]; then
        RECEIVER=""
        read -p "Enter your Email Address:" NEWEMAIL
        RECEIVER=$NEWEMAIL
else
        echo "mail will be sent to $RECEIVER"
fi


read -p "Do you wanna receive a output in mail[Yes/No}:" MAILCONF


output_file=IPOPFILES/my_output_$FSUF
mailto_file=IPOPFILES/VG_LIST$FSUF.csv
>$output_file
>$mailto_file

echo -e "SERVER,VG NAME, VG SIZE, VG FREE " >> $mailto_file
echo -e " SERVER,| VG NAME, | VG SIZE, | VG FREE" >> $output_file


function checklastpatch {
                vglist=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo vgs | grep -E "vg00|root" | tail -n +2 | awk '{print $1,$(NF -1), $NF}'`

                read vgname vgsize vgfree <<< $(echo $vglist)
                echo "$server,| $vgname | $vgsize | $vgfree |" >> $output_file
                echo "$server,$vgname,$vgsize,$vgfree" >> $mailto_file


}




for server in `cat $FILE`;do
        ssh -n -o ConnectTimeout=4 -o BatchMode=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -p 77 -l sysadm $server sudo uptime > /dev/null 2>&1
        if [ $? = 0 ] ; then
                PORT=77
                checklastpatch
                else
                       ssh -n -o ConnectTimeout=4 -o BatchMode=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -p 22 -l sysadm $server sudo uptime > /dev/null 2>&1
                       if [ $? = 0 ];then
                       PORT=22
                       checklastpatch
                        else
                                #echo -e "==================================The \033[41;30m $server \033[40;37m is not accessible====================="
                                echo -e "$server" >> IPOPFILES/errorlogs_$FSUF.txt
                                echo "$server,,,Connection KO" >> $mailto_file
                     fi
        fi
done






echo ""
if [[ "${MAILCONF}" =~ ^[Yy] ]];then
        echo -e "\n\n--------------------------------------------------------------- \n find the attchments;`cat IPOPFILES/errorlogs_$FSUF.txt`"|mailx -a `pwd`/$mailto_file -r $SENDER -c "msidrm455@gmail.com" -s " $0 output file for $DATE" $RECEIVER > /dev/null 2>&1
        echo ""
        column -t -s ',' < $output_file
        echo ""
        echo -e "                You have received mail from \033[36m $SENDER\033[0m  on \033[32m $RECEIVER \033[0m "
        echo ""
        echo -e "                                                \033[4;35m The script is finished for all the servers \033[0m"
else
        column -t -s ',' < $output_file
fi
echo ""
if [ -s "IPOPFILES/errorlogs_$FSUF.txt" ];then
        echo "---------------------------------------------"
        cat IPOPFILES/errorlogs_$FSUF.txt
        echo -e "\nThese above servers were not accessible"
        echo ""
else
        echo ""
fi
rm -rf IPOPFILES/errorlogs_$FSUF.txt

