# We are in source directory

#######
## 1 ##
#######

#BRANCH_NAME="$(git branch --show-current)-ci-testspm"
BRANCH_NAME=ci/testspm
SAMPLE_APP_TEMP_DIR="NativeAuthSampleAppTemp"
current_date=$(date +"%Y-%m-%d")

git checkout -b "$BRANCH_NAME"

echo "=== Begin xcframework operations ==="

rm -rf archive framework MSAL.zip 

xcodebuild -sdk iphonesimulator -configuration Release -workspace MSAL.xcworkspace -scheme "MSAL (iOS Framework)" archive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES -archivePath archive/iOSSimulator CODE_SIGNING_ALLOWED=NO

XCBUILD_STATUS_SIM=$?

if [ $XCBUILD_STATUS_SIM -ne 0 ]; then
  echo "** BUILD FAILED **"
  exit 1
fi

xcodebuild -sdk iphoneos -configuration Release -workspace MSAL.xcworkspace -scheme "MSAL (iOS Framework)" archive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES -archivePath archive/iOS CODE_SIGNING_ALLOWED=NO

XCBUILD_STATUS_IPHONE=$?

if [ $XCBUILD_STATUS_IPHONE -ne 0 ]; then
  echo "** BUILD FAILED **"
  exit 1
fi

xcodebuild -sdk macosx -configuration Release -workspace MSAL.xcworkspace -scheme "MSAL (Mac Framework)" archive SKIP_INSTALL=NO BUILD_LIBRARY_FOR_DISTRIBUTION=YES -archivePath archive/macOS CODE_SIGNING_ALLOWED=NO

XCBUILD_STATUS_MAC=$?

if [ $XCBUILD_STATUS_MAC -ne 0 ]; then
  echo "** BUILD FAILED **"
  exit 1
fi

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

git commit -m "Publish temporary Swift Package $current_date"
git push -f origin "$BRANCH_NAME"

#######
## 2 ##
#######

echo "=== Cloning Sample App in a new directory ==="
mkdir -p "$SAMPLE_APP_TEMP_DIR"
cd "$SAMPLE_APP_TEMP_DIR"

git clone https://github.com/Azure-Samples/ms-identity-ciam-native-auth-ios-sample.git
cd ms-identity-ciam-native-auth-ios-sample
git switch ci/test-with-conflicts # remove
git switch ci/testspm # fixed branch in SampleApp's repo
#git merge main
git merge ci/test-with-conflicts

MEGE_STATUS=$(git ls-files -u | grep -q '^')

if git ls-files -u | grep -q '^'; then
  	echo "[Sample App] Merge main into ci/testspm failed due to conflicts"
else
	echo "all good"
fi

echo "Reset Sample App's Package cache"

rm -f NativeAuthSampleApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# DJB: select-Xcode version
# DJB: If it doesnt work, remove the derived data from Xcode here
xcodebuild -resolvePackageDependencies
xcodebuild -scheme NativeAuthSampleApp -configuration Release -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 14,OS=latest' clean build

BUILD_STATUS=$?

#######
## 3 ##
#######

echo "Cleaning up"

cd ../..

rm -rf "SAMPLE_APP_TEMP_DIR" archive framework MSAL.zip

git checkout -- .
git fetch
git switch main

git branch -D "$BRANCH_NAME"
git push origin --delete "$BRANCH_NAME"

if [ $MERGE_STATUS -ne 0 ] || [ $BUILD_STATUS -ne 0 ]; then
	exit 1
fi