# Scripts

Date: 2026-01-11

This document outlines the automation scripts for the EV Charging Tracker iOS app development workflow.

## Overview

Scripts are located in the `scripts/` directory and help automate common development tasks such as testing, linting, formatting, and building.

## ⚠️ Important: Firebase Configuration Required

**The app uses Firebase Analytics and requires `GoogleService-Info.plist` to build.**

This file is **gitignored** for security and must be generated or downloaded before building:

### Quick Setup (Choose One):

**Option 1: Use Build & Distribute Script** (Recommended)
```bash
# Create scripts/.env with Firebase credentials (one-time setup)
cat > scripts/.env << 'EOF'
export FIREBASE_API_KEY="your-api-key"
export FIREBASE_GCM_SENDER_ID="your-sender-id"
export FIREBASE_APP_ID="1:123456789:ios:abc123"
EOF

# Run the complete build and distribution workflow
./scripts/build_and_distribute.sh
```

**Option 2: Download from Firebase Console** (For local development only)
- Download from: https://console.firebase.google.com → `ev-charge-tracker-851bf` → Project Settings → iOS app
- Place at: `EVChargingTracker/GoogleService-Info.plist`
- Build in Xcode normally

**For CI/CD:**
- **Xcode Cloud:** Set environment variables in App Store Connect (handled by `ci_scripts/ci_post_clone.sh`)
- **GitHub Actions:** Set secrets in repository settings (see CI/CD Configuration section)

---

## 1. Testing Scripts

### Run Tests
**Script:** `scripts/run_tests.sh`

**Purpose:** Run all unit and UI tests with code coverage

**Implementation:**
```bash
#!/bin/bash
set -e

echo "🧪 Running tests..."

xcodebuild test \
  -scheme EVChargingTracker \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro,OS=18.0' \
  -enableCodeCoverage YES \
  -resultBundlePath ./build/TestResults.xcresult

echo "✅ Tests completed successfully!"
echo "📊 Code coverage report available in ./build/TestResults.xcresult"
```

**Usage:**
```bash
chmod +x scripts/run_tests.sh
./scripts/run_tests.sh
```

**Requirements:**
- Xcode installed
- iPhone 15 Pro simulator installed (or modify destination)

---

## 2. Code Quality Scripts

### Run Lint
**Script:** `scripts/run_lint.sh`

**Purpose:** Run SwiftLint to check code style and quality

**Implementation:**
```bash
#!/bin/bash
set -e

echo "🔍 Running SwiftLint..."

if ! which swiftlint >/dev/null; then
  echo "❌ Error: SwiftLint not installed"
  echo "Install with: brew install swiftlint"
  exit 1
fi

swiftlint lint --strict

echo "✅ Linting completed successfully!"
```

**Usage:**
```bash
chmod +x scripts/run_lint.sh
./scripts/run_lint.sh
```

**Requirements:**
- Install SwiftLint: `brew install swiftlint`
- Create `.swiftlint.yml` configuration file in project root

---

### Run Formatting
**Script:** `scripts/run_format.sh`

**Purpose:** Auto-format Swift code using SwiftFormat

**Implementation:**
```bash
#!/bin/bash
set -e

echo "🎨 Running SwiftFormat..."

if ! which swiftformat >/dev/null; then
  echo "❌ Error: SwiftFormat not installed"
  echo "Install with: brew install swiftformat"
  exit 1
fi

swiftformat . --config .swiftformat

echo "✅ Formatting completed successfully!"
```

**Usage:**
```bash
chmod +x scripts/run_format.sh
./scripts/run_format.sh
```

**Requirements:**
- Install SwiftFormat: `brew install swiftformat`
- Create `.swiftformat` configuration file in project root

---

### Detect Unused Code
**Script:** `scripts/detect_unused_code.sh`

**Purpose:** Find unused code (classes, functions, properties) using Periphery

**Implementation:**
```bash
#!/bin/bash
set -e

echo "🔎 Detecting unused code..."

if ! which periphery >/dev/null; then
  echo "❌ Error: Periphery not installed"
  echo "Install with: brew install peripheryapp/periphery/periphery"
  exit 1
fi

periphery scan \
  --schemes EVChargingTracker \
  --targets EVChargingTracker \
  --format xcode

echo "✅ Unused code detection completed!"
```

**Usage:**
```bash
chmod +x scripts/detect_unused_code.sh
./scripts/detect_unused_code.sh
```

**Requirements:**
- Install Periphery: `brew install peripheryapp/periphery/periphery`
- First run: `periphery scan --setup`

---

## 3. Build & Distribute Script

### Build and Distribute to Xcode Cloud
**Script:** `scripts/build_and_distribute.sh`

**Purpose:** Complete build and distribution workflow:
1. Generate GoogleService-Info.plist from secrets in `scripts/.env`
2. Build the app locally to verify everything works
3. Commit and push to trigger Xcode Cloud distribution

**Implementation:**
```bash
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
```

**Usage:**
```bash
# Make script executable
chmod +x scripts/build_and_distribute.sh

# Run the script
./scripts/build_and_distribute.sh
```

**Prerequisites:**
1. **Create `scripts/.env` file** with Firebase credentials:
   ```bash
   # scripts/.env
   export FIREBASE_API_KEY="AIza..."
   export FIREBASE_GCM_SENDER_ID="123456789"
   export FIREBASE_APP_ID="1:123456789:ios:abc123"
   ```

2. **Ensure `scripts/.env` is in `.gitignore`**:
   ```bash
   echo "scripts/.env" >> .gitignore
   ```

3. **Configure Xcode Cloud**:
   - Open Xcode → Product → Xcode Cloud → Create Workflow
   - Set environment variables in App Store Connect
   - Configure to trigger on pushes to `main` or `develop`

4. **Valid code signing** configured in Xcode project

**What the Script Does:**
1. ✅ Loads Firebase secrets from `scripts/.env`
2. ✅ Generates `GoogleService-Info.plist` in `EVChargingTracker/`
3. ✅ Builds app locally to verify configuration is correct
4. ✅ Prompts to commit and push changes
5. ✅ Push triggers Xcode Cloud workflow automatically
6. ✅ Xcode Cloud builds and distributes to TestFlight

**Notes:**
- GoogleService-Info.plist is gitignored for security
- Xcode Cloud will regenerate it using `ci_scripts/ci_post_clone.sh`
- Local build verifies everything works before triggering CI/CD
- Optional: Install `xcbeautify` for prettier build output: `brew install xcbeautify`

---

## 4. Combination Scripts

### Run All Quality Checks
**Script:** `scripts/run_all_checks.sh`

**Purpose:** Run format, lint, and tests in sequence

**Implementation:**
```bash
#!/bin/bash
set -e

echo "🔄 Running all quality checks..."
echo ""

# Format code
./scripts/run_format.sh
echo ""

# Lint code
./scripts/run_lint.sh
echo ""

# Run tests
./scripts/run_tests.sh
echo ""

echo "✅ All quality checks passed!"
```

**Usage:**
```bash
chmod +x scripts/run_all_checks.sh
./scripts/run_all_checks.sh
```

---

## 5. CI/CD Configuration

### Xcode Cloud
**Note:** Xcode Cloud cannot be triggered via local scripts. Configure in Xcode:

1. Open Xcode
2. Go to Product → Xcode Cloud → Create Workflow
3. Configure:
   - Trigger: On push to `main` and `develop` branches
   - Actions: Build, Test, Archive
   - TestFlight: Auto-publish on success
4. **Environment Variables:** Add Firebase secrets in App Store Connect:
   - Go to App Store Connect → Your App → Xcode Cloud
   - Add Environment Variables:
     - `FIREBASE_API_KEY` (secret)
     - `FIREBASE_GCM_SENDER_ID` (secret)
     - `FIREBASE_APP_ID` (secret)
5. The `ci_scripts/ci_post_clone.sh` script will automatically generate `GoogleService-Info.plist` from these variables

**Documentation:** https://developer.apple.com/xcode-cloud/

---

### GitHub Actions (Alternative to Xcode Cloud)
**File:** `.github/workflows/ios.yml`

**Purpose:** Run tests and lint on every PR

```yaml
name: iOS CI

on:
  pull_request:
    branches: [ main, develop ]
  push:
    branches: [ main, develop ]

jobs:
  test:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4

      - name: Generate Firebase Config
        env:
          FIREBASE_API_KEY: ${{ secrets.FIREBASE_API_KEY }}
          FIREBASE_GCM_SENDER_ID: ${{ secrets.FIREBASE_GCM_SENDER_ID }}
          FIREBASE_APP_ID: ${{ secrets.FIREBASE_APP_ID }}
        run: |
          chmod +x scripts/generate_firebase_config.sh
          ./scripts/generate_firebase_config.sh

      - name: Install SwiftLint
        run: brew install swiftlint

      - name: Run SwiftLint
        run: swiftlint lint --strict

      - name: Run Tests
        run: |
          xcodebuild test \
            -scheme EVChargingTracker \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            -enableCodeCoverage YES
```

**Setup GitHub Secrets:**
1. Go to GitHub repository → Settings → Secrets and variables → Actions
2. Add repository secrets:
   - `FIREBASE_API_KEY`
   - `FIREBASE_GCM_SENDER_ID`
   - `FIREBASE_APP_ID`

---

### CodeRabbit Integration
**Note:** CodeRabbit is a cloud service, not a local script.

**Setup:**
1. Go to https://coderabbit.ai
2. Install CodeRabbit GitHub App to your repository
3. CodeRabbit will automatically review all pull requests
4. No local script needed

---

## Installation Checklist

### Required Tools
- [ ] Xcode 15+ installed
- [ ] SwiftLint: `brew install swiftlint`
- [ ] SwiftFormat: `brew install swiftformat`

### Optional Tools
- [ ] Periphery: `brew install peripheryapp/periphery/periphery`
- [ ] xcbeautify (for prettier xcodebuild output): `brew install xcbeautify`

### Configuration Files Needed
- [ ] `.swiftlint.yml` - SwiftLint configuration
- [ ] `.swiftformat` - SwiftFormat configuration
- [ ] `ExportOptions.plist` - IPA export settings (for App Store distribution)
- [ ] `scripts/.env` - Environment variables for Firebase (gitignored)

### Firebase Configuration Setup

**Option 1: Environment Variables (.env file - Recommended)**
```bash
# Create scripts/.env file (this file is gitignored)
cat > scripts/.env << 'EOF'
# Firebase Configuration
# Get these values from Firebase Console > Project Settings > Your iOS app
export FIREBASE_API_KEY="AIza..."
export FIREBASE_GCM_SENDER_ID="123456789"
export FIREBASE_APP_ID="1:123456789:ios:abc123"
EOF

# Add to .gitignore if not already there
echo "scripts/.env" >> .gitignore

# Load environment variables before building
source scripts/.env
```

**Option 2: Download from Firebase Console**
```bash
# 1. Go to Firebase Console (https://console.firebase.google.com)
# 2. Select your project: ev-charge-tracker-851bf
# 3. Go to Project Settings > Your apps > iOS app
# 4. Download GoogleService-Info.plist
# 5. Place it at: EVChargingTracker/GoogleService-Info.plist
```

**Option 3: Add to Shell Profile (for permanent setup)**
```bash
# Add to ~/.zshrc or ~/.bashrc
echo 'export FIREBASE_API_KEY="AIza..."' >> ~/.zshrc
echo 'export FIREBASE_GCM_SENDER_ID="123456789"' >> ~/.zshrc
echo 'export FIREBASE_APP_ID="1:123456789:ios:abc123"' >> ~/.zshrc

# Reload shell
source ~/.zshrc
```

### Make Scripts Executable
```bash
chmod +x scripts/*.sh
```

---

## Usage Examples

### Daily Development
```bash
# Before starting work
./scripts/run_format.sh

# During development
./scripts/run_lint.sh

# Before committing
./scripts/run_tests.sh
```

### Before Creating PR
```bash
./scripts/run_all_checks.sh
```

### Build and Distribute Process
```bash
# Complete build and distribution workflow (generates config, builds, pushes to Xcode Cloud)
./scripts/build_and_distribute.sh

# The script will:
# 1. Load Firebase secrets from scripts/.env
# 2. Generate GoogleService-Info.plist
# 3. Build locally to verify
# 4. Prompt to commit and push (triggers Xcode Cloud)
```

---

## Troubleshooting

### "xcodebuild: command not found"
- Install Xcode from App Store
- Run: `xcode-select --install`

### "SwiftLint not found"
- Run: `brew install swiftlint`

### "No such scheme"
- Verify scheme name in Xcode: Product → Scheme → Manage Schemes

### Code signing errors
- Verify certificates in Xcode: Signing & Capabilities
- Ensure provisioning profiles are up to date

### "GoogleService-Info.plist not found" or build fails with Firebase errors
**Problem:** The app requires Firebase Analytics configuration file.

**Solutions:**
1. **Generate from environment variables:**
   ```bash
   # Set environment variables
   export FIREBASE_API_KEY="your-api-key"
   export FIREBASE_GCM_SENDER_ID="your-sender-id"
   export FIREBASE_APP_ID="your-app-id"

   # Generate the file
   ./scripts/generate_firebase_config.sh
   ```

2. **Download from Firebase Console:**
   - Visit https://console.firebase.google.com
   - Select project: `ev-charge-tracker-851bf`
   - Project Settings > Your apps > iOS app
   - Download `GoogleService-Info.plist`
   - Place at: `EVChargingTracker/GoogleService-Info.plist`

3. **Use .env file (recommended for team):**
   ```bash
   # Create scripts/.env with Firebase credentials
   source scripts/.env
   ./scripts/generate_firebase_config.sh
   ```

### "Required Firebase environment variables not set"
**Problem:** Environment variables are missing when running `generate_firebase_config.sh`

**Solution:**
```bash
# Check current environment
echo $FIREBASE_API_KEY
echo $FIREBASE_GCM_SENDER_ID
echo $FIREBASE_APP_ID

# If empty, set them:
export FIREBASE_API_KEY="AIza..."
export FIREBASE_GCM_SENDER_ID="123456789"
export FIREBASE_APP_ID="1:123456789:ios:abc123"

# Or source your .env file:
source scripts/.env
```

### Build succeeds but app crashes on launch with Firebase error
**Problem:** GoogleService-Info.plist has incorrect values or is missing from build.

**Solution:**
1. Verify the file exists: `ls -la EVChargingTracker/GoogleService-Info.plist`
2. Check file contents: `cat EVChargingTracker/GoogleService-Info.plist`
3. Ensure file is included in Xcode target:
   - Open Xcode
   - Select `GoogleService-Info.plist` in Project Navigator
   - Check "Target Membership" in File Inspector (right panel)
   - Ensure `EVChargingTracker` target is checked
4. Clean build: Xcode → Product → Clean Build Folder (⌘+Shift+K)
5. Rebuild: `./scripts/build_and_distribute.sh`

---

## Future Enhancements

- [ ] Add script to generate localized screenshots
- [ ] Add script to bump version number
- [ ] Add script to generate changelog
- [ ] Add script to validate Localizable.xcstrings completeness
- [ ] Integrate with Fastlane for advanced automation
- [ ] Add performance testing script
