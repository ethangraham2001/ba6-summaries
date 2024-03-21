#!/bin/bash

# Function to combine lectures in a directory
combine_lectures() {
    local dir="$1"
    local lecture_files=$(find "$dir" -maxdepth 1 -type f -name 'lecture*.md' | sort -V)
    local output_file="${dir%/}-summary.pdf"  # Generating output file name

    if [ -z "$lecture_files" ]; then
        echo "No lecture files found in $dir."
        return
    fi
    pandoc $dir/metadata.md $lecture_files -o "../pdf/$output_file"
    echo "$dir lectures in /markdown/$dir saved to pdf/$output_file."
}

cd markdown
# Iterate over subdirectories
for subdir in */; do
    if [ -d "$subdir" ]; then
        combine_lectures "$subdir"
    fi
done

