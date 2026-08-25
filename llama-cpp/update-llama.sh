#!/bin/sh

# Exit immediately if a command exits with a non-zero status
set -e

# ================= Configuration =================
# Target asset suffix, can be customized via environment variable or edited here
ASSET_SUFFIX="${LLAMA_ASSET_SUFFIX:-bin-ubuntu-vulkan-x64}"
# ASSET_SUFFIX="${LLAMA_ASSET_SUFFIX:-bin-ubuntu-sycl-fp32-x64}"

# Download and storage directory
DOWNLOAD_DIR="./llama-cpp-binary"
mkdir -p "$DOWNLOAD_DIR"

# GitHub repository for llama.cpp releases
REPO="ggml-org/llama.cpp"

# ================= Fetch Latest 'b' Version =================
printf "Checking the latest 'b' version from GitHub releases...\n"

# Use GitHub API or release redirect URL to find the latest tag starting with 'b'
# We filter tags via GitHub's HTML/API or use grep on the releases/latest page redirect
LATEST_TAG=$(curl -sSL -I "https://github.com/${REPO}/releases/latest" | grep -i "^location:" | sed 's#.*/tag/##' | tr -d '\r')

# Fallback: if 'latest' points to a 'v' tag (like v0.3.0) without binaries, fetch the tags list to find the latest 'b' tag
case "$LATEST_TAG" in
    b*)
        # Latest is already a 'b' version
        ;;
    *)
        printf "Latest release tag '%s' does not start with 'b'. Searching for the latest 'b' version...\n" "$LATEST_TAG"
        # Fetch recent tags from GitHub tags page or API using grep/sed (POSIX compatible)
        LATEST_TAG=$(curl -sSL "https://github.com/${REPO}/tags" | grep -oE '/ggml-org/llama.cpp/releases/tag/b[0-9]+' | head -n 1 | sed 's#.*/##')
        ;;
esac

if [ -z "$LATEST_TAG" ]; then
    printf "Error: Failed to fetch the latest 'b' version tag.\n" >&2
    exit 1
fi

printf "Latest available version is: %s\n" "$LATEST_TAG"

# ================= Version Check & Download =================
# Construct target filename and paths
TAR_NAME="llama-${LATEST_TAG}-${ASSET_SUFFIX}.tar.gz"
DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${LATEST_TAG}/${TAR_NAME}"
TARGET_FILE="${DOWNLOAD_DIR}/${TAR_NAME}"

if [ -f "$TARGET_FILE" ]; then
    printf "Version %s with suffix '%s' already exists locally. No download needed.\n" "$LATEST_TAG" "$ASSET_SUFFIX"
else
    printf "New version detected or file missing. Downloading %s...\n" "$TAR_NAME"
    printf "URL: %s\n" "$DOWNLOAD_URL"

    # Download using curl
    if curl -sSL -f -o "$TARGET_FILE" "$DOWNLOAD_URL"; then
        printf "Successfully downloaded %s to %s\n" "$TAR_NAME" "$DOWNLOAD_DIR"
    else
        printf "Error: Failed to download from %s\n" "$DOWNLOAD_URL" >&2
        # Clean up partial file if exists
        rm -f "$TARGET_FILE"
        exit 1
    fi
fi

printf "Done. Latest binary package is ready at: %s\n" "$TARGET_FILE"
