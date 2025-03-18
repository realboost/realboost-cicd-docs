#!/bin/bash

# Check if pandoc is installed
if ! command -v pandoc &> /dev/null; then
    echo "Error: pandoc is not installed. Please install it first."
    echo "On MacOS: brew install pandoc"
    exit 1
fi

# Create word directory if it doesn't exist
mkdir -p word

# Find all MD files recursively in current directory and subdirectories
find . -type f -name "*.md" | while read file; do
    # Check if file is not README.md
    if [ "$(echo "$file" | tr '[:upper:]' '[:lower:]')" != "./readme.md" ]; then
        # Get filename without extension
        filename="${file%.*}"
        # Get directory path
        dir="$(dirname "$file")"
        # Create corresponding word directory
        mkdir -p "word/$dir"
        
        echo "Converting $file to word/$filename.docx..."
        
        # Convert MD to DOCX using pandoc
        pandoc "$file" -f markdown -t docx -o "word/$filename.docx"
        
        # Check if conversion was successful
        if [ $? -eq 0 ]; then
            echo "Successfully converted $file to word/$filename.docx"
        else
            echo "Error converting $file"
        fi
    fi
done

echo "Conversion complete!"
