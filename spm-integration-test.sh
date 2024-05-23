# We are in source directory

BRANCH_NAME="ci/testspm"
SAMPLE_APP_TEMP_DIR="NativeAuthSampleAppTemp"
current_date=$(date +"%Y-%m-%d")

git checkout -b "$BRANCH_NAME"

echo "=== Begin xcframework operations ==="

rm -rf archive framework MSAL.zip 

xcodebuild -sdk iphonesimulator -configuration Release -workspace MSAL.xcworkspace -scheme "MSAL (iOS Framework)" archive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES -archivePath archive/iOSSimulator CODE_SIGNING_ALLOWED=NO
xcodebuild -sdk iphoneos -configuration Release -workspace MSAL.xcworkspace -scheme "MSAL (iOS Framework)" archive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES -archivePath archive/iOS CODE_SIGNING_ALLOWED=NO
xcodebuild -sdk macosx -configuration Release -workspace MSAL.xcworkspace -scheme "MSAL (Mac Framework)" archive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES -archivePath archive/macOS CODE_SIGNING_ALLOWED=NO
xcodebuild -create-xcframework -framework archive/iOSSimulator.xcarchive/Products/Library/Frameworks/MSAL.framework -framework archive/iOS.xcarchive/Products/Library/Frameworks/MSAL.framework -framework archive/macOS.xcarchive/Products/Library/Frameworks/MSAL.framework -output framework/MSAL.xcframework
zip -r MSAL.zip framework/MSAL.xcframework -y -v
CHECKSUM=$(swift package compute-checksum MSAL.zip)

echo "=== MSAL.zip xcframework created ==="
echo "This is the checksum: $CHECKSUM"

NEW_URL="https://github.com/AzureAD/microsoft-authentication-library-for-objc/raw/$BRANCH_NAME/MSAL.zip/"
echo "Putting this: $NEW_URL"

sed -i '' "s#url: \"[^\"]*\"#url: \"$NEW_URL\"#" Package.swift
sed -i '' "s#checksum: \"[^\"]*\"#checksum: \"$CHECKSUM\"#" Package.swift

echo "=== Finished modifying Package.swift. Result: ==="
cat Package.swift

echo "Pushing MSAL.zip and Package.swift to $BRANCH_NAME"

git add MSAL.zip Package.swift

git commit -m "Publish Swift Package $current_date"
git push -f origin "$BRANCH_NAME"

echo "=== Cloning Sample App in a new directory ==="
mkdir -p "$SAMPLE_APP_TEMP_DIR"
cd "$SAMPLE_APP_TEMP_DIR"

git clone https://github.com/Azure-Samples/ms-identity-ciam-native-auth-ios-sample.git
cd ms-identity-ciam-native-auth-ios-sample
git switch ci/testspm
git merge main

echo "Reset Sample App's Package cache"

rm -f NativeAuthSampleApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# DJB: select-Xcode version
# DJB: If it doesnt work, remove the derived data from Xcode here
xcodebuild -resolvePackageDependencies
xcodebuild -scheme NativeAuthSampleApp -configuration Release -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 14,OS=latest' clean build

BUILD_STATUS=$?

if [ $BUILD_STATUS -ne 0 ]; then
  echo "** BUILD FAILED **"
  exit 1
else
  echo "** BUILD SUCCEEDED **"
fi

echo "Cleaning up"

cd ../..

rm -rf "SAMPLE_APP_TEMP_DIR" archive framework MSAL.zip

git checkout -- .
git fetch
#git checkout -f main
git switch main
# DJB: + consider using some dynamic value in the name of the branch (for example the name of the current branch or current date)

git branch -D "$BRANCH_NAME"
git push origin --delete "$BRANCH_NAME"