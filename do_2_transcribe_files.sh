#!/bin/bash

# Define source and destination folders
SOURCE_FOLDER="/Users/nbell/Library/Mobile Documents/com~apple~CloudDocs/Recordings/Voice Notes"
LANDING_FOLDER="/Users/nbell/Tools/whisper.cpp/inbound_audio"
PREPROCESSED_FOLDER="/Users/nbell/Tools/whisper.cpp/processed_audio"
RAW_TRANSCRIPTIONS="/Users/nbell/Tools/whisper.cpp/raw_transcriptions"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if required commands exist
for cmd in exiftool ffmpeg; do
    if ! command_exists "$cmd"; then
        echo "Error: $cmd is not installed or not in PATH. Please install it and try again."
        exit 1
    fi
done


# Function to convert audio files to WAV format
convert_to_wav() {
    echo "Running convert_to_wav()"
    local input_folder="$1"
    local output_folder="$2"

    # Check if input folder exists
    if [ ! -d "$input_folder" ]; then
        echo "Error: Input folder '$input_folder' does not exist."
        return 1
    fi

    # Create output folder if it doesn't exist
    mkdir -p "$output_folder"

    # Loop through all files in the input folder
    for input_file in "$input_folder"/*; do
        # Skip if not a file
        [ -f "$input_file" ] || continue
        echo "Input filename: $input_file"

        # Extract filename without path and extension
        filename=$(basename "${input_file%.*}")
        echo "Filename: $filename"

        # Set output file path
        output_file="$output_folder/${filename}.wav"
        echo "Output file: $output_file"

        # Check if output file already exists
        if [ -f "$output_file" ]; then
            echo "Warning: Output file '$output_file' already exists. Skipping conversion."
            continue
        fi

        # Convert file using FFmpeg
        if ffmpeg -i "$input_file" -acodec pcm_s16le -ac 1 -ar 16000 "$output_file" 2>/dev/null; then
            printf "Converted: %s -> %s\n" "$input_file" "$output_file"
        else
            printf "Error converting: %s\n" "$input_file"
        fi
    done
}


transcribe_audio_files() {
    echo "Running transcribe_audio_files()"
    local input_folder="$1"
    local model_path="$2"
    local language="$3"
    local transcription_folder="$4"

    # Check if input folder exists
    if [ ! -d "$input_folder" ]; then
        echo "Error: Input folder '$input_folder' does not exist."
        return 1
    fi

    # Check if model file exists
    if [ ! -f "$model_path" ]; then
        echo "Error: Model file '$model_path' does not exist."
        return 1
    fi

    # Check if main executable exists
    if [ ! -x "./main" ]; then
        echo "Error: 'main' executable not found or not executable."
        return 1
    fi

    # Create the transcription folder if it doesn't exist
    mkdir -p "$transcription_folder"

    # Counter for processed files
    local processed=0
    local failed=0

    # Loop through all .wav files in the input folder
    for audio_file in "$input_folder"/*.wav; do
        # Skip if no .wav files are found
        [ -f "$audio_file" ] || continue

        echo "Transcribing: $audio_file"
        
        # Get the base filename without extension
        local base_name=$(basename "${audio_file%.*}")
        
        # Set the output text file path
        local output_file="$transcription_folder/${base_name}"  # Not appending '.txt' because the .main function adds it 


        # Check if output file already exists
        if [ -f "$output_file.txt" ]; then
            echo "Skipping transcription: $output_file.txt already exists"
            ((skipped++))
        else
            # Run the transcription command
            echo "Transcription output:"
            if output=$(./main -m "$model_path" -l "$language" --output-txt -f "$audio_file" -of "$output_file"); then
                echo "$output"
                echo "Transcription successful: $output_file"
                ((processed++))
            else
                echo "$output"
                echo "Error transcribing: $audio_file"
                ((failed++))
            fi
        fi
        echo "----------------------------------------"

    done

    echo "Transcription complete. Processed: $processed, Failed: $failed, Skipped: $skipped"
}



# Create destination and preprocessed folders if they don't exist
mkdir -p "$LANDING_FOLDER" "$PREPROCESSED_FOLDER" "$RAW_TRANSCRIPTIONS"


# Function to get formatted timestamp from file
get_timestamp() {
    local file="$1"
    exiftool -d "%Y%m%dT%H%M%S%z" -DateTimeOriginal "$file" | awk '{print $NF}'
}

# Move files from source to destination folder
echo "Moving files from $SOURCE_FOLDER to $LANDING_FOLDER"

if [ -z "$(ls -A "$SOURCE_FOLDER")" ]; then
    echo "The source folder is empty."
else
    for source_file in "$SOURCE_FOLDER"/*; do
        # Check if it's a file (not a directory)
        if [ -f "$source_file" ]; then
            # Get the filename and extension
            filename=$(basename "$source_file")
            extension="${filename##*.}"
            
            # Get the timestamp of the source file
            source_timestamp=$(get_timestamp "$source_file")
            
            # Check if a file with the same timestamp and extension exists in the destination
            existing_file=$(find "$LANDING_FOLDER" -type f -name "*${source_timestamp}*.${extension}")
            
            if [ -n "$existing_file" ]; then
                echo "Skipping $filename: A file with the same timestamp and extension already exists in the destination."
            else
                # Copy the file
                if cp "$source_file" "$LANDING_FOLDER/"; then
                    echo "Copied: $filename"
                else
                    echo "Error: Failed to copy $filename. Check permissions."
                fi
            fi
        fi
    done
fi

# Rename files based on their original date and time
echo "Renaming files based on metadata"
exiftool -d "%Y%m%dT%H%M%S%z.%%e" "-FileName<DateTimeOriginal" "$LANDING_FOLDER" || {
    echo "Error: Failed to rename files using exiftool."
    exit 1
}


# Convert audio files
convert_to_wav "$LANDING_FOLDER" "$PREPROCESSED_FOLDER"


# Transcribe audio files
transcribe_audio_files "$PREPROCESSED_FOLDER" "./models/ggml-medium.en.bin" "en" "$RAW_TRANSCRIPTIONS"


echo "Script completed successfully"