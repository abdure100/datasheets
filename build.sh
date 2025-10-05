#!/bin/bash

# ABA Data Collection App Build Script

echo "Building ABA Data Collection App..."

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

echo "Build complete!"
echo "Web build: build/web/"
echo "Android build: build/app/outputs/flutter-apk/"
