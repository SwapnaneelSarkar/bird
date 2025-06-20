#!/bin/bash

echo "🚀 Building Bird App for Play Store Release"
echo "=========================================="

# Clean the project
echo "🧹 Cleaning project..."
flutter clean

# Get dependencies
echo "📦 Getting dependencies..."
flutter pub get

# Build release APK
echo "🔨 Building release APK..."
flutter build apk --release

# Check if build was successful
if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📱 APK location: build/app/outputs/flutter-apk/app-release.apk"
    echo "📊 Version: 1.0.2 (Build 4)"
    echo ""
    echo "🎯 Next steps:"
    echo "1. Upload the APK to Google Play Console"
    echo "2. Create a new release in the Play Console"
    echo "3. Add release notes describing your changes"
    echo "4. Submit for review"
else
    echo "❌ Build failed!"
    exit 1
fi 