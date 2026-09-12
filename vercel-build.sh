#!/bin/bash
set -e

echo "=================================================="
echo "      Melo - Vercel Flutter Web Build Script      "
echo "=================================================="

# Check if Flutter is already installed in environment
if ! command -v flutter &> /dev/null; then
  echo "Flutter not found in PATH. Checking local directory..."
  if [ ! -d "flutter" ]; then
    echo "Cloning Flutter SDK (stable branch)..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 flutter
  fi
  export PATH="$PATH:$(pwd)/flutter/bin"
fi

echo "Flutter version:"
flutter --version

echo "Enabling Flutter Web support..."
flutter config --enable-web --no-analytics

echo "Resolving dependencies..."
flutter pub get

echo "Compiling Flutter Web release build..."
flutter build web --release

echo "=================================================="
echo " Build Succeeded! Output directory: build/web     "
echo "=================================================="
