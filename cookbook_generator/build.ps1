# build.ps1

# This script builds the project for Windows, Linux, and macOS.
# It uses cargo to build for each target and places the executables
# in a 'dist' directory.

# Ensure the 'dist' directory exists and is clean.
if (Test-Path -Path "dist") {
    Remove-Item -Recurse -Force "dist"
}
New-Item -ItemType Directory -Path "dist"
New-Item -ItemType Directory -Path "dist/windows"
New-Item -ItemType Directory -Path "dist/linux"
New-Item -ItemType Directory -Path "dist/macos"

# Build for Windows (native)
echo "Building for Windows..."
cargo build --release
Copy-Item -Path "target/release/cookbook_generator.exe" -Destination "dist/windows/"

# Build for Linux
echo "Building for Linux..."
cargo build --release --target x86_64-unknown-linux-gnu
Copy-Item -Path "target/x86_64-unknown-linux-gnu/release/cookbook_generator" -Destination "dist/linux/"

# Build for macOS
echo "Building for macOS..."
cargo build --release --target x86_64-apple-darwin
Copy-Item -Path "target/x86_64-apple-darwin/release/cookbook_generator" -Destination "dist/macos/"

echo "Build complete. Binaries are in the 'dist' directory."
