#!/usr/bin/env bash

set -euo pipefail

cleanFiles() {
    local target_dir="${1:-.}"

    if [[ ! -d "$target_dir" ]]; then
        exit 1
    fi

    find "$target_dir" -type f \( \
        -name "*.aux" -o \
        -name "*.fls" -o \
        -name "*.log" -o \
        -name "*.blg" -o \
        -name "*.fdb_latexmk" -o \
        -name "*.bbl" -o \
        -name "*.bbl-SAVE-ERROR" -o \
        -name "*.bcf" -o \
        -name "*.bcf-SAVE-ERROR" -o \
        -name "*.xdv" -o \
        -name "*.xml" -o \
        -name "*.run.xml" -o \
        -name "*.synctex.gz" -o \
        -name "*.synctex(busy)" \
    \) -delete

    find "$target_dir" -type f -name "* [0-9].*" -delete
}

# Main
case "${1:-}" in
    --cleanFiles)
        cleanFiles "${2:-}"
        exit 0
        ;;
    *)
        echo "Usage: $(basename "$0") [--cleanFiles] [path_to_directory]"
        exit 1
        ;;
esac
