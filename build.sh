#!/bin/sh

xcodebuild archive -scheme "WhoopDI" \
 -destination "generic/platform=iOS Simulator" \
 -archivePath "archives/WhoopDI.xcarchive" \
 -target "WhoopDI" \
 BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
 SKIP_INSTALL=NO
# xcodebuild -create-xcframework -archive "archives/WhoopDI.xcarchive" -framework "WhoopDI.framework" -output "xcframeworks/MyFramework.xcframework"