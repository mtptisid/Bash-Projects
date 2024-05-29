#!/bin/bash
###########################################################################
######## Script for disabling and deleting user                          ##
######## Created By    : MATHAPATI Siddharamayya                         ##
######## Creation Date : 12th December 2023                              ##
######## Email         : msidrm455@gmail.com                             ##
######## Version       : 2.0                                             ##
###########################################################################

#set -x
#  Check if the file provided is CSV or not
if [ -z "$1" ]; then
  echo ""
  echo "Usage: $0 <csv_file>"
  cat /home/RUN_TEAM/USER_DISABLE/READ-ME.txt
  exit 1
fi
#  creating a directory to save output files
mkdir -p `pwd`/INPUTFILES/USERDISLOGS
LOGDIR=INPUTFILES/USERDISLOGS/

#removing all old data from output files
>errorlogs.txt
>USES_LOCK_OUTPUT.html
>userna.txt
>USES_LOCK_OUTPUT
tput clear
>email_body.html
>USES_LOCK_OUTPUT.csv

#defining the sender and receiver for mail service
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

#created a function to call later
function userdisabling {
                server_filename=$(echo "$server" | tr -d '[:space:]')
                #creating a file with server name in your directory
                output_file="$LOGDIR/${server_filename}_output.txt"
                >"$output_file"
                echo ""
                #echo "-- `date +%F/%T` --" >> "$output_file"
                echo -e "================================= \033[37;44m $server \033[0m ====================================="
                echo -e "================================= $server =====================================" >> "$output_file"
                echo ""
                echo -e "*************** Taking backup for the \033[1;33m $user \033[0m *****************"

                Serverfulname=`ssh -n -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p $PORT -l sysadm $server sudo hostname -f`

                #taking backup of the user from passwd command and file
                ssh -n -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p $PORT -l sysadm $server sudo cp /etc/passwd /etc/passwd_$(date +%d%m%y).bkp > /dev/null 2>&1
                ssh -n -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p $PORT -l sysadm $server sudo cp /etc/shadow /etc/shadow_$(date +%d%m%y).bkp > /dev/null 2>&1

                #taking backup of the user details from passwd file and command
                old_paaswd_output=`ssh -n -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p $PORT -l sysadm $server sudo cat /etc/passwd | grep -i $user` > /dev/null 2>&1
                old_passwd_output=`ssh -n -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p $PORT -l sysadm $server sudo passwd -S $user` > /dev/null 2>&1

                #we are locking the user
                echo "----------------------------------------------------------------------"
                echo ""
                #echo -e "               Locking the user  \033[31m $user \033[0m"
                ssh -n -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p $PORT -l sysadm $server sudo passwd -l $user
                ssh -n -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p $PORT -l sysadm $server sudo /usr/sbin/usermod -L $user > /dev/null 2>&1
                if [ $? = 0 ] ; then
                        echo -e "\t \033[42;30m $user is locked successfully \033[40;37m"
                        echo ""
                else
                        echo ""
                        echo -e "\t \033[41;30m Unable to lock the $user / $user not found \033[40;37m"
                        #echo "Unable to lock the $user / $user not found" >> "$output_file"
                fi

                #we are changing the shell of the user
                ssh -n -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p $PORT -l sysadm $server sudo /usr/sbin/usermod -s /sbin/nologin $user > /dev/null 2>&1
                if [ $? = 0 ] ; then
                        echo -e "\t \033[42;30m $user shell changed to /sbin/nologin successfully \033[40;37m"
                        echo ""
                        userdiabled=Yes
                else
                        echo ""
                        echo -e "\t \033[41;30m Unable to change the shell for $user / $user not found \033[40;37m"
                        #echo "Unable to change the shell for $user / $user not found" >> "$output_file"
                        echo "User $user not found in $server" >> userna.txt
                        userdisabled=NO
                fi
                echo ""
                #echo -e "               User  \033[31m $user \033[0m has been locked"
                echo "----------------------------------------------------------------------"

                #taking the post lock output of passwd com and file for user
                paaswd_output=`ssh -n -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p $PORT -l sysadm $server sudo cat /etc/passwd | grep -i $user` > /dev/null 2>&1
                user_output=`ssh -n -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p $PORT -l sysadm $server sudo passwd -S $user` > /dev/null 2>&1

                #redirecting all the data in log file which is created with servers name
                if [ -n "$old_paaswd_output" ]; then

                        echo "--------------------------------------------------------------------------------------------" >> "$output_file"
                        echo "" >> "$output_file"
                        echo -e "   ***************backup for the $user *****************" >> "$output_file"

                        echo "    ------------Entry of the user in PASSWD file-----------" >> "$output_file"
                        echo -e "     Before:\t $old_paaswd_output" >> "$output_file"
                        echo -e "     After :\t $paaswd_output" >> "$output_file"
                        echo "" >> "$output_file"

                        echo "    ------------Backup of passwd-----------" >> "$output_file"
                        echo -e "     Before:\t $old_passwd_output" >> "$output_file"
                        echo -e "     After :\t $user_output" >> "$output_file"
                else
                        echo " $user not found $server" >> "$output_file"
                fi
                shellstatus=`echo "$paaswd_output"|awk -F: '{print $NF}'`
                passwdstatus=`echo "$user_output"|awk '{print $8,$9}'`
                #echo -e "<tr><td bgcolor="khaki" align="center">`cat $outputfile`</td></tr>" >> USES_LOCK_OUTPUT.html
                echo -e "<tr><td bgcolor="khaki" align="center">$server</td><td bgcolor="khaki" align="center">$user</td><td bgcolor="khaki" align="center">$shellstatus</td><td bgcolor="khaki" align="center">$userdisabled</td></tr>" >> email_body.html
                echo "$server,$user,$shellstatus,$userdiabled" >>USES_LOCK_OUTPUT.csv
                echo "<div class="box" onclick="toggleBox-sidd">" >> USES_LOCK_OUTPUT.html
                echo "<div class="box-label">" >> USES_LOCK_OUTPUT.html
                echo "$Serverfulname"  >> USES_LOCK_OUTPUT.html
                echo "<div class="ok">" >> USES_LOCK_OUTPUT.html
                echo "OK" >> USES_LOCK_OUTPUT.html
                echo "</div>" >> USES_LOCK_OUTPUT.html
                echo "</div>" >> USES_LOCK_OUTPUT.html
                echo "<div class="box-content">" >> USES_LOCK_OUTPUT.html
                echo "<button onclick="toggleContainerVisibility-matha"></button>" >> USES_LOCK_OUTPUT.html
                echo "`cat $output_file`" >> USES_LOCK_OUTPUT.html
                echo "</div>" >> USES_LOCK_OUTPUT.html
                echo "</div>" >> USES_LOCK_OUTPUT.html
                #printing the output to the screen.
                #echo -e "================================= \033[37;44m $server \033[0m =====================================";cat $output_file


}

cat header-page >> USES_LOCK_OUTPUT.html
echo "<h1 class="heading">Report for the User disabling on `date`</h1>" >> USES_LOCK_OUTPUT.html
echo "<div class="content">" >>USES_LOCK_OUTPUT.html

echo "SERVER,USER,SHELL,USERDISABLED" >> USES_LOCK_OUTPUT.csv
cat email_body >> email_body.html

while IFS=$'\t' read -r server user;do
        ssh -n -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p 77 -l sysadm $server sudo uptime > /dev/null 2>&1
        if [ $? = 0 ] ; then
                PORT=77
                userdisabling
                else
                       ssh -n -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p 22 -l sysadm $server sudo uptime > /dev/null 2>&1
                       if [ $? = 0 ];then
                       PORT=22
                        userdisabling
                        else
                                echo -e "==================================The \033[41;30m $server \033[40;37m is not accessible====================="
                                echo -e "$server" >> errorlogs.txt
                                #PORT=22
                                #echo -e "$server\t$user\t$PORT" >>list.csv
                                echo -e "<tr><td bgcolor="khaki" align="center">$server</td><td bgcolor="khaki" align="center">$user</td><td bgcolor="khaki" align="center">-</td><td bgcolor="khaki" align="center">KO</td></tr>" >> email_body.html

                                echo "$server,$user,-,NO" >>USES_LOCK_OUTPUT.csv
                                echo "<div class="box" onclick="toggleBox-sidd">" >> USES_LOCK_OUTPUT.html
                                echo "<div class="box-label">" >> USES_LOCK_OUTPUT.html
                                echo "$server"  >> USES_LOCK_OUTPUT.html
                                echo "<div class="ko">" >> USES_LOCK_OUTPUT.html
                                echo "Connection KO" >> USES_LOCK_OUTPUT.html
                                echo "</div>" >> USES_LOCK_OUTPUT.html
                                echo "</div>" >> USES_LOCK_OUTPUT.html
                                echo "<div class="box-content">" >> USES_LOCK_OUTPUT.html
                                echo "<button onclick="toggleContainerVisibility-matha"></button>" >> USES_LOCK_OUTPUT.html
                                echo "The Server is not accessible through both port 77 and 22" >> USES_LOCK_OUTPUT.html
                                echo "</div>" >> USES_LOCK_OUTPUT.html
                                echo "</div>" >> USES_LOCK_OUTPUT.html

                        fi
        fi
done < "$1"

echo "</tabel></body></html>" >> email_body.html

echo "</div>" >> USES_LOCK_OUTPUT.html
echo "<footer class="footer">The script is created by Siddharamayya MATHAPATI and Now Executed by $EXECUTER</footer>" >> USES_LOCK_OUTPUT.html
#echo "</table>" >> USES_LOCK_OUTPUT.html
echo "</body>" >> USES_LOCK_OUTPUT.html
echo "</html>" >> USES_LOCK_OUTPUT.html

#sed -i 's/Connection KO/<font color="red">Connection KO/g;s/KO/<font color="red">KO/g;s/OK/<font color="green">OK/g' USES_LOCK_OUTPUT.html
sed -i 's/-sidd/(event)/g' USES_LOCK_OUTPUT.html
sed -i 's/-matha/(this, document.querySelector('.box-content'))/g' USES_LOCK_OUTPUT.html
echo ""
echo ""
#echo " Output files are saved in `pwd`/USERDELLOGS"
cat `pwd`/USERDISLOGS/v* >> USES_LOCK_OUTPUT
#echo "-- `date +%F/%T` --" >> USES_LOCK_OUTPUT.html
#echo -e "<tr><td bgcolor="khaki" align="center">`cat report_file`</td></tr>" >> USES_LOCK_OUTPUT.html
tar -zpcvf USERDISLOGS.tgz USERDISLOGS > /dev/null 2>&1
# we are sending the output and log files to the user mails
echo -e "Please find the attachments for the USER disble action \n\n `cat errorlogs.txt` \n\nThese above servers are not accessible\n\n--------------------------------------------------------------- \n\nUsers KO's \n\n`cat userna.txt`"|mailx -a `pwd`/USES_LOCK_OUTPUT.html -a `pwd`/USERDISLOGS.tgz -a `pwd`/USES_LOCK_OUTPUT -a `pwd`/email_body.html -a `pwd`/USES_LOCK_OUTPUT.csv  -r $SENDER -s " User Disableaction output file for $DATE" $RECEIVER

echo -e "                You have received mail from \033[36m $SENDER\033[0m  on \033[32m $RECEIVER \033[0m "
echo ""
echo -e "                                                \033[4;35m The script is finished for all the servers \033[0m"
echo ""
#removing the logs directories and files
rm -rf `pwd`/USERDISLOGS/*
cp USES_LOCK_OUTPUT.html `pwd`/USERDISLOGS/USES_LOCK_OUTPUT_by_`whoami`_$(date +%d%m%y%h)
rm -rf USES_LOCK_OUTPUT.html
#rm -rf USERDISLOGS.tgz
if [ -s "errorlogs.txt" ];then
        echo "---------------------------------------------"
        cat errorlogs.txt
        echo -e "\nThese above servers were not accessible"
        echo ""
else
        echo ""
fi
if [ -s "userna.txt" ];then
        echo "---------------------------------------------"
        echo -e "USER KO's\n"
        cat userna.txt
        echo ""
else
        echo ""
fi
rm -rf userna.txt
