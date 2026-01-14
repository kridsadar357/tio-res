#!/bin/bash
# build_with_safe_date.sh
# This script temporarily changes the system date to build the Flutter app
# Then restores automatic date/time synchronization

echo "⚠️  This script will change the system date temporarily"
echo ""

# Pre-download dependencies (while date is correct)
echo "📦 resolving dependencies with correct system date..."
flutter pub get
# Trigger a full build attempt to ensure ALL artifacts are cached (ignore failure)
echo "📦 Pre-downloading Gradle dependencies (running assembleDebug)..."
cd android
./gradlew app:assembleDebug || true
# Stop the gradle daemon so it doesn't carry over the old date
./gradlew --stop
cd ..

# Save current date
CURRENT_DATE=$(date)
echo "Current date: $CURRENT_DATE"

# Disable automatic date/time
echo "Disabling automatic date/time..."
sudo systemsetup -setusingnetworktime off 2>/dev/null

# Set date to November 1, 2025 (after certificate issue dates but before 2026)
echo "Setting date to November 1, 2025..."
sudo date 110112002025

echo "New date: $(date)"
echo ""

# Update file timestamps to current (spoofed) date to prevent "future file" errors
# We exclude .gradle and .git to avoid messing with cache/vcs internals unnecessarily
echo "Updating file timestamps to match spoofed date..."
find . -type f -not -path "*/.git/*" -not -path "*/.gradle/*" -not -path "*/build/*" -exec touch {} +

# Clean build artifacts? NO. We need the cache. 
# But maybe clean 'build' to force gradle to link stuff? 
# If we run assembleDebug --offline, it should work.

# Run Gradle Build Offline
echo "Building APK offline..."
cd android
./gradlew app:assembleDebug --offline
GRADLE_RESULT=$?
cd ..

if [ $GRADLE_RESULT -ne 0 ]; then
    echo "❌ Gradle build failed."
    # Restore automatic date/time before exiting
    echo "Restoring automatic date/time..."
    sudo systemsetup -setusingnetworktime on 2>/dev/null
    exit $GRADLE_RESULT
fi

# Run Flutter with the prebuilt APK
echo "Launching Flutter app..."
flutter run --use-application-binary=android/app/build/outputs/apk/debug/app-debug.apk

# Store build result
BUILD_RESULT=$?

# Restore automatic date/time
echo ""
echo "Restoring automatic date/time..."
sudo systemsetup -setusingnetworktime on 2>/dev/null

echo "Date restored: $(date)"

if [ $BUILD_RESULT -eq 0 ]; then
    echo "✅ Build successful!"
else
    echo "❌ Build failed with exit code: $BUILD_RESULT"
fi

exit $BUILD_RESULT
