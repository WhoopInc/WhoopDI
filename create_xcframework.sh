xcodebuild archive -project WhoopDIKit/WhoopDIKit.xcodeproj -scheme WhoopDIKit -destination "generic/platform=iOS" -archivePath "archives/WhoopDIKit-ios.xcarchive"
xcodebuild archive -project WhoopDIKit/WhoopDIKit.xcodeproj -scheme WhoopDIKit -destination "generic/platform=iOS Simulator" -archivePath "archives/WhoopDIKit-iosSimulator.xcarchive"

xcodebuild -create-xcframework -archive archives/WhoopDIKit-ios.xcarchive -framework WhoopDIKit.framework -archive archives/WhoopDIKit-iosSimulator.xcarchive -framework WhoopDIKit.framework -output WhoopDIKit.xcframework

zip -r WhoopDIKit.zip WhoopDIKit.xcframework
shasum -a 256 WhoopDIKit.zip | awk '{print $1}' > WhoopDIKit.sha256
