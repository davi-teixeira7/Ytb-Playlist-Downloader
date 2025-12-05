JSON_FILE="links.json"
LOG_FILE="download_errors.json"
YTDLP_EXEC="yt-dlp"
YTDLP_OPTS="-t mp3 --embed-metadata --embed-thumbnail --download-archive downloaded_archive.txt"
FORBIDDEN_CHARS='[\\/:*?"<>|]'

source ./.venv/Scripts/activate

if [ $? -ne 0 ]; then
    echo "Error: Could not activate the virtual environment ./.venv/Scripts/activate."
    exit 1
fi

if [ ! -f "$JSON_FILE" ]; then
    echo "Error: File $JSON_FILE was not found."
    deactivate
    exit 1
fi 

echo "[]" > "$LOG_FILE"
echo "Error log will be saved to $LOG_FILE"
echo "Starting playlist downloads..."
echo "-----------------------------------"

LINKS=$(jq -r '.links[]' "$JSON_FILE")
counter=1

for link in $LINKS; do
    echo "Processing link: $link"
    
    metadata=$("$YTDLP_EXEC" -J --flat-playlist "$link" 2>/dev/null)
    title=$(echo "$metadata" | jq -r '(.playlist_title // .title // null)')

    if [ "$title" == "null" ] || [ -z "$title" ]; then
        dir_name="Untitled_Playlist_$counter"
        counter=$((counter + 1))
        echo "Warning: Could not get title. Using folder name: $dir_name"
    else
        cleaned_title=$(echo "$title" | sed -E 's/^(youtube|youtube:tab|YoutubeTab)-//' | sed -E "s/$FORBIDDEN_CHARS/_/g" | sed -E 's/_{2,}/_/g' | sed -E 's/^_|_$//g' | cut -c1-100)
        dir_name="$cleaned_title"
        echo "Folder name: $dir_name"
    fi

    if [ -d "$dir_name" ]; then
        echo "Existing directory: $dir_name. Downloading only new tracks..."
        DIR_EXISTS=true
    else
        if mkdir -p "$dir_name"; then
            echo "Directory created: $dir_name"
        else
            echo "Error creating directory: $dir_name. Skipping this link."
            echo "-----------------------------------"
            continue
        fi
    fi
    
    cd "$dir_name"

    LOG_PATH="../$LOG_FILE"

    YTDLP_PL_OPTS="$YTDLP_OPTS"
    OUTPUT=$("$YTDLP_EXEC" $YTDLP_PL_OPTS "$link" 2>&1)
    EXIT_CODE=$?

    if [ $EXIT_CODE -eq 0 ]; then
        echo "Playlist download '$dir_name' completed"
    else
        echo "Error downloading '$dir_name'. Logging to file."
        
        ERROR_MESSAGE=$(echo "$OUTPUT" | grep 'ERROR:' | tail -n 1 | sed 's/^ERROR: //')
        
        FAILED_VIDEO_ID=$(echo "$OUTPUT" | grep 'ERROR:' | tail -n 1 | sed -E 's/.*\[youtube\] ([^:]+):.*$/\1/')
        
        FAILED_VIDEO_LINK="https://music.youtube.com/watch?v=$FAILED_VIDEO_ID"
        
        MANUAL_OPTS="-t mp3 --embed-metadata --embed-thumbnail" 
        DOWNLOAD_COMMAND="$YTDLP_EXEC $MANUAL_OPTS $FAILED_VIDEO_LINK"
        
        ERROR_JSON=$(jq -c -n --arg link "$link" --arg playlist "$dir_name" --arg error_msg "$ERROR_MESSAGE" --arg download_cmd "$DOWNLOAD_COMMAND" \
            '{link: $link, playlist: $playlist, error_message: $error_msg, download: $download_cmd}')

        cat "$LOG_PATH" | jq --argjson data "$ERROR_JSON" '. + [$data]' > temp.json
        mv temp.json "$LOG_PATH"
    fi
    
    cd ..
    
    echo "-----------------------------------"

done

deactivate
echo "Playlist download process finished. Virtual environment deactivated."
