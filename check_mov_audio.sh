#!/bin/bash

# Check if a directory path is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <directory-path>"
  exit 1
fi

# Get the directory path
DIRECTORY="$1"

# Ensure the provided path does not end with a slash
DIRECTORY=${DIRECTORY%/}

# Find all .mov files and check for audio
IFS=$'\n'
MOV_FILES=$(find "$DIRECTORY" -type f -name '*.mov')
MOV_HAS_AUDIO=()

for FILE in $MOV_FILES; do
  if ffprobe -v error -show_entries stream=codec_type -of default=noprint_wrappers=1:nokey=1 "$FILE" | grep -q audio; then
    MOV_HAS_AUDIO+=("$FILE")
  fi
done

# Check if any .mov files with audio were found
if [ ${#MOV_HAS_AUDIO[@]} -eq 0 ]; then
  echo "No .mov files with audio found."
  exit 0
fi

# Ask user for the desired action
echo "Found ${#MOV_HAS_AUDIO[@]} .mov files with audio."
echo "Would you like to (1) copy the files or (2) generate a list? (Enter 1 or 2)"
read -r ACTION

if [ "$ACTION" == "1" ]; then
  # Create the target directory within the provided directory
  TARGET_DIR="$DIRECTORY/movHasAudio"
  mkdir -p "$TARGET_DIR"

  # Copy the files with directory structure
  for FILE in "${MOV_HAS_AUDIO[@]}"; do
    TARGET_PATH="$TARGET_DIR/$(dirname "$FILE" | sed 's|^'"$DIRECTORY"'||')"
    mkdir -p "$TARGET_PATH"
    cp "$FILE" "$TARGET_PATH"
  done

  echo "Files copied to '$TARGET_DIR'."

elif [ "$ACTION" == "2" ]; then
  # Create a tab-delimited list in the provided directory
  OUTPUT_FILE="$DIRECTORY/mov_has_audio_list.txt"
  > "$OUTPUT_FILE"

  for FILE in "${MOV_HAS_AUDIO[@]}"; do
    # Split the file path into its components
    IFS='/'
    FILE_COMPONENTS=($FILE)
    # Join the components with tabs
    FILE_PATH_TABS=$(printf "%s\t" "${FILE_COMPONENTS[@]}")
    # Remove the trailing tab and write to the output file
    echo -e "${FILE_PATH_TABS%\\t}\t$(basename "$FILE")" >> "$OUTPUT_FILE"
  done

  echo "Tab-delimited list created at '$OUTPUT_FILE'."

else
  echo "Invalid option. Exiting."
  exit 1
fi
