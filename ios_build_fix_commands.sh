#!/bin/bash
# iOS Build Fix Commands
# Use these commands when encountering stale file or framework errors

echo "🧹 Step 1: Cleaning Flutter build..."
flutter clean

echo "📦 Step 2: Getting Flutter dependencies..."
flutter pub get

echo "🍎 Step 3: Setting UTF-8 encoding and installing CocoaPods..."
export LANG=en_US.UTF-8
cd ios
pod install
cd ..

echo "✅ Build environment cleaned and ready!"
echo "🚀 Now run: flutter run -d <device-id>"

