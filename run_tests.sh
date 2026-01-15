#!/bin/bash
set -e

echo "🧹 Cleaning build folder..."

# Remove local build folder if it exists
if [ -d "./build" ]; then
  rm -rf ./build
  echo "✅ Removed ./build folder"
fi

# Clean xcodebuild artifacts
xcodebuild clean \
  -scheme EVChargingTracker

echo "✅ Build artifacts cleaned"
echo ""
echo "🧪 Running tests..."

xcodebuild test \
  -scheme EVChargingTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max,OS=26.2' \
  -enableCodeCoverage YES \
  -resultBundlePath ./build/TestResults.xcresult

echo "✅ Tests completed successfully!"
echo "📊 Code coverage report available in ./build/TestResults.xcresult"
