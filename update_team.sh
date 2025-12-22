#!/bin/bash
# Script to update the development team in Xcode project
# Usage: ./update_team.sh <TEAM_ID>
# Team ID should be alphanumeric (e.g., ABC123XYZ, 44GY3MRW88)

if [ -z "$1" ]; then
    echo "Usage: ./update_team.sh <TEAM_ID>"
    echo "Example: ./update_team.sh ABC123XYZ"
    echo ""
    echo "⚠️  Team ID must be alphanumeric (not an email address!)"
    echo "   Find it in Xcode: Settings > Accounts > Select team"
    exit 1
fi

TEAM_ID="$1"

# Validate Team ID format (should be alphanumeric, typically 10 characters)
if [[ ! "$TEAM_ID" =~ ^[A-Z0-9]{8,12}$ ]]; then
    echo "❌ ERROR: Invalid Team ID format!"
    echo ""
    echo "Team ID must be alphanumeric (e.g., ABC123XYZ, 44GY3MRW88)"
    echo "You provided: $TEAM_ID"
    echo ""
    echo "⚠️  If you provided an email address, that's incorrect!"
    echo "   Team IDs are shown in Xcode Settings > Accounts"
    echo "   They look like: 44GY3MRW88 or RZW6S4A75D"
    exit 1
fi

PROJECT_FILE="ios/Runner.xcodeproj/project.pbxproj"

if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ ERROR: Project file not found: $PROJECT_FILE"
    exit 1
fi

echo "Updating team ID to: $TEAM_ID"

# Update all occurrences of DEVELOPMENT_TEAM
sed -i '' "s/DEVELOPMENT_TEAM = [^;]*/DEVELOPMENT_TEAM = $TEAM_ID/g" "$PROJECT_FILE"

echo "✅ Team ID updated in project.pbxproj"
echo ""
echo "Next steps:"
echo "1. Open ios/Runner.xcworkspace in Xcode"
echo "2. Go to Signing & Capabilities"
echo "3. Verify the team is correct"
echo "4. Rebuild the archive"

