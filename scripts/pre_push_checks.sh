#!/bin/bash
set -e

echo "🚦 Running pre-push checks..."
echo ""

# Lint (strict mode)
./scripts/run_lint.sh
echo ""

# Run tests
./scripts/run_tests.sh
echo ""

echo "✅ Pre-push checks passed! Safe to push."
