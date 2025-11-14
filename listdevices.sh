#!/bin/bash

# List Flutter devices and copy device ID to clipboard

# Change to script directory to ensure we're in the project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo "Scanning for Flutter devices..."
echo ""

# Run flutter devices and capture output
DEVICES_OUTPUT=$(flutter devices 2>&1)

# Extract device lines (those with • separator)
DEVICE_LINES=$(echo "$DEVICES_OUTPUT" | grep -E "•.*•.*•" | grep -v "Found")

if [ -z "$DEVICE_LINES" ]; then
    echo "No devices found."
    exit 1
fi

echo "Available devices:"
echo "=================="
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
        
        echo "$COUNT. $DEVICE_NAME"
        echo "   ID: $DEVICE_ID"
        echo ""
    fi
done <<< "$DEVICE_LINES"

if [ $COUNT -eq 0 ]; then
    echo "No valid devices found."
    exit 1
fi

# If only one device, automatically copy it
if [ $COUNT -eq 1 ]; then
    SELECTED_ID=${DEVICE_IDS[1]}
    SELECTED_NAME=${DEVICE_NAMES[1]}
    echo "Only one device found. Copying ID to clipboard..."
else
    # Prompt user to select a device
    echo "Select a device (1-$COUNT) or press Enter to copy the first device: "
    read -r SELECTION
    
    if [ -z "$SELECTION" ]; then
        SELECTION=1
    fi
    
    # Validate selection
    if ! [[ "$SELECTION" =~ ^[0-9]+$ ]] || [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt $COUNT ]; then
        echo "Invalid selection. Using first device."
        SELECTION=1
    fi
    
    SELECTED_ID=${DEVICE_IDS[$SELECTION]}
    SELECTED_NAME=${DEVICE_NAMES[$SELECTION]}
fi

# Copy to clipboard
echo "$SELECTED_ID" | pbcopy

echo "✅ Device ID copied to clipboard:"
echo "   Name: $SELECTED_NAME"
echo "   ID: $SELECTED_ID"
echo ""
echo "You can now paste it with Cmd+V"

