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

  # Add padding of 5 characters to each column width
  for i in "${!col_widths[@]}"; do
    col_widths[$i]=$((col_widths[$i] + 1))
  done

  # Calculate the total width of the table (including borders and separators)
  local total_width=0
  for width in "${col_widths[@]}"; do
    total_width=$((total_width + width + 1)) #added sep space val
  done
  total_width=$((total_width + 7)) # Include leftmost and rightmost border for this script may change for others.

  # Print A BOrder
  print_border() {
    printf "+%s+\n" "$(printf '%*s' "$total_width" '' | tr ' ' '-')"
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
