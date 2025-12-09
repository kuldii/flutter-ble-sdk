#!/bin/bash

# Script to format all Dart code in the project
# Usage: ./scripts/format.sh

set -e

echo "🎨 Formatting Dart code..."
dart format lib/ test/ example/lib/

echo "✅ Code formatting complete!"
