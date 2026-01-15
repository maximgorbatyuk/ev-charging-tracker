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
