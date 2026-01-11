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
