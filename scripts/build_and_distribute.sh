#!/bin/bash
set -e

echo "🚀 Starting Build and Distribution Process..."
echo ""

# ============================================================================
# Step 1: Load Firebase Configuration from .env
# ============================================================================
echo "📋 Step 1: Loading Firebase configuration from scripts/.env..."

ENV_FILE="./scripts/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Error: scripts/.env file not found!"
    echo ""
    echo "Create scripts/.env file with the following content:"
    echo "export FIREBASE_API_KEY=\"your-api-key\""
    echo "export FIREBASE_GCM_SENDER_ID=\"your-sender-id\""
    echo "export FIREBASE_APP_ID=\"your-app-id\""
    exit 1
fi

# Source the .env file to load environment variables
source "$ENV_FILE"

# Verify environment variables are set
if [ -z "$FIREBASE_API_KEY" ] || [ -z "$FIREBASE_GCM_SENDER_ID" ] || [ -z "$FIREBASE_APP_ID" ]; then
    echo "❌ Error: Required Firebase environment variables not set in scripts/.env"
    echo "Required variables:"
    echo "  - FIREBASE_API_KEY"
    echo "  - FIREBASE_GCM_SENDER_ID"
    echo "  - FIREBASE_APP_ID"
    exit 1
fi

echo "✅ Firebase configuration loaded successfully"
echo ""

# ============================================================================
# Step 2: Generate GoogleService-Info.plist
# ============================================================================
echo "🔧 Step 2: Generating GoogleService-Info.plist..."

PLIST_PATH="./EVChargingTracker/GoogleService-Info.plist"

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

if [ -f "$PLIST_PATH" ]; then
    echo "✅ GoogleService-Info.plist generated successfully"
else
    echo "❌ Failed to generate GoogleService-Info.plist"
    exit 1
fi
echo ""

# ============================================================================
# Step 3: Build Locally to Verify
# ============================================================================
echo "📦 Step 3: Building app locally to verify configuration..."

SCHEME="EVChargingTracker"
ARCHIVE_PATH="./build/${SCHEME}.xcarchive"

# Clean build directory
rm -rf ./build

# Build archive
xcodebuild archive \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -destination 'generic/platform=iOS' \
  | xcbeautify || xcodebuild archive \
    -scheme "$SCHEME" \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -destination 'generic/platform=iOS'

if [ -d "$ARCHIVE_PATH" ]; then
    echo "✅ Local build successful! Archive created at: $ARCHIVE_PATH"
else
    echo "❌ Build failed. Please check the errors above."
    exit 1
fi
echo ""

# ============================================================================
# Step 4: Trigger Xcode Cloud Distribution
# ============================================================================
echo "☁️  Step 4: Preparing to trigger Xcode Cloud distribution..."
echo ""
echo "⚠️  Important: Xcode Cloud builds are triggered by git push."
echo ""
echo "Current git status:"
git status --short
echo ""

read -p "Do you want to commit and push to trigger Xcode Cloud? (y/n) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Get current branch
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

    echo "📝 Committing changes..."

    # Check if there are changes to commit
    if [[ -n $(git status --porcelain) ]]; then
        git add .
        git commit -m "chore: prepare build for distribution

- Generated GoogleService-Info.plist
- Verified local build successful
- Ready for Xcode Cloud distribution"

        echo "✅ Changes committed"
        echo ""
    else
        echo "ℹ️  No changes to commit"
        echo ""
    fi

    echo "🚀 Pushing to $CURRENT_BRANCH..."
    git push origin "$CURRENT_BRANCH"

    echo ""
    echo "✅ Push successful!"
    echo ""
    echo "🎉 Xcode Cloud will now:"
    echo "  1. Clone the repository"
    echo "  2. Run ci_scripts/ci_post_clone.sh to generate GoogleService-Info.plist"
    echo "  3. Build and archive the app"
    echo "  4. Distribute to TestFlight (if configured)"
    echo ""
    echo "📊 Monitor progress:"
    echo "  - Xcode: Window → Organizer → Xcode Cloud"
    echo "  - App Store Connect: https://appstoreconnect.apple.com"

else
    echo ""
    echo "❌ Distribution cancelled. To trigger Xcode Cloud manually:"
    echo "  1. Commit your changes: git add . && git commit -m 'your message'"
    echo "  2. Push to remote: git push"
    echo "  3. Or manually trigger in App Store Connect"
fi

echo ""
echo "✅ Build and distribution process complete!"
