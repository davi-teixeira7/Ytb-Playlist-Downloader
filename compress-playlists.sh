DEST_FOLDER="compacted-folder"
COMPRESS_CMD="7z"

if [ ! -d "$DEST_FOLDER" ]; then
    echo "Creating destination folder: $DEST_FOLDER"
    mkdir -p "$DEST_FOLDER"
fi

echo "Starting compression of subfolders..."
echo "-----------------------------------"

for dir in */; do
    dir_name="${dir%/}"
    
    if [ "$dir_name" == "$DEST_FOLDER" ] || [ "$dir_name" == ".venv" ]; then
        continue
    fi

    zip_file="$dir_name.zip"
    echo "Processing folder: $dir_name"

    if "$COMPRESS_CMD" a -tzip -r "$zip_file" "$dir_name"; then
        echo "Compressed successfully to: $zip_file"
        
        # Move the created ZIP file to the destination folder
        mv "$zip_file" "$DEST_FOLDER/"
        echo "Moved to: $DEST_FOLDER/$zip_file"
    else
        echo "ERROR: Failed to compress folder $dir_name."
    fi

    echo "---"

done

echo "Compression process complete. Files saved in: $DEST_FOLDER"
