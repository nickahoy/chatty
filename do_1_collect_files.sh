#!/bin/bash

# This script moves all files from a source folder to a destination folder

# Define source and destination paths
# SOURCE_FOLDER="/Users/nbell/Library/Mobile Documents/iCloud~is~workflow~my~workflows/Documents/Recordings"
SOURCE_FOLDER='/Users/nbell/Library/Mobile Documents/iCloud~is~workflow~my~workflows/Documents/Voice Notes'
DESTINATION_FOLDER="/Users/nbell/Tools/whisper.cpp/source_audio"

# Check if source folder exists
if [ ! -d "$SOURCE_FOLDER" ]; then
    echo "Error: Source folder does not exist."
    exit 1
fi

# Create destination folder if it doesn't exist
mkdir -p "$DESTINATION_FOLDER"

# Check if destination folder creation was successful
if [ ! -d "$DESTINATION_FOLDER" ]; then
    echo "Error: Failed to create destination folder."
    exit 1
fi

# Move files from source to destination
if ! mv "$SOURCE_FOLDER"/* "$DESTINATION_FOLDER" 2>/dev/null; then
    echo "Error: Failed to move files. Check permissions and try again."
    exit 1
fi

echo "Files successfully moved from source to destination."