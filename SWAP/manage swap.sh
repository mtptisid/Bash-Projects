#!/bin/bash
###########################################################################
######## Script to manage swap on RHEL/ LINUX Machines                   ##
######## Created By    : MATHAPATI Siddharamayya                         ##
######## Creation Date : 30th January 2024                               ##
######## Email         : msidrm455@gmail.com 							 ##
######## Version       : 2.0                                             ##
###########################################################################


FSUF="$(id -u)_$$"
SCRDIR=/home/user/scripts
touch $SCRDIR/INPUTFILES/my_input_$FSUF
FILE=$SCRDIR/INPUTFILES/my_input_$FSUF
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
echo
if [ $# -gt 2 ];then
        read -p "You choose to extend the swap value to $3, can you please Confirm[Yes/No]:" Confirmation
fi
echo

output_file=$SCRDIR/INPUTFILES/my_output_$FSUF
mailto_file=$SCRDIR/INPUTFILES/VG_LIST$FSUF.csv
>$output_file
>$mailto_file

echo -e "SERVER,SWAP TOTAL, SWAP USED, SWAP FREE,VG FREE, MEMORY AVAILABLE, STATUS " >> $mailto_file
echo "+----------------,------------,------------,------------,-------------,--------------------,-------------------------------------------, " >> $output_file
echo -e "| SERVER , SWAP TOTAL, SWAP USED, SWAP FREE , VG FREE, MEMORY AVAILABLE   ,            STATUS                         | " >> $output_file
echo "+----------------,------------,------------,------------,-------------,--------------------,-------------------------------------------," >> $output_file


round_float() {
   if [[ $1 =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
       integer_part=$(echo $1 | cut -d. -f1)
       decimal_part=$(echo $1 | cut -d. -f2)
       if [ ${#decimal_part} -eq 0 ]; then
           decimal_part=0
       fi
       first_decimal=${decimal_part:0:1}
       if [ ${#decimal_part} -gt 1 ]; then
           second_decimal=${decimal_part:1:1}
       else
           second_decimal=0
       fi
       if [ $first_decimal -ge 5 ] || [ $second_decimal -ge 5 ]; then
           echo $((integer_part + 1))
       else
           echo $integer_part
       fi
   fi
}



function swaplisting {
        vglist=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo /usr/sbin/vgs | grep -E "vg00|root" | awk '{print $1,$(NF -1), $NF}'`
        read vgname vgsize vgfree <<< $(echo $vglist)
        swapcheck=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo free -mh | grep -i swap |awk '{print $2,$3,$4}'`
        memcheck=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo free -mh | grep -i mem | awk '{ print $2,$3,$4,$5,$6,$7}'`
        read memtotal memused memfree memshred memcache memavailable <<< $(echo $memcheck)
        read swaptotal swapused swapfree <<< $(echo $swapcheck)

        echo "$server,$swaptotal,$swapused,$swapfree,$vgfree,$memavailable,NA" >> $mailto_file
        echo "| $server, $swaptotal, $swapused, $swapfree, $vgfree,$memavailable, NA, " >> $output_file

}


function infswaplisting {


}


function exaswaplisting {

}

function swapextend {
        echo -e "================================= \033[37;44m $server \033[0m ====================================="
        sizetoextend=$(( "$DESIREDVALUE" * 1024 ))
        vglist=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo /usr/sbin/vgs --units M | grep -E "vg00|root" | awk '{print $1,$(NF -1), $NF}' |awk '{for (i=1; i<=NF; i++) {gsub(/G/ ,"", $i); gsub(/M/, "", $i) }; print }'`
        read vgname vgsize vgfree <<< $(echo $vglist)
        swapcheck=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo free -m | grep -i swap |awk '{print $2,$3,$4}' |awk '{for (i=1; i<=NF; i++) {gsub(/G/ ,"", $i); gsub(/M/, "", $i) }; print }'`
        memcheck=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo free -m | grep -i mem | awk '{ print $2,$3,$4,$5,$6,$7}' |awk '{for (i=1; i<=NF; i++) {gsub(/G/ ,"", $i); gsub(/M/, "", $i) }; print }'`
        read swaptotal swapused swapfree <<< $(echo $swapcheck)
        read memtotal memused memfree memshred memcache memavailable <<< $(echo $memcheck)

        if [ "$sizetoextend" == "$swaptotal" ];then
                echo "$server,$swaptotal,$swapused,$swapfree,$vgfree,,swap Already at $DESIREDVALUE" >> $mailto_file
                echo "$server, $swaptotal, $swapused, $swapfree, $vgfree,,swap Already at $DESIREDVALUE" >> $output_file
        else
                echo "checking free size in VG"
                vgfree=$(echo "$vgfree" | sed 's/\..*//')
                if [ "$vgfree" -gt "$sizetoextend" ];then
                        echo "Checking free available memory to swapoff"
                        if [ "$memavailable" -gt "$swapused"  ];then
                                ssh -o -q StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo swapoff -a
                                if [];then
                                        lvtoextend=$(( sizetoextend - swaptotal ))
                                        ssh -o -q StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo lvextend -L +"$lvtoextend"M /dev/mapper/vg00-swaplv
                                        if [ $? = 0 ];then
                                                echo "Swap is extended to by $lvtoextend"
                                                ssh -o -q StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo mkswap /dev/mapper/vg00-swaplv
                                                ssh -o -q StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo swapon -a
                                                postswapcheck=`ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 -o BatchMode=yes -p $PORT -l sysadm $server sudo free -mh | grep -i swap |awk '{print $2,$3,$4}'`
                                                read swapnow swapusednow swapfreenow <<< $(echo $postswapcheck)
                                                echo "$server,$swapnow,$swapusednow,$swapfreenow,,,Extended by $LVtoextend MB" >> $mailto_file
                                                echo "| $server, $swapnow, $swapusednow, $swapfreenow, , , Extended by $LVtoextend MB" >> $output_file

                                        fi
                                fi
                        else
                                echo "The server dont have enough memory to do swapoff"
                                echo "$server,$swaptotal,$swapused,$swapfree,$vgfree,$memavailable,No Memory Available" >> $mailto_file
                                echo "| $server, $swaptotal, $swapused, $swapfree, $vgfree,$memavailable,No Memory available" >> $output_file
                        fi
                else

                        echo "the server doesn't have enaough space in VG to extend"
                        echo "$server,$swaptotal,$swapused,$swapfree,$vgfree,$memavailable,No space in VG" >> $mailto_file
                        echo "| $server, $swaptotal, $swapused, $swapfree, $vgfree,$memavailable,No space in VG" >> $output_file

                fi


        fi

}


function swapchecklist {

for server in `cat $FILE`;do
        ssh -n -o ConnectTimeout=4 -o BatchMode=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -p 77 -l sysadm $server sudo uptime > /dev/null 2>&1
        if [ $? = 0 ] ; then
                PORT=77
                $CALLINGFUNC
                else
                       ssh -n -o ConnectTimeout=4 -o BatchMode=yes -o StrictHostKeyChecking=no -o ServerAliveInterval=60 -o ServerAliveCountMax=3 -p 22 -l sysadm $server sudo uptime > /dev/null 2>&1
                       if [ $? = 0 ];then
                               PORT=77
                                $CALLINGFUNC
                        else
                               `ssh -q -l sysadm -p 77 10.240.122.40 "sudo su - root -c 'ssh -p 77 sysadm@$server sudo uptime'" /dev/null` > /dev/null 2>&1
                                 if [ $? = 0 ];then
                                 echo "$server" >> $SCRDIR/INPUTFILES/INFserlist_$FSUF
                                else
                                        `ssh -T root@up000nim0101c "su -c 'ssh 10.116.5.111 'su - p002200 -c ssh -q $server uptime''"`  > /dev/null 2>&1
                                        if [ $? = 0 ];then
                                                echo "$server" >> $SCRDIR/INPUTFILES/CAPS3PGlist_$FSUF
                                        else
                                                `ssh -q -l sysadm -p 77 infdbassh4f1 "sudo su - tahamai -c 'ssh -T -l opc $server uptime'" /dev/null` > /dev/null 2>&1
                                                if [ $? = 0 ];then
                                                        echo "server" >> $SCRDIR/INPUTFILES/EXASERLIST_$FSUF
                                                else


                                                        echo -e "$server" >> $SCRDIR/INPUTFILES/errorlogs_$FSUF.txt
                                                        echo "$server,,,Connection KO" >> $mailto_file
                     fi
             fi
        fi
fi
fi
sizetoextend=""
done

}



if [ "$1" == "--extend" ];then
#if [[ "$Confirmation" =~ ^[Yy]$ ]];THen
        DESIREDVALUE=$2
        #echo "calling swap extend func"
        CALLINGFUNC="swapextend"
        swapchecklist
else
        #ECHo "checking swap"
        CALLINGFUNC="swaplisting"
        swapchecklist
fi




echo "+----------------,------------,------------,------------,-------------,--------------------,------------------------------------------+," >> $output_file
echo ""
if [[ "${MAILCONF}" =~ ^[Yy] ]];then
        echo -e "\n\n--------------------------------------------------------------- \n find the attchments;`cat $SCRDIR/INPUTFILES/errorlogs_$FSUF.txt`"|mailx -a $mailto_file -r $SENDER -s " $0 output file for $DATE" $RECEIVER > /dev/null 2>&1
        echo ""
        column -t -s ',' -o '|' < $output_file
        echo ""
        echo -e "                You have received mail from \033[36m $SENDER\033[0m  on \033[32m $RECEIVER \033[0m "
        echo ""
        echo -e "                                                \033[4;35m The script is finished for all the servers \033[0m"
else
        column -t -s ',' -o '|' < $output_file
fi
echo ""
if [ -s "$SCRDIR/INPUTFILES/errorlogs_$FSUF.txt" ];then
        echo "---------------------------------------------"
        cat $SCRDIR/INPUTFILES/errorlogs_$FSUF.txt
        echo -e "\nThese above servers were not accessible"
        echo ""
else
        echo ""
fi
rm -rf $SCRDIR/INPUTFILES/errorlogs_$FSUF.txt


