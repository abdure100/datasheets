#!/bin/bash

# TestFlight Build and Upload Script
# This script builds the iOS app and prepares it for TestFlight distribution
# Usage: ./build_testflight.sh [version] [build_number]
#   version: App version (e.g., 1.0.0) - defaults to current version in pubspec.yaml
#   build_number: Build number (e.g., 1, 2, 3) - defaults to incrementing current build

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Change to script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR" || exit 1

echo ""
echo "=========================================="
echo "  TestFlight Build Script"
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

# Open Xcode workspace
echo "📂 Opening Xcode workspace..."
open ios/Runner.xcworkspace

echo ""
echo "=========================================="
echo "  Next Steps in Xcode:"
echo "=========================================="
echo ""
echo "1. In Xcode, select 'Any iOS Device' or 'Generic iOS Device' as the target"
echo "2. Go to Product > Archive"
echo "3. Wait for the archive to complete"
echo "4. In the Organizer window:"
echo "   - Select your archive"
echo "   - Click 'Distribute App'"
echo "   - Choose 'App Store Connect'"
echo "   - Choose 'Upload'"
echo "   - Select your team and signing options"
echo "   - Click 'Upload'"
echo ""
echo "5. After upload completes:"
echo "   - Go to App Store Connect (https://appstoreconnect.apple.com)"
echo "   - Navigate to your app > TestFlight"
echo "   - Wait for processing (10-30 minutes)"
echo "   - Add testers and submit for review"
echo ""
echo "=========================================="
echo ""
echo "📋 Build Information:"
echo "   Version: $VERSION"
echo "   Build: $BUILD_NUMBER"
echo "   Archive will be created in Xcode"
echo ""
echo "💡 Tip: You can also use 'fastlane' to automate the upload process"
echo ""

