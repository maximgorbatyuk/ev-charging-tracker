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
