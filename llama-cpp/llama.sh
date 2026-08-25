#!/bin/sh

# pacman -S vulkan-icd-loader vulkan-intel

# usage ./llama.sh llama-server -m /path/to/Model.gguf
# run things in /tmp

# Exit immediately if a command exits with a non-zero status
set -e

# ================= Step 0: Parse Subcommand Argument =================
if [ $# -lt 1 ]; then
    printf "Usage: %s <executable_name> [args...]\n" "$0" >&2
    printf "Example: %s llama-server -m model.gguf --port 8080\n" "$0" >&2
    exit 1
fi

# The first argument is the name of the executable to run (e.g., llama-server, llama-cli)
TARGET_TOOL="$1"
shift # Shift arguments so $* and $@ contain only the remaining parameters

# ================= Step 1: Run Update Script =================
UPDATE_SCRIPT="./update-llama.sh"
if [ ! -f "$UPDATE_SCRIPT" ]; then
    printf "Error: Update script '%s' not found in the current directory.\n" "$UPDATE_SCRIPT" >&2
    exit 1
fi

# Run the update script to ensure the latest version is downloaded
sh "$UPDATE_SCRIPT"

# ================= Step 2: Find Latest tar.gz in Cache =================
BINARY_DIR="./llama-cpp-binary"
if [ ! -d "$BINARY_DIR" ]; then
    printf "Error: Binary directory '%s' does not exist.\n" "$BINARY_DIR" >&2
    exit 1
fi

# Find the latest tar.gz file based on version number
LATEST_TAR=$(find "$BINARY_DIR" -maxdepth 1 -name "llama-b*-bin-*.tar.gz" | sort -V | tail -n 1)

if [ -z "$LATEST_TAR" ]; then
    printf "Error: No matching llama tar.gz package found in '%s'.\n" "$BINARY_DIR" >&2
    exit 1
fi

printf "Using local package: %s\n" "$LATEST_TAR"

# ================= Step 3: Extract to Random Temp Directory =================
if command -v mktemp >/dev/null 2>&1; then
    TEMP_DIR=$(mktemp -d /tmp/llama-sh-XXXXXX)
else
    RANDOM_STR=$(date +%s)_$$
    TEMP_DIR="/tmp/llama-sh-$RANDOM_STR"
    mkdir -p "$TEMP_DIR"
fi

cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        printf "Cleaning up temporary directory: %s\n" "$TEMP_DIR"
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT INT TERM

printf "Extracting package to temporary directory...\n"
tar -xzf "$LATEST_TAR" -C "$TEMP_DIR"

# ================= Step 4: Locate Executable and Run =================
# Directly search for the user-specified tool (e.g. llama-server) inside the extracted files
LLAMA_EXEC=$(find "$TEMP_DIR" -type f -name "$TARGET_TOOL" | head -n 1)

if [ -z "$LLAMA_EXEC" ] || [ ! -f "$LLAMA_EXEC" ]; then
    printf "Error: Could not find executable '%s' inside the extracted package.\n" "$TARGET_TOOL" >&2
    exit 1
fi

# Ensure execution permission
chmod +x "$LLAMA_EXEC"

printf "Executing %s with arguments: %s\n" "$LLAMA_EXEC" "$*"

# Run the target executable with the remaining arguments
"$LLAMA_EXEC" "$@"
