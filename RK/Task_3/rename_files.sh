#!/bin/bash
if [ $# -ne 1 ]; then
    echo "Usage: $0 directory"
    exit 1
fi

directory="$1"

if [ ! -d "$directory" ]; then
    echo "Error: Directory '$directory' does not exist"
    exit 1
fi

cd "$directory" || exit 1

files=($(find . -maxdepth 1 -type f -not -name ".*" | sed 's|^\./||' | grep -v "^rename_files.sh$"))
count=${#files[@]}

if [ $count -eq 0 ]; then
    echo "No files to rename in directory '$directory'"
    exit 0
fi

echo "Found $count files in directory '$directory'"

for i in $(seq 1 2); do
    if [ ${#files[@]} -eq 0 ]; then
        break
    fi
    
    random_index=$((RANDOM % ${#files[@]}))
    file="${files[$random_index]}"
    new_name="random_$(head /dev/urandom | tr -dc a-z0-9 | head -c 8).dat"
    mv "$file" "$new_name"
    echo "Renamed: $file -> $new_name"
    unset 'files[random_index]'
    files=("${files[@]}")
done

echo "Renaming completed"
