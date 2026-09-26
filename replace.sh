#!/bin/bash
set -eu

# Exclude metadata and hidden folders (.trickplay, .git, .tmp, etc.) from directory processing
find . \( -name "*.trickplay" -o -name ".*" \) -prune -o -type d -print0 | while IFS= read -r -d '' dir; do
    [ "$dir" = "." ] && continue
    ignore_file="${dir}/.ignore"
    
    # Early-exit search: find first video file (case-insensitive)
    has_video=$(find "$dir" -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.avi" -o -iname "*.mpg" -o -iname "*.mpeg" -o -iname "*.mov" -o -iname "*.wmv" -o -iname "*.ts" \) -print 2>/dev/null | head -n 1 || true)

    if [ -z "$has_video" ]; then
        if [ ! -f "$ignore_file" ]; then
            echo "$dir - No video file exists. Creating .ignore"
            touch "$ignore_file"
        fi
    else
        if [ -f "$ignore_file" ]; then
            echo "$dir - Video file exists. Removing .ignore"
            rm -f "$ignore_file"
        fi
    fi
done

# Trigger Jellyfin library refresh if parameters are set
if [ -n "${JF_URL:-}" ] && [ -n "${JF_API_KEY:-}" ]; then
    clean_url="${JF_URL%/}"
    jfurl="${clean_url}/library/refresh?api_key=${JF_API_KEY}"
    
    # Redact API key in stdout/logs to prevent secret exposure
    log_url="${clean_url}/library/refresh?api_key=***"
    echo "Calling Jellyfin endpoint: $log_url"
    
    curl -s -S -X POST -d "" \
        -H "Accept: application/json" \
        -H "Authorization: MediaBrowser Token=\"${JF_API_KEY}\"" \
        -H "X-Emby-Token: ${JF_API_KEY}" \
        -H "X-MediaBrowser-Token: ${JF_API_KEY}" \
        -w "jellyfin library refresh completed with http_code: %{http_code}\n" \
        "$jfurl"
fi