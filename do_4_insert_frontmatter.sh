#!/bin/bash

# Get the input and output directory paths
input_dir='/Users/nbell/Tools/whisper.cpp/markdown_output/new'
output_dir='/Users/nbell/Tools/whisper.cpp/final_output'

# Check if the input directory exists
if [ ! -d "$input_dir" ]; then
    echo "Input directory does not exist: $input_dir"
    exit 1
fi

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"


convert_to_iso8601() {
    local input_date="$1"
    
    # Check if input is provided
    if [ -z "$input_date" ]; then
        echo "Error: No date provided to convert_to_iso8601 function"
        return 1
    fi
    
    # Extract components
    local year="${input_date:0:4}"
    local month="${input_date:4:2}"
    local day="${input_date:6:2}"
    local hour="${input_date:9:2}"
    local minute="${input_date:11:2}"
    local second="${input_date:13:2}"
    local timezone="${input_date:15}"
    
    # Construct the new date string
    echo "${year}-${month}-${day}T${hour}:${minute}:${second}${timezone}"
}


# Function to convert to 8601 format for file system
convert_to_safe_iso8601() {
    local input_date="$1"
    
    # Check if input is provided
    if [ -z "$input_date" ]; then
        echo "Error: No date provided to convert_to_safe_iso8601 function"
        return 1
    fi
    
    # Extract year, month, and day
    local year="${input_date:0:4}"
    local month="${input_date:4:2}"
    local day="${input_date:6:2}"
    
    # Extract the rest of the string (time and timezone)
    local rest="${input_date:8}"
    
    # Construct the new date string
    echo "${year}-${month}-${day}${rest}"
}

# Function to process a single file
process_file() {
    local input_file="$1"
    local output_file="$2"
    local filename=$(basename "$input_file")
    local filename_no_ext="${filename%.*}"

    # Create the new content
    {
        echo "# $(convert_to_safe_iso8601 $filename_no_ext)"
        echo "---"
        echo "created: $(convert_to_iso8601 $filename_no_ext)"
        echo "---"
        echo
        cat "$input_file"
    } > "$output_file"

    echo "File processed: $input_file -> $output_file"
}

# Iterate through all files in the input directory
find "$input_dir" -type f | while read -r input_file; do
    # Determine the relative path of the file within the input directory
    rel_path="${input_file#$input_dir/}"

    base_name=$(basename "$input_file" .md)
    target_name="$(convert_to_safe_iso8601 "$base_name").md"
    
    # Construct the output file path
    output_file="$output_dir/$target_name"
    
    # Create the necessary subdirectories in the output directory
    mkdir -p "$(dirname "$output_file")"
    
    # Process the file
    process_file "$input_file" "$output_file"
done

echo "All files have been processed. Modified files are in: $output_dir"