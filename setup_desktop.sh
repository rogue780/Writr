#!/bin/bash

# Script to enable and set up desktop platforms for Flutter

echo "Setting up desktop platforms for Writr..."

# Enable desktop platforms
echo "Enabling Windows desktop..."
flutter config --enable-windows-desktop

echo "Enabling macOS desktop..."
flutter config --enable-macos-desktop

echo "Enabling Linux desktop..."
flutter config --enable-linux-desktop

# Create platform-specific files
echo "Creating platform directories..."
flutter create --project-name=writr --platforms=windows,macos,linux .

echo ""
echo "Desktop setup complete!"
echo ""
echo "You can now build for desktop:"
echo "  flutter build windows"
echo "  flutter build macos"
echo "  flutter build linux"
