#!/bin/bash

# ABA Data Collection App Build Script - DEBUG MODE
# Usage: ./buildd.sh [device-id]
#   device-id: Optional device ID from 'flutter devices' output
#              If not provided, will prompt for device selection

# Change to script directory to ensure we're in the project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

# Get device ID from command line argument or prompt for it
DEVICE_ID=""
if [ -z "$1" ]; then
    echo ""
    echo "=========================================="
    echo "  DEVICE SELECTION"
    echo "=========================================="
    echo ""
    
    # Run flutter devices and capture output
    DEVICES_OUTPUT=$(flutter devices 2>&1)
    
    # Extract device lines (those with • separator)
    DEVICE_LINES=$(echo "$DEVICES_OUTPUT" | grep -E "•.*•.*•" | grep -v "Found")
    
    if [ -z "$DEVICE_LINES" ]; then
        echo "⚠️  No devices found."
        echo ""
        read -p "Enter device ID manually (or press Enter to skip running): " DEVICE_ID
    else
        echo "Available devices:"
        echo ""
        
        # Counter for device selection
        COUNT=0
        declare -a DEVICE_IDS
        declare -a DEVICE_NAMES
        
        # Parse each device line
        while IFS= read -r line; do
            # Skip empty lines
            [ -z "$line" ] && continue
            
            # Extract device name (everything before the first •, keep all labels)
            DEVICE_NAME=$(echo "$line" | sed -E 's/^[[:space:]]*([^•]+).*/\1/' | xargs)
            
            # Extract device ID (between first and second •)
            DEVICE_ID=$(echo "$line" | awk -F '•' '{print $2}' | xargs)
            
            if [ -n "$DEVICE_ID" ] && [ -n "$DEVICE_NAME" ]; then
                COUNT=$((COUNT + 1))
                DEVICE_IDS[$COUNT]=$DEVICE_ID
                DEVICE_NAMES[$COUNT]=$DEVICE_NAME
                
                echo "  $COUNT. $DEVICE_NAME"
                echo "     ID: $DEVICE_ID"
                echo ""
            fi
        done <<< "$DEVICE_LINES"
        
        if [ $COUNT -eq 0 ]; then
            echo "⚠️  No valid devices found."
            echo ""
            read -p "Enter device ID manually (or press Enter to skip running): " DEVICE_ID
        else
            echo "=========================================="
            echo ""
            read -p "Select device (1-$COUNT) or press Enter to skip running: " SELECTION
            
            if [ -z "$SELECTION" ]; then
                DEVICE_ID=""
            elif [[ "$SELECTION" =~ ^[0-9]+$ ]] && [ "$SELECTION" -ge 1 ] && [ "$SELECTION" -le $COUNT ]; then
                DEVICE_ID=${DEVICE_IDS[$SELECTION]}
                echo ""
                echo "✅ Selected: ${DEVICE_NAMES[$SELECTION]}"
                echo "   ID: $DEVICE_ID"
            else
                echo ""
                echo "⚠️  Invalid selection. Skipping device run."
                DEVICE_ID=""
            fi
        fi
        
        echo ""
        echo "=========================================="
        echo ""
    fi
else
    DEVICE_ID="$1"
fi

# Kill Xcode if it's open (prevents build conflicts)
echo "Checking for Xcode..."
if pgrep -x "Xcode" > /dev/null; then
    echo "Xcode is running. Killing Xcode..."
    killall Xcode 2>/dev/null || true
    sleep 1
    echo "Xcode closed."
else
    echo "Xcode is not running."
fi

# Clean previous builds
echo "Cleaning previous builds..."
flutter clean

# Get dependencies
echo "Getting dependencies..."
flutter pub get

# Generate JSON serialization code
echo "Generating JSON serialization code..."
flutter packages pub run build_runner build --delete-conflicting-outputs

# Check for any issues
echo "Checking for issues..."
flutter analyze

# Build for different platforms
echo "Building for web..."
flutter build web

echo "Building for Android..."
flutter build apk

# Run on device if device ID was provided
if [ -n "$DEVICE_ID" ]; then
    echo "Running on device ID: $DEVICE_ID (DEBUG MODE)"
    flutter run -d "$DEVICE_ID" --debug
else
    echo "Build complete!"
    echo "Web build: build/web/"
    echo "Android build: build/app/outputs/flutter-apk/"
    echo ""
    echo "To run on a device, use: ./buildd.sh <device-id>"
    echo "Or run: ./listdevices.sh to get device IDs"
fi
