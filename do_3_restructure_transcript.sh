#!/bin/bash

# Directory containing the .txt files
input_dir="./raw_transcriptions"

# Directory for output .md files
output_dir="./markdown_output"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Counter for processed and skipped files
processed=0
skipped=0

# Iterate through all .txt files in the input directory
for txt_file in "$input_dir"/*.txt; do
    # Check if file exists (this prevents errors if no .txt files are found)
    [ -f "$txt_file" ] || continue

    # Extract the base filename without extension
    base_name=$(basename "$txt_file" .txt)

    # Define output markdown file
    md_file="$output_dir/${base_name}.md"

    # Check if the corresponding .md file already exists
    if [ -f "$md_file" ]; then
        echo "Skipping: $txt_file (output file already exists)"
        ((skipped++))
        continue
    fi

    echo "Processing: $txt_file"

    # Perform the operation
    cat "$txt_file" | llm -t tidy-transcription -o max_tokens 4000 > "$md_file"

    echo "Created: $md_file"
    ((processed++))
done

echo "Processing complete."
echo "Files processed: $processed"
echo "Files skipped: $skipped"