#!/bin/bash

# Define ANSI color codes
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
SKYBLUE='\033[1;36m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# Main logic
awk -v yellow="$YELLOW" -v green="$GREEN" -v red="$RED" -v skyblue="$SKYBLUE" -v orange="$ORANGE" -v nc="$NC" '
BEGIN {
    in_green_block = 0;
    in_red_block = 0;
    in_play_recap = 0;
}
{
    if ($0 ~ /^TASK/ || $0 ~ /^PLAY/) {
        print yellow $0 nc;
    } else if ($0 ~ /^ok/ && $0 ~ /{$/) {
        print green $0 nc;
        in_green_block = 1;
    } else if ($0 ~ /^ok/) {
        print green $0 nc;
    } else if ($0 ~ /^fatal/ && $0 ~ /{$/) {
        print red $0 nc;
        in_red_block = 1;
    } else if ($0 ~ /^fatal/) {
        print red $0 nc;
    } else if ($0 ~ /^skipping/) {
        print skyblue $0 nc;
    } else if ($0 ~ /^changed/) {
        print orange $0 nc;
    } else if ($0 ~ /^PLAY RECAP/) {
        print yellow $0 nc;
        in_play_recap = 1;
    } else if (in_play_recap) {
        # Check for counts and apply colors
        if ($0 ~ /failed=[1-9]/ || $0 ~ /unreachable=[1-9]/) {
            host_color = red
        } else {
            host_color = green
        }

        # Print the line with colors applied to specific sections
        split($0, words, /[ \t]+/)
        for (i = 1; i <= length(words); i++) {
            if (i == 1) {
                printf("%s%s%s ", host_color, words[i], nc)
            } else if (words[i] ~ /ok=[0-9]+/) {
                printf("%s%s%s ", green, words[i], nc)
            } else if (words[i] ~ /changed=[0-9]+/) {
                printf("%s%s%s ", orange, words[i], nc)
            } else if (words[i] ~ /failed=[0-9]+/) {
                printf("%s%s%s ", red, words[i], nc)
            } else if (words[i] ~ /unreachable=[0-9]+/) {
                printf("%s%s%s ", red, words[i], nc)
            } else {
                printf("%s ", words[i])
            }
        }
        print ""
    } else if (in_green_block) {
        print green $0 nc;
        if ($0 ~ /}$/) {
            in_green_block = 0;
        }
    } else if (in_red_block) {
        print red $0 nc;
        if ($0 ~ /}$/) {
            in_red_block = 0;
        }
    } else {
        print $0;
    }
}
' "$1"






PLAY RECAP *********************************************************************
MYSERVER8579               : ok=28   changed=9    unreachable=0    failed=0    skipped=19   rescued=0    ignored=0
MYSERVER8610               : ok=28   changed=9    unreachable=0    failed=0    skipped=19   rescued=0    ignored=0
MYSERVER8630               : ok=14   changed=3    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0
MYSERVER8502               : ok=28   changed=9    unreachable=0    failed=0    skipped=19   rescued=0    ignored=0
MYSERVER8503               : ok=28   changed=9    unreachable=0    failed=0    skipped=21   rescued=0    ignored=0
MYSERVER8532               : ok=14   changed=3    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0
localhost                  : ok=5    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0


-------------------------------------------------------------------------------------------------------------------------------
#!/bin/bash

# Define ANSI color codes
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
SKYBLUE='\033[1;36m'
ORANGE='\033[0;33m'
NC='\033[0m' # No Color

# Main logic
awk -v yellow="$YELLOW" -v green="$GREEN" -v red="$RED" -v skyblue="$SKYBLUE" -v orange="$ORANGE" -v nc="$NC" '
BEGIN {
    in_green_block = 0;
    in_red_block = 0;
    in_play_recap = 0;
}
{
    if ($0 ~ /^TASK/ || $0 ~ /^PLAY/) {
        print yellow $0 nc;
    } else if ($0 ~ /^ok/ && $0 ~ /{$/) {
        print green $0 nc;
        in_green_block = 1;
    } else if ($0 ~ /^ok/) {
        print green $0 nc;
    } else if ($0 ~ /^fatal/ && $0 ~ /{$/) {
        print red $0 nc;
        in_red_block = 1;
    } else if ($0 ~ /^fatal/) {
        print red $0 nc;
    } else if ($0 ~ /^skipping/) {
        print skyblue $0 nc;
    } else if ($0 ~ /^changed/) {
        print orange $0 nc;
    } else if ($0 ~ /^PLAY RECAP/) {
        print yellow $0 nc;
        in_play_recap = 1;
    } else if (in_play_recap) {
        # Initialize counts
        ok_count = 0;
        changed_count = 0;
        unreachable_count = 0;
        failed_count = 0;
        skipped_count = 0;
        rescued_count = 0;
        ignored_count = 0;

        # Extract counts from the line
        if (match($0, /ok=[0-9]+/)) {
            ok_count = substr($0, RSTART+3, RLENGTH-3);
        }
        if (match($0, /changed=[0-9]+/)) {
            changed_count = substr($0, RSTART+8, RLENGTH-8);
        }
        if (match($0, /unreachable=[0-9]+/)) {
            unreachable_count = substr($0, RSTART+12, RLENGTH-12);
        }
        if (match($0, /failed=[0-9]+/)) {
            failed_count = substr($0, RSTART+7, RLENGTH-7);
        }
        if (match($0, /skipped=[0-9]+/)) {
            skipped_count = substr($0, RSTART+8, RLENGTH-8);
        }
        if (match($0, /rescued=[0-9]+/)) {
            rescued_count = substr($0, RSTART+8, RLENGTH-8);
        }
        if (match($0, /ignored=[0-9]+/)) {
            ignored_count = substr($0, RSTART+8, RLENGTH-8);
        }

        # Determine the highest count
        max_count = ok_count;
        color = green;

        if (changed_count > max_count) {
            max_count = changed_count;
            color = orange;
        }
        if (unreachable_count > max_count || failed_count > max_count) {
            max_count = unreachable_count > failed_count ? unreachable_count : failed_count;
            color = red;
        }
        if (skipped_count > max_count || rescued_count > max_count || ignored_count > max_count) {
            max_count = skipped_count > rescued_count ? (skipped_count > ignored_count ? skipped_count : ignored_count) : (rescued_count > ignored_count ? rescued_count : ignored_count);
            color = skyblue;
        }

        # Print the line with the determined color
        print color $0 nc;
    } else if (in_green_block) {
        print green $0 nc;
        if ($0 ~ /}$/) {
            in_green_block = 0;
        }
    } else if (in_red_block) {
        print red $0 nc;
        if ($0 ~ /}$/) {
            in_red_block = 0;
        }
    } else {
        print $0;
    }
}
' "$1"
