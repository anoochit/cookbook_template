#!/bin/bash

# This script builds the project for Windows, Linux, and macOS.
# It uses cargo to build for each target and places the executables
# in a 'dist' directory.

# Ensure the 'dist' directory exists and is clean.
if [ -d "dist" ]; then
    rm -rf "dist"
fi
mkdir -p "dist/windows"
mkdir -p "dist/linux"
mkdir -p "dist/macos"

# Build for Linux (native, if on Linux) or cross-compile
echo "Building for Linux..."
cargo build --release --target x86_64-unknown-linux-gnu
cp "target/x86_64-unknown-linux-gnu/release/cookbook_generator" "dist/linux/"

# Build for macOS (native, if on macOS) or cross-compile
echo "Building for macOS..."
cargo build --release --target x86_64-apple-darwin
cp "target/x86_64-apple-darwin/release/cookbook_generator" "dist/macos/"

# Build for Windows
echo "Building for Windows..."
cargo build --release --target x86_64-pc-windows-gnu
cp "target/x86_64-pc-windows-gnu/release/cookbook_generator.exe" "dist/windows/"


echo "Build complete. Binaries are in the 'dist' directory."
