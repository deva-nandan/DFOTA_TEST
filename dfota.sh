#!/bin/bash
set -x
# Check if correct number of arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <original_directory> <modified_directory> <atcmd_path>"
    exit 1
fi

# Check if directories exist
if [ ! -d "$1" ]; then
    echo "Error: Original directory $1 does not exist."
    exit 1
fi

if [ ! -d "$2" ]; then
    echo "Error: Modified directory $2 does not exist."
    exit 1
fi


# Create a directory for storing patches if it doesn't exist
PATCH_DIR="patches"
FW_TAR="fw.tar.gz"
MD5_FILE="md5"
DFOTA_TAR="dfota.tar.gz"
mkdir -p "$PATCH_DIR"

if [ -f "$3" ]; then
    atcmd_md5="$PATCH_DIR/atcmd.txt"
    md5sum "$3" | cut -d " " -f 1 > "$atcmd_md5"
    mv "$3" "$PATCH_DIR"
fi

# Loop through all files in the original directory
for original_file in "$1"/*; do
    if [ -f "$original_file" ]; then
        filename=$(basename -- "$original_file")
        modified_file="$2/$filename"
        patch_file="$PATCH_DIR/$filename.patch"
        patch_md5="$PATCH_DIR/$filename.txt"
        
        # Check if modified file exists
        if [ ! -f "$modified_file" ]; then
            # Create an empty file in modified directory
            touch "$modified_file"
        fi
        
        # Generate patch file
        echo "Creating patch for $filename..."
        bsdiff "$original_file" "$modified_file" "$patch_file"
        md5sum "$modified_file" | cut -d " " -f 1 > "$patch_md5" 
    fi
done

echo "All patches generated successfully."
echo "Creating dfota tarball..."
# Create a tarball containing all patch files and their corresponding MD5 files
tar -czvf "$FW_TAR" "$PATCH_DIR"

# Create MD5 hash of fw.tar.gz
md5sum "$FW_TAR" > "$MD5_FILE"

# Create a tarball containing the MD5 file and the fw.tar.gz file
tar -czvf "$DFOTA_TAR" "$MD5_FILE" "$FW_TAR"

rm "$MD5_FILE" "$FW_TAR"

echo "Done"
