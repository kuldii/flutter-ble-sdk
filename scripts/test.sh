#!/bin/bash

# Script to run all tests
# Usage: ./scripts/test.sh

set -e

echo "🧪 Running tests..."
flutter test

echo "✅ All tests passed!"
