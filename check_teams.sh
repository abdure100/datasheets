#!/bin/bash
# Check available teams in Xcode project

echo "Checking Xcode project for team information..."
echo ""

# Try to extract team info from project
grep -A 2 "DEVELOPMENT_TEAM" ios/Runner.xcodeproj/project.pbxproj | head -10

echo ""
echo "To find the Team ID for admin@sphereemr.com:"
echo "1. Open Xcode"
echo "2. Go to Xcode > Settings > Accounts"
echo "3. Find admin@sphereemr.com"
echo "4. Note the Team ID shown next to the team name"
echo ""
echo "Or in the project:"
echo "1. Open ios/Runner.xcworkspace"
echo "2. Select Runner project > Runner target"
echo "3. Go to Signing & Capabilities"
echo "4. Check the Team dropdown - it will show available teams"

