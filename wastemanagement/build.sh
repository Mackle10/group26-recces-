#!/bin/bash
set -e

echo "Starting Flutter web build process..."

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file..."
    echo "GOOGLEMAPS_KEY=${GOOGLEMAPS_KEY:-your_google_maps_api_key_here}" > .env
fi

# Check if Flutter is already installed
if ! command -v flutter &> /dev/null; then
    echo "Installing Flutter..."
    # Download Flutter
    curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
    tar xf flutter_linux_3.24.5-stable.tar.xz
    export PATH="$PATH:`pwd`/flutter/bin"
else
    echo "Flutter is already installed"
fi

# Add Flutter to PATH
export PATH="$PATH:`pwd`/flutter/bin"

echo "Flutter version:"
flutter --version

echo "Installing Flutter dependencies..."
flutter pub get

echo "Building Flutter web app..."
flutter build web --release --web-renderer html

echo "Build completed successfully!"
echo "Build output directory: $(pwd)/build/web"
ls -la build/web/ 