#!/bin/bash

filter1="$1"
filter2="$2"
maximumSize=1048576000  # ~1.048 GB

find . -type d -name "_Motions" -print0 | while IFS= read -r -d '' dir; do
    echo "Processing: $dir"
    (
        cd "$dir" || { echo "Failed to enter directory: $dir"; exit; }
        for i in *.mov; do
            [[ ! -f "$i" ]] && continue
            mkdir -p "_Originals"
            filesize=$(wc -c <"$i")
            if ([[ "$i" == *"$filter1"* ]] || [[ "$i" == *"$filter2"* ]]) && [[ $filesize -ge $maximumSize ]]; then
                fileName="${i%.mov}.mp4"
                echo "Encoding: $i ($filesize bytes)"
                # echo "Running: ffmpeg -i \"$i\" -s 3840x2160 -c:v libx264 [...] \"$fileName\""
                ffmpeg \
                    -loglevel quiet \
                    -n \
                    -i "$i" \
                    -x264opts colorprim=bt709:transfer=bt709:colormatrix=bt709:fullrange=off \
                    -s 3840x2160 \
                    -c:v libx264 \
                    -pix_fmt yuv420p \
                    -movflags +faststart \
                    -flags +loop \
                    -preset medium \
                    -b:v 30000k \
                    -maxrate 38400k \
                    -bufsize 38400k \
                    -f mp4 \
                    "$fileName"
                mv -f "$i" "_Originals/"
            else
                echo "Skipping: $i ($filesize bytes) — does not match filters or is too small"
            fi
        done
    )
done