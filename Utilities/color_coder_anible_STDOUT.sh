#!/bin/bash

# Define ANSI color codes
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
RED='\033[0;31m'
SKYBLUE='\033[1;36m'
ORANGE='\033[0;33m'
MAGENTA='\033[1;35m'
NC='\033[0m' # No Color

# Main logic
awk -v yellow="$YELLOW" -v green="$GREEN" -v red="$RED" -v skyblue="$SKYBLUE" -v orange="$ORANGE" -v magenta="$MAGENTA" -v nc="$NC" '
BEGIN {
    in_play_recap = 0; # Flag for PLAY RECAP section
}
{
    handled = 0; # To track if a line has been handled

    # Handle TASK and PLAY lines
    if ($0 ~ /^TASK/ || $0 ~ /^PLAY/ && $0 !~ /^PLAY RECAP/) {
        print yellow $0 nc;
        handled = 1;
    }
    # Handle "ok" lines
    else if ($0 ~ /^ok/ && $0 ~ /{$/) {
        print green $0 nc;
        handled = 1;
    } else if ($0 ~ /^ok/) {
        print green $0 nc;
        handled = 1;
    }
    # Handle "fatal" lines
    else if ($0 ~ /^fatal/ && $0 ~ /{$/) {
        print red $0 nc;
        handled = 1;
    } else if ($0 ~ /^fatal/) {
        print red $0 nc;
        handled = 1;
    }
    # Handle "skipping" lines
    else if ($0 ~ /^skipping/) {
        print skyblue $0 nc;
        handled = 1;
    }
    # Handle "changed" lines
    else if ($0 ~ /^changed/) {
        print orange $0 nc;
        handled = 1;
    }
    # Handle PLAY RECAP header
    if ($0 ~ /^PLAY RECAP/) {
        print yellow $0 nc;
        in_play_recap = 1; # Enable PLAY RECAP block
        handled = 1;
    }
    # Handle PLAY RECAP contents
    else if (in_play_recap) {
        # Check if the line contains "localhost"
        if ($0 ~ /localhost/) {
            print magenta $0 nc;
        }
        # Check if the line has unreachable=1+ or failed=1+
        else if ($0 ~ /unreachable=[1-9]/ || $0 ~ /failed=[1-9]/) {
            print red $0 nc;
        }
        # Otherwise, color it green
        else {
            print green $0 nc;
        }
        handled = 1;
    }

    # Default case: Print unhandled lines without color
    if (!handled) {
        print $0;
    }
}
' "$1"
