#!/bin/bash

# Script to generate test coverage report for KGiTON BLE SDK
# Usage: ./scripts/generate_coverage.sh

set -e

echo "🧹 Cleaning previous coverage data..."
rm -rf coverage/

echo "🧪 Running tests with coverage..."
flutter test --coverage

echo "📊 Generating HTML coverage report..."
genhtml coverage/lcov.info -o coverage/html

echo "✅ Coverage report generated!"
echo "📂 Open coverage/html/index.html to view the report"
echo ""
echo "Coverage Summary:"
lcov --summary coverage/lcov.info
