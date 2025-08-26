#!/bin/bash

# .SYNOPSIS
#     Create a book cover image using ImageMagick.
# .DESCRIPTION
#     This script generates a book cover image based on metadata from epub.yaml.
#     It allows the user to specify the paper size (A4 or A6).
# .PARAMETER PaperSize
#     Specifies the paper size for the cover image. Valid values are "A4" or "A6".
# .EXAMPLE
#     ./create_cover.sh -PaperSize A4

# Default paper size
PAPER_SIZE="A4"

# Parse command-line arguments
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -PaperSize) 
            if [[ "$2" == "A4" || "$2" == "A6" ]]; then
                PAPER_SIZE="$2"
                shift
            else
                echo "Error: Invalid PaperSize. Must be A4 or A6."
                exit 1
            fi
            ;; 
        *) 
            echo "Unknown parameter passed: $1"
            exit 1
            ;; 
    esac
    shift
done

# Check for ImageMagick and yq
if ! command -v magick &> /dev/null; then
    echo "Error: ImageMagick (magick command) not found. Please install it."
    exit 1
fi

if ! command -v yq &> /dev/null; then
    echo "Error: yq (YAML processor) not found. Please install it (e.g., brew install yq or snap install yq)."
    exit 1
fi

# Read metadata from epub.yaml using yq
TITLE=$(yq '.title | select(has("type") and .type == "main") | .text' epub.yaml)
if [ -z "$TITLE" ]; then
    TITLE=$(yq '.title' epub.yaml) # Fallback if not array or main type not found
fi
SUBTITLE=$(yq '.title | select(has("type") and .type == "subtitle") | .text' epub.yaml)

# Define image dimensions based on paper size
case "$PAPER_SIZE" in
    "A4")
        WIDTH=2480
        HEIGHT=3508
        ;; 
    "A6")
        WIDTH=1240
        HEIGHT=1748
        ;; 
esac

# Ensure output folder exists
OUTPUT_DIR="images"
mkdir -p "$OUTPUT_DIR"

OUTPUT_FILE="$OUTPUT_DIR/cover.png"
OUTPUT_BACK_COVER_FILE="$OUTPUT_DIR/back_cover.png"
OUTPUT_PDF="$OUTPUT_DIR/cover.pdf"
OUTPUT_BACK_COVER_PDF="$OUTPUT_DIR/back_cover.pdf"

# Create a white background image
magick -size "${WIDTH}x${HEIGHT}" xc:white "$OUTPUT_FILE"
magick -size "${WIDTH}x${HEIGHT}" xc:white "$OUTPUT_BACK_COVER_FILE"

# Add title and subtitle (quoted to handle spaces)
magick "$OUTPUT_FILE" \
    -gravity center \
    -pointsize 150 \
    -annotate +0-200 "$TITLE" \
    -pointsize 80 \
    -annotate +0+100 "$SUBTITLE" \
    "$OUTPUT_FILE"

# Convert to PDF
magick "$OUTPUT_FILE" "$OUTPUT_PDF"
magick "$OUTPUT_BACK_COVER_FILE" "$OUTPUT_BACK_COVER_PDF"

echo "✅ Cover image created at $OUTPUT_FILE"
echo "✅ PDF version created at $OUTPUT_PDF"
