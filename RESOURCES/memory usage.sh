
#!/bin/bash
###########################################################################
######## Script for fetcing Memory Usage of the Linux Server             ##
######## Created By    : MATHAPATI Siddharamayya                         ##
######## Creation Date : 28th January 2025                               ##
######## Email         : msidrm455@gmail.com 				                     ##
######## Version       : 2.0                                             ##
###########################################################################

MEMFILE=/tmp/ram_$$.csv
SWAPF=/tmpswap_$$.csv
TOPF=/tmp/top_$$.csv
FREEF=/tmp/free_$$.csv

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


convert_to_human_readable() {
    local size_kb=$1
    if (( size_kb >= 1048576 )); then  # More than or equal to 1GB
        size_gb=$(echo "scale=2; $size_kb/1048576" | bc)
        echo "${size_gb} GB"
    elif (( size_kb >= 1024 )); then  # More than or equal to 1MB but less than 1GB
        size_mb=$(echo "scale=2; $size_kb/1024" | bc)
        echo "${size_mb} MB"
    else  # Less than 1MB
        echo "${size_kb} KB"
    fi
}



echo "------------------------------`hostname`--------------------------------"
echo

echo "+-------------------------------- Uptime --------------------------------+"
echo "| `uptime` |"
echo "+------------------------------------------------------------------------+"
echo

echo "Top Output:"
echo "  PID,USER,PR,NI,VIRT,RES,SHR,S,%CPU,%MEM,TIME+,COMMAND" > $TOPF
top -b -n 1 | awk 'NR>7 {print $1","$2","$3","$4","$5","$6","$7","$8","$9","$10","$11","$12}'|head -7 >> $TOPF
format_table $TOPF
echo

echo "Memory Usage:"
free -h | awk '
  NR==2 {mem_total=$2; mem_used=$3; mem_free=$4; mem_shared=$5; mem_buff_cache=$6; mem_available=$7}
  NR==3 {swap_total=$2; swap_used=$3; swap_free=$4}
  END {
    print ",MEM,SWAP"
    print "total," mem_total "," swap_total
    print "Used," mem_used "," swap_used
    print "free," mem_free "," swap_free
    print "shared," mem_shared ","
    print "buff/cache," mem_buff_cache ","
    print "available," mem_available ","
  }
' > $FREEF
format_table $FREEF
echo

# Create temporary files for later processing
SCRIPT_NAME=`basename $0`
SORT="kb"  # {pid|kB|name} as first parameter, [default: kb]
[ "$1" != "" ] && { SORT="$1"; }

[ ! -x `which mktemp` ] && { echo "ERROR: mktemp is not available!"; exit; }
MKTEMP=`which mktemp`
TMP=`${MKTEMP} -d`
[ ! -d "${TMP}" ] && { echo "ERROR: unable to create temp dir!"; exit; }

>${TMP}/${SCRIPT_NAME}.pid
>${TMP}/${SCRIPT_NAME}.kb
>${TMP}/${SCRIPT_NAME}.name

SUM=0
OVERALL=0
echo "${OVERALL}" > ${TMP}/${SCRIPT_NAME}.overal

# Process and gather information for swap
for DIR in $(find /proc/ -maxdepth 1 -type d -regex "^/proc/[0-9]+"); do
    PID=$(echo $DIR | cut -d / -f 3)
    PROGNAME=$(ps -p $PID -o comm --no-headers)

    for SWAP in $(grep Swap $DIR/smaps 2>/dev/null | awk '{ print $2 }'); do
        let SUM=$SUM+$SWAP
    done

    if (( $SUM > 0 )); then
        # Save the raw swap usage in KB, no conversion yet
        echo -n "."  # Indicate progress
        echo -e "${PID},${SUM},${PROGNAME}" >> ${TMP}/${SCRIPT_NAME}.pid
        echo -e "${SUM},${PID},${PROGNAME}" >> ${TMP}/${SCRIPT_NAME}.kb
        echo -e "${PROGNAME},${SUM},${PID}" >> ${TMP}/${SCRIPT_NAME}.name
    fi
    let OVERALL=$OVERALL+$SUM
    SUM=0
done

# Convert overall swap usage to human-readable format for display
human_readable_overall=$(convert_to_human_readable $OVERALL)
echo "${human_readable_overall}" > ${TMP}/${SCRIPT_NAME}.overal
echo


TOP_PROGRAMS=$(cat ${TMP}/${SCRIPT_NAME}.pid | sort -t, -k2,2nr | head -n 7 | cut -d',' -f3 | paste -sd '|' -)

# Save swap usage details to separate CSV file
echo "PID,SwapUsed(kB),ProgramName" > $SWAPF

cat ${TMP}/${SCRIPT_NAME}.pid | sort -t, -k2,2nr | head -n 7  >> ${TMP}/${SCRIPT_NAME}.tempkb  # Top 7 processes by swap usage

TOP_PROGRAMS=$(cat ${TMP}/${SCRIPT_NAME}.tempkb | sort -t, -k2,2nr | head -n 7 | cut -d',' -f3 | paste -sd '|' -)

cat ${TMP}/${SCRIPT_NAME}.pid  | while IFS=, read -r pid swap program_name; do
    human_readable_swap=$(convert_to_human_readable $swap)
    echo -e "${pid},${human_readable_swap},${program_name}" >> ${TMP}/${SCRIPT_NAME}.fin
done

cat ${TMP}/${SCRIPT_NAME}.fin | grep -i -E "$TOP_PROGRAMS">> $SWAPF


# Save RAM usage of top 10 processes (or however many you need) to a separate file
echo "CPU%,MEM%,MEM in MB,PROCESS" > $MEMFILE
ps aux --sort=-%mem | awk 'NR<=10 { print $3","$4","$6/1024" MB,"$11 }' >> $MEMFILE # Top 10 processes by RAM usage in MB

# Save Overall swap usage to the file

# Process table using print_table function
# You would use something like this:
# print_table ${TMP}/${SCRIPT_NAME}.pid
# OR similar depending on how your print_table function is implemented.
# Save Overall swap usage to the file
echo "Overall RAM Usage"
format_table $MEMFILE
echo
# Save Overall swap usage to the file
echo "Overall swap used: ${human_readable_overall}"
format_table $SWAPF

rm -fr "${TMP}/"

rm -rf $MEMFILE $SWAPF $TOPF $FREEF
