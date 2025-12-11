#!/bin/bash

# Script to generate GoogleService-Info.plist from .env file
# This should be run as a build phase in Xcode

set -e

PROJECT_DIR="${PROJECT_DIR:-.}"
ENV_FILE="$PROJECT_DIR/.env"
TEMPLATE_FILE="$PROJECT_DIR/fit-texas/GoogleService-Info.plist.template"
OUTPUT_FILE="$PROJECT_DIR/fit-texas/GoogleService-Info.plist"

# Check if .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "Error: .env file not found at $ENV_FILE"
    exit 1
fi

# Check if template file exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Error: Template file not found at $TEMPLATE_FILE"
    exit 1
fi

echo "Generating GoogleService-Info.plist from .env..."

# Load environment variables from .env file
export $(grep -v '^#' "$ENV_FILE" | xargs)

# Read the template file
TEMPLATE_CONTENT=$(<"$TEMPLATE_FILE")

# Replace placeholders with environment variables
OUTPUT_CONTENT="$TEMPLATE_CONTENT"
OUTPUT_CONTENT="${OUTPUT_CONTENT//\$\{API_KEY\}/$API_KEY}"
OUTPUT_CONTENT="${OUTPUT_CONTENT//\$\{GCM_SENDER_ID\}/$GCM_SENDER_ID}"
OUTPUT_CONTENT="${OUTPUT_CONTENT//\$\{PLIST_VERSION\}/$PLIST_VERSION}"
OUTPUT_CONTENT="${OUTPUT_CONTENT//\$\{BUNDLE_ID\}/$BUNDLE_ID}"
OUTPUT_CONTENT="${OUTPUT_CONTENT//\$\{PROJECT_ID\}/$PROJECT_ID}"
OUTPUT_CONTENT="${OUTPUT_CONTENT//\$\{STORAGE_BUCKET\}/$STORAGE_BUCKET}"
OUTPUT_CONTENT="${OUTPUT_CONTENT//\$\{GOOGLE_APP_ID\}/$GOOGLE_APP_ID}"

# Handle boolean values - convert to proper plist boolean tags
OUTPUT_CONTENT="${OUTPUT_CONTENT//BOOL_IS_ADS_ENABLED/$IS_ADS_ENABLED}"
OUTPUT_CONTENT="${OUTPUT_CONTENT//BOOL_IS_ANALYTICS_ENABLED/$IS_ANALYTICS_ENABLED}"
OUTPUT_CONTENT="${OUTPUT_CONTENT//BOOL_IS_APPINVITE_ENABLED/$IS_APPINVITE_ENABLED}"
OUTPUT_CONTENT="${OUTPUT_CONTENT//BOOL_IS_GCM_ENABLED/$IS_GCM_ENABLED}"
OUTPUT_CONTENT="${OUTPUT_CONTENT//BOOL_IS_SIGNIN_ENABLED/$IS_SIGNIN_ENABLED}"

# Write to output file
echo "$OUTPUT_CONTENT" > "$OUTPUT_FILE"

echo "✅ GoogleService-Info.plist generated successfully"
