#!/bin/bash

# Script to analyze code for issues
# Usage: ./scripts/analyze.sh

set -e

echo "🔍 Analyzing code..."
flutter analyze

echo "✅ Analysis complete!"
