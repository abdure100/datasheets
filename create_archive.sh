#!/bin/bash

# Create Archive Script
# Creates a clean archive of the project excluding build artifacts

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Get project name from directory
PROJECT_NAME=$(basename "$SCRIPT_DIR")
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE_NAME="${PROJECT_NAME}_archive_${TIMESTAMP}"

echo ""
echo "=========================================="
echo "  Creating Project Archive"
echo "=========================================="
echo ""
echo "📦 Project: $PROJECT_NAME"
echo "📅 Timestamp: $TIMESTAMP"
echo "📁 Archive: ${ARCHIVE_NAME}.tar.gz"
echo ""

# Create temporary directory for archive
TEMP_DIR=$(mktemp -d)
ARCHIVE_DIR="$TEMP_DIR/$ARCHIVE_NAME"

echo "📂 Preparing archive directory..."
mkdir -p "$ARCHIVE_DIR"

# Copy files, excluding build artifacts and dependencies
echo "📋 Copying project files..."

# Use rsync to copy files with exclusions
rsync -av \
  --exclude='.git' \
  --exclude='build/' \
  --exclude='.dart_tool/' \
  --exclude='.flutter-plugins' \
  --exclude='.flutter-plugins-dependencies' \
  --exclude='.packages' \
  --exclude='.pub-cache/' \
  --exclude='.pub/' \
  --exclude='Pods/' \
  --exclude='Podfile.lock' \
  --exclude='node_modules/' \
  --exclude='*.log' \
  --exclude='*.swp' \
  --exclude='*.swo' \
  --exclude='.DS_Store' \
  --exclude='*.xcuserstate' \
  --exclude='*.xcworkspace/xcuserdata/' \
  --exclude='*.xcodeproj/xcuserdata/' \
  --exclude='DerivedData/' \
  --exclude='*.ipa' \
  --exclude='*.app' \
  --exclude='*.dSYM' \
  --exclude='vendor/' \
  --exclude='composer.lock' \
  . "$ARCHIVE_DIR/"

# Create archive
echo "🗜️  Creating archive..."
cd "$TEMP_DIR"
tar -czf "$SCRIPT_DIR/${ARCHIVE_NAME}.tar.gz" "$ARCHIVE_NAME"

# Clean up
rm -rf "$TEMP_DIR"

# Get archive size
ARCHIVE_SIZE=$(du -h "$SCRIPT_DIR/${ARCHIVE_NAME}.tar.gz" | cut -f1)

echo ""
echo "=========================================="
echo "  Archive Created Successfully!"
echo "=========================================="
echo ""
echo "✅ Archive: ${ARCHIVE_NAME}.tar.gz"
echo "📊 Size: $ARCHIVE_SIZE"
echo "📍 Location: $SCRIPT_DIR"
echo ""
echo "💡 To extract: tar -xzf ${ARCHIVE_NAME}.tar.gz"
echo ""

