#!/bin/bash

# NOTE: This script is intentionally simplified and omits error checking
# for better code clarity.

#--- Variable Declarations ---
# Define target directory and repository URL
repository_url="git@github.com:DavydMelnik/belhard-devops.git"
destination_directory="/tmp/$(basename "${repository_url%/.git}")_$(date +'%Y%m%d%H%M%S')"

# --- Function Definitions ---
#Clones a Git repository
git_clone_repository() {
    local repository_url=$1
    local destination_directory=$2

    git clone "$repository_url" "$destination_directory"
}

#Processes Git tags and increments version if needed
update_tag_patch() {
    local destination_directory=$1

    if git -C "$destination_directory" describe --tags --abbrev=0 --exact-match >/dev/null 2>&1; then
        echo "No changes."
    else
        tag=$(git -C "$destination_directory" describe --tags --abbrev=0)
        new_tag=$(echo "$tag" | awk -F. '{ $NF++; print $1"."$2"."$NF }')
        echo "New version: $new_tag"
        git -C "$destination_directory" tag -a "$new_tag" -m "chore(release): auto-increment patch version to $new_tag [created by bash script]"
        git -C "$destination_directory" push origin "$new_tag"
    fi
}

#Deleting local directory
remove_local_dir() {
    local dir_to_remove=$1

    rm -rf "$dir_to_remove"
}

# --- Main execution ---
git_clone_repository "$repository_url" "$destination_directory"
update_tag_patch "$destination_directory"
remove_local_dir "$destination_directory"
