#!/bin/bash
###########################################################################
######## Script for running a loop with command on list of servers       ##
######## Created By    :  Siddharamayya  Mathapati                       ##
######## Creation Date : 19th December 2023                              ##
######## Email         : msidrm455@gmail.com                             ##
######## Version       : 2.0                                             ##
###########################################################################

#set -x
#  Check if the file provided is CSV or not
if [ -z "$1" ]; then
  echo ""
  echo "Usage: $0 <csv_file>"
  #cat /home/RUN_TEAM/USER_DISABLE/READ-ME.txt
  exit 1
fi
#  creating a directory to save output files

#removing all old data from output files
tput clear
mkdir -p `pwd`/LOOPLOGS
LOGDIR=`pwd`/LOOPLOGS/

INPUTFILE=$1
#defining the sender and receiver for mail service
SENDER=root@$(uname -n).gmail.com
EXECUTER=$(getent passwd `whoami`| awk -F: '{print $5}')
RECEIVER="$(getent passwd `whoami`| awk -F: '{print $5}'|awk '{up=""; low=""; for(i=1;i<=NF;i++) {gsub(/[^A-Za-z]/, "", $i); if (toupper($i) == $i) up = up $i; else low = low $i;} print up ":" low }'|awk -F: '{print tolower($0)}'| awk -F: '{OFS="."; print $2, $1}')@gmail.com"

CHARACTERCOUNT=${#RECEIVER}
if [ $CHARACTERCOUNT -lt 30 ]; then
        RECEIVER=""
        read -p "Enter your Email Address:" NEWEMAIL
        RECEIVER=$NEWEMAIL
else
        echo "mail will be sent to $RECEIVER"
fi

touch output_file
echo ""
echo -e "------------------------------------------------------------------------------"
read -p "Enter your Command to Execute: " INPUT
COMMANDS=$INPUT
echo ""
read -p "Do you wanna receive a output in mail[Yes/No}:" MAILCONF

function loop2run {
        server_filename=$(echo "$server" | tr -d '[:space:]')
        #creating a file with server name in your directory
        output_file="$LOGDIR/${server_filename}_output.txt"
        #printf "\033[0;32m%s %s\033[0m |%n" "$CNT.[ $server ]"
        echo -e "================================= $server =====================================" >> "$output_file"
        Serverfulname=`ssh -n -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p $PORT -l sysadm $server sudo hostname -f`
        ssh -n -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p $PORT -l sysadm $server sudo $COMMANDS |tee -a $output_file
        #CNT=`expr $CNT + 1`

        echo "<div class="box" onclick="toggleBox-sidd">" >> LOOP_OUTPUT.html
        echo "<div class="box-label">" >> LOOP_OUTPUT.html
        echo "$Serverfulname"  >> LOOP_OUTPUT.html
        echo "<div class="ok">" >> LOOP_OUTPUT.html
        echo "OK" >> LOOP_OUTPUT.html
        echo "</div>" >> LOOP_OUTPUT.html
        echo "</div>" >> LOOP_OUTPUT.html
        echo "<div class="box-content">" >> LOOP_OUTPUT.html
        echo "<button onclick="toggleContainerVisibility-matha"></button>" >> LOOP_OUTPUT.html
        echo "`cat $output_file`" >> LOOP_OUTPUT.html
        echo "</div>" >> LOOP_OUTPUT.html
        echo "</div>" >> LOOP_OUTPUT.html

}

cat header-page >> LOOP_OUTPUT.html
echo "<h1 class="heading">Output report of the FOR LOOP on `date +%F%T`</h1>" >> LOOP_OUTPUT.html
echo "<div class="content">" >>LOOP_OUTPUT.html

CNT=1
for server in `cat $INPUTFILE`;do
        ssh -n -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p 77 -l sysadm $server sudo uptime > /dev/null 2>&1
        if [ $? = 0 ] ; then
                PORT=77
                printf "\033[0;32m%s %s\033[0m |%n" "$CNT.[ $server ]"
                loop2run
                else
                       ssh -n -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no -p 22 -l sysadm $server sudo uptime > /dev/null 2>&1
                       if [ $? = 0 ];then
                       PORT=22
                       printf "\033[0;32m%s %s\033[0m |%n" "$CNT.[ $server ]"
                       loop2run
                        else
                                #echo -e "==================================The \033[41;30m $server \033[40;37m is not accessible====================="
                                printf "\033[0;31m%s %s | Server is not accessible \033[0m" "$CNT.[ $server ]"
                                echo -e "$server" >> errorlogs.txt
                                #PORT=22
                                #echo -e "$server\t$user\t$PORT" >>list.csv
                                echo "<div class="box" onclick="toggleBox-sidd">" >> LOOP_OUTPUT.html
                                echo "<div class="box-label">" >> LOOP_OUTPUT.html
                                echo "$server"  >> LOOP_OUTPUT.html
                                echo "<div class="ko">" >> LOOP_OUTPUT.html
                                echo "Connection KO" >> LOOP_OUTPUT.html
                                echo "</div>" >> LOOP_OUTPUT.html
                                echo "</div>" >> LOOP_OUTPUT.html
                                echo "<div class="box-content">" >> LOOP_OUTPUT.html
                                echo "<button onclick="toggleContainerVisibility-matha"></button>" >> LOOP_OUTPUT.html
                                echo "The Server is not accessible through both port 77 and 22" >> LOOP_OUTPUT.html
                                echo "</div>" >> LOOP_OUTPUT.html
                                echo "</div>" >> LOOP_OUTPUT.html

                        fi
        fi
        CNT=`expr $CNT + 1`
done

echo "</div>" >> LOOP_OUTPUT.html
echo "<footer class="footer">The script is created by Siddharamayya MATHAPATI and Now Executed by $EXECUTER</footer>" >> LOOP_OUTPUT.html
#echo "</table>" >> LOOP_OUTPUT.html
echo "</body>" >> LOOP_OUTPUT.html
echo "</html>" >> LOOP_OUTPUT.html

#sed -i 's/Connection KO/<font color="red">Connection KO/g;s/KO/<font color="red">KO/g;s/OK/<font color="green">OK/g' LOOP_OUTPUT.html
sed -i 's/-sidd/(event)/g' LOOP_OUTPUT.html
sed -i 's/-matha/(this, document.querySelector('.box-content'))/g' LOOP_OUTPUT.html

cat $LOGDIR/* >>LOOP_OUTPUT.txt
tar -zpcvf LOOP_OUTPUT.tgz $LOGDIR > /dev/null 2>&1
echo ""
echo ""
if [[ "$MAILCONF" =~ ^[Yy]$ ]];then
        echo -e "Please find the output attchec for your loop\n `cat errorlogs.txt` \n\nThese above servers are not accessible\n\n--------------------------------------------------------------- \n"|mailx -a `pwd`/LOOP_OUTPUT.html -a LOOP_OUTPUT.tgz -a LOOP_OUTPUT.txt -r $SENDER -s " $0 output file for $DATE" $RECEIVER > /dev/null 2>&1
        echo -e "                You have received mail from \033[36m $SENDER\033[0m  on \033[32m $RECEIVER \033[0m "
        echo ""
fi
echo -e "                                                \033[4;35m The script is finished for all the servers \033[0m"
echo ""
if [ -s "errorlogs.txt" ];then
        echo "---------------------------------------------"
        cat errorlogs.txt > /dev/null 2>&1
        echo -e "\nThese above servers were not accessible"
        echo ""
else
        echo ""
fi > /dev/null 2>&1
rm -rf LOOP_OUTPUT.html
rm -rf output_file
rm -rf errorlogs.txt > /dev/null 2>&1
rm -rf LOOP_OUTPUT.txt
rm -rf LOOP_OUTPUT.tgz
rm -rf $LOGDIR/*
