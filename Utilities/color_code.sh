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
