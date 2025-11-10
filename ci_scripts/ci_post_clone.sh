#!/bin/sh

# ci_scripts/ci_post_clone.sh
# This script runs after Xcode Cloud clones your repository

set -e  # Exit on any error

echo "🔧 Generating GoogleService-Info.plist from environment variables..."

# Define the path where the plist should be created
# Replace "YourApp" with your actual target name
PLIST_PATH="$CI_PRIMARY_REPOSITORY_PATH/EVChargingTracker/GoogleService-Info.plist"

# Get bundle identifier from the project
BUNDLE_ID="${PRODUCT_BUNDLE_IDENTIFIER:-dev.mgorbatyuk.EvChargeTracker}"

# Create the GoogleService-Info.plist file
cat > "$PLIST_PATH" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>API_KEY</key>
    <string>$FIREBASE_API_KEY</string>
    <key>GCM_SENDER_ID</key>
    <string>$FIREBASE_GCM_SENDER_ID</string>
    <key>PLIST_VERSION</key>
    <string>1</string>
    <key>BUNDLE_ID</key>
    <string>dev.mgorbatyuk.EvChargeTracker</string>
    <key>PROJECT_ID</key>
    <string>ev-charge-tracker-851bf</string>
    <key>STORAGE_BUCKET</key>
    <string>ev-charge-tracker-851bf.firebasestorage.app</string>
    <key>IS_ADS_ENABLED</key>
	<false></false>
	<key>IS_ANALYTICS_ENABLED</key>
	<false></false>
	<key>IS_APPINVITE_ENABLED</key>
	<true></true>
	<key>IS_GCM_ENABLED</key>
	<true></true>
	<key>IS_SIGNIN_ENABLED</key>
	<true></true>
	<key>GOOGLE_APP_ID</key>
    <string>$FIREBASE_APP_ID</string>
</dict>
</plist>
EOF

# Verify the file was created
if [ -f "$PLIST_PATH" ]; then
    echo "✅ GoogleService-Info.plist generated successfully at $PLIST_PATH"
    echo "📄 File contents:"
    cat "$PLIST_PATH"
else
    echo "❌ Failed to generate GoogleService-Info.plist"
    exit 1
fi