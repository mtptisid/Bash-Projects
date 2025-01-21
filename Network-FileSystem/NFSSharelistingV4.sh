#!/bin/bash
###########################################################################
######## Script for listing the shares and mountpoints                   ##
######## Created By    : MATHAPATI Siddharamayya                         ##
######## Creation Date : 19th December 2023                              ##
######## Email         : msidrm455@gmail.com                             ##
######## Version       : 2.0                                             ##
###########################################################################

#set -x
#  creating a directory to save output files

SCRDIR=/home/myuser/scripts
touch $SCRDIR/INPUTFILES/my_input_$(id -u)
FILE=$SCRDIR/INPUTFILES/my_input_$(id -u)
vi $FILE

if [ -s $FILE ];then
        echo " using the $FILE as input for the script"
else
        echo "The $FILE has no values"
        echo ""
        echo "Please paste your data to the  file once you run a Script."
        exit 1

fi


#removing all old data from output files
tput clear
mkdir -p $SCRDIR/LOGS/NFSLOGS
LOGDIR=$SCRDIR/LOGS/NFSLOGS
>$SCRDIR/INPUTFILES/firstsortedlist_`id -u`
>$SCRDIR/INPUTFILES/soreted_`id -u`.list
>$SCRDIR/INPUTFILES/secondsortedlist_`id -u`
>$SCRDIR/INPUTFILES/final_list_`id -u`

if [ "$2" == "--skip" ];then
        read -p "Hey you are not given any Arguments,type Yes if you wanna skip the data processing?[Yes/No}:" Confirmation
fi

function dataprocessing {

                echo -e "\e[5;32mThe Data is being proceesed, Please Wait....\e[0m"

                awk -F'\t' '{split($2, hostnames, ","); for (i in hostnames) print $1, hostnames[i]}' $FILE | awk 'BEGIN {OFS=","}{print $1, $2}' >> $SCRDIR/INPUTFILES/firstsortedlist_`id -u`

                awk -i inplace -F, '{ if ($2 ~ /^[0-9]/) print $0; else {sub(/\..*$/, "", $2); print $1","$2}}' $SCRDIR/INPUTFILES/firstsortedlist_`id -u`

                cat $SCRDIR/INPUTFILES/firstsortedlist_`id -u` | awk -F, '{print $2}' >> /$SCRDIR/INPUTFILES/soreted_`id -u`.list

                ./hostnamecheck $SCRDIR/INPUTFILES/soreted_`id -u`.list $SCRDIR/INPUTFILES/nfshost_`id -u` > /dev/null 2>&1
                ./nslookupcheck $SCRDIR/INPUTFILES/soreted_`id -u`.list $SCRDIR/INPUTFILES/nfshost1_`id -u` > /dev/null 2>&1

                awk -F: 'NR==FNR{a[$1]=$2; next} {print $1, ($2 == "" ? a[$1] : $2)}' $SCRDIR/INPUTFILES/nfshost_`id -u` $SCRDIR/INPUTFILES/nfshost1_`id -u` | awk 'BEGIN { OFS="," }{print $1,$2}' >> $SCRDIR/INPUTFILES/secondsortedlist_`id -u`

                paste -d',' /$SCRDIR/INPUTFILES/firstsortedlist_`id -u` $SCRDIR/INPUTFILES/secondsortedlist_`id -u` | awk 'BEGIN { FS=","; OFS="," }{print $1,$2,$4}' >> $SCRDIR/INPUTFILES/final_list_`id -u`

                #cat /input_file |tr -d ' ' |sort|uniq >> /final_list

}


if [ "$1" == "" ];then
        HNASNAMES="NFS|CIFS"
else
        HNASNAMES=$1
fi


#defining the sender and receiver for mail service
SENDER=root@$(uname -n).myorg.com
EXECUTER=$(getent passwd `whoami`| awk -F: '{print $5}')
RECEIVER="$(getent passwd `whoami`| awk -F: '{print $5}'|awk '{up=""; low=""; for(i=1;i<=NF;i++) {gsub(/[^A-Za-z]/, "", $i); if (toupper($i) == $i) up = up $i; else low = low $i;} print up ":" low }'|awk -F: '{print tolower($0)}'| awk -F: '{OFS="."; print $2, $1}')@myorg.com"

CHARACTERCOUNT=${#RECEIVER}
if [ $CHARACTERCOUNT -lt 30 ]; then
        RECEIVER=""
        read -p "Enter your Email Address:" NEWEMAIL
        RECEIVER=$NEWEMAIL
else
        echo "mail will be sent to $RECEIVER"
fi
>$SCRDIR/INPUTFILES/MOUNT_LIST_OUTPUT_`id -u`.html
echo ""
echo -e "------------------------------------------------------------------------------"
echo ""


function findsharemounts {

                server_filename=$(echo "$server" | tr -d '[:space:]')
                #creating a file with server name in your directory
                output_file="$LOGDIR/${server_filename}_output.txt"
                echo ""
                #echo "-- `date +%F/%T` --" >> "$output_file"
                echo -e "================================= \033[37;44m $server \033[0m ====================================="
                echo -e "================================= $server =====================================" >> "$output_file"
                echo ""
                Serverfulname=`ssh -n -o ConnectTimeout=4 -o BatchMode=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -p $PORT -l sysadm $server sudo hostname -f`

                ssh -n -o ConnectTimeout=4 -o BatchMode=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -p $PORT -l sysadm $server sudo $TIMEOUTS df $OPTIONS | egrep -i $HNASNAMES >> "$output_file" > /dev/null 2>&1

                dfcomout=`ssh -n -o ConnectTimeout=4 -o BatchMode=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -p $PORT -l sysadm $server sudo $TIMEOUTS df $OPTIONS | grep -iE "NFS|CIFS" |grep -i "$sharename"`
                if [ $? = 0 ]; then
                        read shares types mounts <<< $(echo $dfcomout | awk '{print $1, $2, $NF}')
                        echo -e " The $shares is \033[42;30m  mounted \033[40;37m  as $mounts"
                        readcheck=`ssh -n -o ConnectTimeout=4 -o BatchMode=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -p $PORT -l sysadm $server "sudo ls -l $mounts"`   > /dev/null 2>&1
                        writecheck=`ssh -n -o ConnectTimeout=4 -o BatchMode=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -p $PORT -l sysadm $server "sudo touch $mounts/nfstestfile.txt && echo "Success" || echo "Fail";sudo rm -rf $mounts/nfstestfile.txt"`   > /dev/null 2>&1
                        ownerandperm=`ssh -n -o ConnectTimeout=5 -o BatchMode=yes -o StrictHostKeyChecking=no -p $PORT -l sysadm $server sudo ls -ld $mounts | awk '{print $1, $3":"$4}'`
                        if [ -n "$readcheck" ] && [ "$writecheck" == "Success" ]; then
                                echo ""
                                read permission owners <<< $(echo $ownerandperm)
                                echo -e "\033[1;32m read write access OK on $mounts.\033[0m"
                                echo "$sharename,$ipaddress,$server,$shares,$mounts,$types,$owners,$permission,OK,OK,MOUNTED,LINUX" >> $NFSLIST
                        elif [ -n "$readcheck" ];then
                                echo -e "\033[32m Read access is OK \033[0m  \033[31m write access is KO to the $mounts\033[0m"
                                echo "$sharename,$ipaddress,$server,$shares,$mounts,$types,$owners,$permission,OK,KO,MOUNTED,LINUX" >> $NFSLIST
                        else
                                echo -e "\033[1;31m Read and write access to the $mounts is KO \033[0m"
                                echo "$sharename,$ipaddress,$server,$shares,$mounts,$types,$owners,$permission,KO,KO,MOUNTED,LINUX" >> $NFSLIST

                        fi
                else
                        fstabout=`ssh -n -o ConnectTimeout=4 -o BatchMode=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -p $PORT -l sysadm $server sudo cat $FSENTRIES |grep -iE "CIFS|NFS" | grep -i "$sharename"`
                        if [ $? = 0 ]; then
                                read fsshares fsmounts <<< $(echo $fstabout | awk '{print $1, $2}')
                                echo -e " \033[1;33m The $shares is not mounted but has entry in FSTAB \033[0m"
                                echo "$sharename,$ipaddress,$server,$fsshares,$fsmounts,NA,NA,NA,NA,NA,NOT-MOUNTED,LINUX" >> $NFSLIST

                        else
                                echo -e "The $sharename is not present"
                                echo "$sharename,$ipaddress,$server,NA,NA,NA,NA,NA,,,Not Present,LINUX" >> $NFSLIST
                        fi
                fi


                echo "<div class="box" onclick="toggleBox-sidd">" >> $HTMLPAGE
                echo "<div class="box-label">" >> $HTMLPAGE
                echo "$Serverfulname"  >> $HTMLPAGE
                echo "<div class="ok">" >> $HTMLPAGE
                echo "OK" >> $HTMLPAGE
                echo "</div>" >> $HTMLPAGE
                echo "</div>" >> $HTMLPAGE
                echo "<div class="box-content">" >> $HTMLPAGE
                echo "<button onclick="toggleContainerVisibility-matha"></button>" >> $HTMLPAGE
                echo "`cat $output_file`" >> $HTMLPAGE
                echo "</div>" >> $HTMLPAGE
                echo "</div>" >> $HTMLPAGE


}


HTMLPAGE=$SCRDIR/INPUTFILES/MOUNT_LIST_OUTPUT_`id -u`.html
NFSLIST=$SCRDIR/INPUTFILES/NFS_LIST_FINAL_`id -u`.csv
>$HTMLPAGE
>$NFSLIST
cat PREREQUISITES/header-page >> $HTMLPAGE
echo "<h1 class="heading">Output of the shares and mounts on `date +%F%T`</h1>" >> $HTMLPAGE
echo "<div class="content">" >> $HTMLPAGE
echo "SHARE,IP ADDRESS,HOST NAME,SHARE NAME,MOUNT POINT,TYPE,OWNER,PERMISSIONS,READ ACCESS,WRITE ACCESS,STATUS,SCOPE" >> $NFSLIST


function nfssharecheckings {
while IFS="$Delimeter" read -r sharename ipaddress server;do
        ssh -n -o ConnectTimeout=4 -o BatchMode=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -p 77 -l sysadm $server sudo uptime > /dev/null 2>&1
        if [ $? = 0 ] ; then
                PORT=77
                if [[ "$server" == [sS][aA]* ]];then
                        OPTIONS=""
                        FSENTRIES="/etc/filesystems"
                        TIMEOUTS=""
                else
                        OPTIONS="-PhT"
                        FSENTRIES="/etc/fstab"
                        TIMEOUTS="timeout 15s"
                fi
                findsharemounts
        else
               ssh -n -o ConnectTimeout=4 -o BatchMode=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -p 22 -l sysadm $server sudo uptime > /dev/null 2>&1
                if [ $? = 0 ];then
                        PORT=22
                        if [[ "$server" == [sS][aA]* ]];then
                                OPTIONS=""
                                FSENTRIES="/etc/filesystems"
                                TIMEOUTS=""
                        else
                                OPTIONS="-PhT"
                                FSENTRIES="/etc/fstab"
                                TIMEOUTS="timeout 15s"
                        fi
                                findsharemounts
                        else
                                #echo -e "==================================The \033[41;30m $server \033[40;37m is not accessible====================="
                                printf "\033[0;31m $ipaddress : $server is not accessible \033[0m" "$CNT.[ $server ]"
                                echo -e "$server" >> $SCRDIR/INPUTFILES/errorlogs.txt
                                #PORT=22o
                                if [[ "$server" == [wW]* ]];then
                                        echo "$sharename,$ipaddress,$server,NA,NA,NA,NA,NA,NA,NA,Connection KO,WINDOWS" >> $NFSLIST
                                #echo -e "$server\t$user\t$PORT" >>list.csv
                                else
                                        echo "$sharename,$ipaddress,$server,NA,NA,NA,NA,NA,NA,NA,Connection KO,NOT IN SCOPE" >> $NFSLIST
                                fi
                                echo "<div class="box" onclick="toggleBox-sidd">" >> $HTMLPAGE
                                echo "<div class="box-label">" >> $HTMLPAGE
                                echo "$server"  >> $HTMLPAGE
                                echo "<div class="ko">" >> $HTMLPAGE
                                echo "Connection KO" >> $HTMLPAGE
                                echo "</div>" >> $HTMLPAGE
                                echo "</div>" >> $HTMLPAGE
                                echo "<div class="box-content">" >> $HTMLPAGE
                                echo "<button onclick="toggleContainerVisibility-matha"></button>" >> $HTMLPAGE
                                echo "The Server is not accessible through both port 77 and 22" >> $HTMLPAGE
                                echo "</div>" >> $HTMLPAGE
                                echo "</div>" >> $HTMLPAGE

                        fi
        fi
done < $INPUTFILE
}



if [ "$2" == "--skip" ] && [[ "$Confirmation" =~ ^[Yy]$ ]];then
        INPUTFILE=$FILE
        Delimeter=$'\t'
        nfssharecheckings
else
        dataprocessing
        Delimeter=','
        INPUTFILE=$SCRDIR/INPUTFILES/final_list_`id -u`
        nfssharecheckings
fi





echo "</div>" >> $HTMLPAGE
echo "<footer class="footer">The script is created by Siddharamayya MATHAPATI and Now Executed by $EXECUTER</footer>" >> $HTMLPAGE
#echo "</table>" >> $HTMLPAGE
echo "</body>" >> $HTMLPAGE
echo "</html>" >> $HTMLPAGE

#sed -i 's/Connection KO/<font color="red">Connection KO/g;s/KO/<font color="red">KO/g;s/OK/<font color="green">OK/g' $HTMLPAGE
sed -i 's/-sidd/(event)/g' $HTMLPAGE
sed -i 's/-matha/(this, document.querySelector('.box-content'))/g' $HTMLPAGE

cat $LOGDIR/* >>$SCRDIR/INPUTFILES/MOUNT_LIST_OUTPUT_`id -u`.txt
tar -zpcvf $SCRDIR/INPUTFILES/MOUNT_LIST_OUTPUT_`id -u`.tgz $LOGDIR > /dev/null 2>&1
echo ""
echo ""
echo -e "\n\n--------------------------------------------------------------- \n find the attchments"|mailx -a /$HTMLPAGE -a $SCRDIR/INPUTFILES/MOUNT_LIST_OUTPUT_`id -u`.tgz -a $SCRDIR/INPUTFILES/MOUNT_LIST_OUTPUT_`id -u`.txt  -a /$NFSLIST -r $SENDER -c "msidrm455@gmail.com" -s " $0 output file for $DATE" $RECEIVER > /dev/null 2>&1
echo -e "                You have received mail from \033[36m $SENDER\033[0m  on \033[32m $RECEIVER \033[0m "
echo ""
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
rm -rf output_file
rm -Rf errorlogs.txt > /dev/null 2>&1
rm -Rf $SCRDIR/INPUTFILES/MOUNT_LIST_OUTPUT_`id -u`.tgz
rm -rf $LOGDIR/*
