#!/bin/bash

# Script to clean the project
# Usage: ./scripts/clean.sh

set -e

echo "🧹 Cleaning project..."
flutter clean

echo "🧹 Cleaning example project..."
cd example && flutter clean && cd ..

echo "🧹 Removing coverage data..."
rm -rf coverage/

echo "✅ Project cleaned!"
