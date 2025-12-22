#!/bin/bash

# Xcode Archive Script
# Creates an iOS archive for distribution via TestFlight or App Store
# Usage: ./create_xcode_archive.sh [version] [build_number]

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Change to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo ""
echo "=========================================="
echo "  Xcode Archive Script"
echo "=========================================="
echo ""

# Get version from pubspec.yaml if not provided
CURRENT_VERSION=$(grep "^version:" pubspec.yaml | sed 's/version: //' | sed 's/+.*//')
CURRENT_BUILD=$(grep "^version:" pubspec.yaml | sed 's/.*+//')

VERSION=${1:-$CURRENT_VERSION}
BUILD_NUMBER=${2:-$((CURRENT_BUILD + 1))}

echo "📱 App Configuration:"
echo "   Bundle ID: com.sphereemr.datasheets"
echo "   Version: $VERSION"
echo "   Build Number: $BUILD_NUMBER"
echo ""

# Update pubspec.yaml version
echo "📝 Updating version in pubspec.yaml..."
sed -i '' "s/^version:.*/version: $VERSION+$BUILD_NUMBER/" pubspec.yaml
echo "✅ Version updated to $VERSION+$BUILD_NUMBER"
echo ""

# Clean previous builds
echo "🧹 Cleaning previous builds..."
flutter clean
echo "✅ Clean complete"
echo ""

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get
echo "✅ Dependencies installed"
echo ""

# Generate code
echo "🔧 Generating code..."
flutter packages pub run build_runner build --delete-conflicting-outputs || true
echo "✅ Code generation complete"
echo ""

# Build iOS app in release mode
echo "🏗️  Building iOS app (Release mode)..."
flutter build ios --release --no-codesign
echo "✅ iOS build complete"
echo ""

# Set paths
WORKSPACE_PATH="ios/Runner.xcworkspace"
SCHEME="Runner"
ARCHIVE_PATH="$HOME/Library/Developer/Xcode/Archives/$(date +%Y-%m-%d)/Runner-$(date +%Y-%m-%d-%H.%M.%S).xcarchive"
EXPORT_OPTIONS="ios/exportOptions.plist"
EXPORT_PATH="build/ios/export"

# Create export directory
mkdir -p "$EXPORT_PATH"

echo "📦 Creating Xcode archive..."
echo "   Workspace: $WORKSPACE_PATH"
echo "   Scheme: $SCHEME"
echo "   Archive Path: $ARCHIVE_PATH"
echo ""

# Create archive using xcodebuild
# Explicitly target iOS device (not Mac)
xcodebuild archive \
  -workspace "$WORKSPACE_PATH" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=iOS" \
  -allowProvisioningUpdates \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=RZW6S4A75D \
  PROVISIONING_PROFILE_SPECIFIER="" \
  || {
    echo ""
    echo "${RED}❌ Archive creation failed!${NC}"
    echo ""
    echo "💡 Common issues:"
    echo "   1. Make sure you're signed in to Xcode with your Apple Developer account"
    echo "   2. Check that your development team is set correctly"
    echo "   3. Verify code signing settings in Xcode"
    echo "   4. Try opening the workspace in Xcode and archiving manually first"
    echo ""
    exit 1
  }

echo ""
echo "✅ Archive created successfully!"
echo ""

# Export IPA (optional - uncomment if you want to export automatically)
read -p "Do you want to export the IPA now? (y/n) " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
  echo "📤 Exporting IPA..."
  
  xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -exportPath "$EXPORT_PATH" \
    -allowProvisioningUpdates \
    || {
      echo ""
      echo "${YELLOW}⚠️  IPA export failed. You can export manually from Xcode Organizer.${NC}"
      echo ""
    }
  
  if [ -f "$EXPORT_PATH/Runner.ipa" ]; then
    echo ""
    echo "✅ IPA exported successfully!"
    echo "   Location: $EXPORT_PATH/Runner.ipa"
    echo ""
  fi
fi

echo ""
echo "=========================================="
echo "  Archive Complete!"
echo "=========================================="
echo ""
echo "📦 Archive Location:"
echo "   $ARCHIVE_PATH"
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Open Xcode Organizer:"
echo "   - Open Xcode"
echo "   - Go to Window > Organizer (or press Cmd+Shift+9)"
echo "   - Select your archive"
echo ""
echo "2. Distribute App:"
echo "   - Click 'Distribute App'"
echo "   - Choose 'App Store Connect'"
echo "   - Choose 'Upload'"
echo "   - Select your team and signing options"
echo "   - Click 'Upload'"
echo ""
echo "3. After upload:"
echo "   - Go to App Store Connect (https://appstoreconnect.apple.com)"
echo "   - Navigate to your app > TestFlight"
echo "   - Wait for processing (10-30 minutes)"
echo "   - Add testers and submit for review"
echo ""
echo "=========================================="
echo ""

