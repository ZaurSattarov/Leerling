#!/bin/zsh
set -euo pipefail

project_root="${0:A:h:h}"
expected_bundle_id="com.klantio.leerling"
expected_team_id="LLTU5D46PX"
expected_profile_name="Klantio Leerling App Store"
expected_profile_uuid="1d4be69f-1900-4993-b6b7-996ea4fe0c1a"
expected_certificate_sha1="E3A263C099442F2772850D61AE63F74F14C615FA"
profile_path="${PROFILE_PATH:-$HOME/Library/MobileDevice/Provisioning Profiles/$expected_profile_uuid.mobileprovision}"
temporary_directory="$(mktemp -d /tmp/klantio-ios-preflight.XXXXXX)"
trap 'rm -rf "$temporary_directory"' EXIT

fail() {
  print -u2 -- "PRECHECK FAILED: $1"
  exit 1
}

read_plist_value() {
  /usr/libexec/PlistBuddy -c "Print :$2" "$1" 2>/dev/null
}

[[ -f "$profile_path" ]] || fail "Provisioning profile ontbreekt: $profile_path"

firebase_bundle_id="$(read_plist_value "$project_root/ios/Runner/GoogleService-Info.plist" BUNDLE_ID)"
[[ "$firebase_bundle_id" == "$expected_bundle_id" ]] || fail "Firebase BUNDLE_ID is $firebase_bundle_id, verwacht $expected_bundle_id"

profile_plist="$temporary_directory/profile.plist"
security cms -D -i "$profile_path" > "$profile_plist"
profile_name="$(read_plist_value "$profile_plist" Name)"
profile_uuid="$(read_plist_value "$profile_plist" UUID)"
profile_team_id="$(read_plist_value "$profile_plist" TeamIdentifier:0)"
profile_application_identifier="$(read_plist_value "$profile_plist" Entitlements:application-identifier)"

[[ "$profile_name" == "$expected_profile_name" ]] || fail "Profile naam is $profile_name"
[[ "$profile_uuid" == "$expected_profile_uuid" ]] || fail "Profile UUID is $profile_uuid"
[[ "$profile_team_id" == "$expected_team_id" ]] || fail "Profile Team ID is $profile_team_id"
[[ "$profile_application_identifier" == "$expected_team_id.$expected_bundle_id" ]] || fail "Profile application-identifier is $profile_application_identifier"

profile_certificate_b64="$temporary_directory/profile-certificate.b64"
profile_certificate_der="$temporary_directory/profile-certificate.der"
plutil -extract 'DeveloperCertificates.0' raw -o "$profile_certificate_b64" "$profile_plist"
base64 -D -i "$profile_certificate_b64" -o "$profile_certificate_der"
profile_certificate_sha1="$(openssl x509 -inform DER -in "$profile_certificate_der" -noout -fingerprint -sha1 | cut -d= -f2 | tr -d ':')"
[[ "$profile_certificate_sha1" == "$expected_certificate_sha1" ]] || fail "Profile certificate SHA-1 is $profile_certificate_sha1"

security find-identity -v -p codesigning | grep -Fq "$expected_certificate_sha1" || fail "Lokale Distribution identity/private key ontbreekt voor $expected_certificate_sha1"

build_settings="$temporary_directory/release-build-settings.txt"
(cd "$project_root" && xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release -showBuildSettings -destination 'generic/platform=iOS') > "$build_settings"
grep -Eq "^[[:space:]]*PRODUCT_BUNDLE_IDENTIFIER = $expected_bundle_id$" "$build_settings" || fail "Release Bundle ID wijkt af"
grep -Eq "^[[:space:]]*DEVELOPMENT_TEAM = $expected_team_id$" "$build_settings" || fail "Release Team ID wijkt af"
grep -Eq "^[[:space:]]*PROVISIONING_PROFILE_SPECIFIER = $expected_profile_name$" "$build_settings" || fail "Release provisioning profile wijkt af"
grep -Eq "^[[:space:]]*CODE_SIGN_IDENTITY = $expected_certificate_sha1$" "$build_settings" || fail "Release signing certificate wijkt af"

version_line="$(grep '^version:' "$project_root/pubspec.yaml")"
print -- "PRECHECK PASSED"
print -- "Bundle ID: $expected_bundle_id"
print -- "Team ID: $expected_team_id"
print -- "Profile: $profile_name ($profile_uuid)"
print -- "Certificate SHA-1: $profile_certificate_sha1"
print -- "Firebase BUNDLE_ID: $firebase_bundle_id"
print -- "$version_line"
