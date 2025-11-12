#!/bin/bash
# DMG Build Script for OyVey
echo "Building OyVey.app..."
xcodebuild -project OyVey.xcodeproj -scheme OyVey -configuration Release clean build

echo "Creating DMG..."
# TODO: Add create-dmg commands here
