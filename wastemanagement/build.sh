#!/bin/bash
set -e

echo "Installing Flutter..."
# Download and install Flutter
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz
tar xf flutter_linux_3.24.5-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"

echo "Installing dependencies..."
flutter pub get

echo "Building Flutter web app..."
flutter build web --release

echo "Build completed!" 