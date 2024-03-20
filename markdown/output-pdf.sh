#!/bin/bash

# Find all Markdown files named lectureXX.md
lecture_files=$(find . -maxdepth 1 -type f -name 'lecture*.md' | sort -V)

# Check if there are any lecture files
if [ -z "$lecture_files" ]; then
    echo "No lecture files found."
    exit 1
fi

# Output file name
output_file="cs300-summary.pdf"

# Combine lecture files into a single Pandoc document
pandoc metadata.md $lecture_files -o "$output_file"

echo "Combined lectures saved to $output_file."
