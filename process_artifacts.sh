#!/bin/bash

# Check if release tag is provided
if [ -z "$1" ]; then
    echo "Please provide a release tag as an argument."
    exit 1
fi

RELEASE_TAG="$1"
ARTIFACTS_DIR="artifacts"
TEMP_DIR="temp"

# Create artifacts and temp directories if they don't exist
mkdir -p "$ARTIFACTS_DIR"
mkdir -p "$TEMP_DIR"

# Function to log messages with timestamps
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Download artifacts
log_message "Downloading artifacts for release $RELEASE_TAG..."

# Get the list of download URLs for electron-related tar.gz files
DOWNLOAD_URLS=$(curl -s "https://api.github.com/repos/WiseLibs/better-sqlite3/releases/tags/$RELEASE_TAG" | jq -r '.assets[].browser_download_url | select(contains("electron") and endswith(".tar.gz"))')

# Download each file
for url in $DOWNLOAD_URLS; do
    filename=$(basename "$url")
    log_message "Downloading $filename..."
    curl -sL -o "$TEMP_DIR/$filename" "$url"
    if [ $? -eq 0 ]; then
        log_message "Successfully downloaded $filename"
    else
        log_message "Failed to download $filename"
    fi
done

# Process artifacts
log_message "Processing artifacts..."

for file in "$TEMP_DIR"/*.tar.gz; do
    if [ -f "$file" ]; then
        filename=$(basename "$file")
        log_message "Processing $filename..."
        
        # Extract the file
        tar -xzf "$file" -C "$TEMP_DIR"
        if [ $? -eq 0 ]; then
            log_message "Successfully extracted $filename"
            
            # Rename and move the extracted file
            extracted_file="$TEMP_DIR/build/Release/better_sqlite3.node"
            if [ -f "$extracted_file" ]; then
                new_filename="${filename%.tar.gz}.node"
                mv "$extracted_file" "$ARTIFACTS_DIR/$new_filename"
                log_message "Renamed and moved to $new_filename"
            else
                log_message "Expected file not found in $filename"
            fi
            
            # Clean up extracted files
            rm -rf "$TEMP_DIR/artifacts"
        else
            log_message "Failed to extract $filename"
        fi
        
        # Remove the original tar.gz file
        rm "$file"
        log_message "Removed $filename"
    fi
done

# Clean up temp directory
rm -rf "$TEMP_DIR"
log_message "Removed temporary directory"

log_message "Artifact processing completed."