# Apple build and release workflow

The `Apple build verification` workflow runs on pushes to `main`, pull requests, and manual dispatch. It uses the runner's latest stable Xcode and prints the exact Xcode, Apple SDK, and Flutter versions used by each run. The normal workflow path analyzes the Flutter project, runs tests, and builds simulator and unsigned iOS release outputs. Those unsigned build files are uploaded as a GitHub Actions artifact.

## Signed App Store Connect build

The signed path runs only from **Actions → Apple build verification → Run workflow** when `build_signed` is selected. It creates an App Store Connect IPA artifact; it does not upload to Apple unless `upload_to_testflight` is also explicitly selected. Both inputs are off by default. The signed job runs only after the normal verification job succeeds.

Configure these repository settings before dispatching the signed build:

| Setting | Kind | Value |
| --- | --- | --- |
| `APPLE_BUNDLE_ID` | Repository variable | Registered App Store bundle ID for this app |
| `PAYMENT_API_URL` | Repository variable | Production HTTPS origin for the purchase verification API |
| `APPLE_UNLOCK_PRODUCT_ID` | Repository variable | Product identifier configured in App Store Connect |
| `APPLE_TEAM_ID` | Actions secret | Apple Developer Team ID |
| `APPLE_CERTIFICATE_BASE64` | Actions secret | Base64 encoded Apple Distribution `.p12` containing its private key |
| `APPLE_CERTIFICATE_PASSWORD` | Actions secret | Password used to export that `.p12` |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Actions secret | Base64 encoded App Store provisioning profile for this exact bundle ID and team, containing the distribution certificate |

For explicit TestFlight upload, also configure `ASC_API_KEY_ID`, `ASC_API_ISSUER_ID`, and `ASC_API_PRIVATE_KEY` as Actions secrets. The private key secret should contain the `.p8` text including its PEM header and footer. Select both dispatch inputs to upload. App Store Connect must already contain the app record and the API key must have permission to upload builds.

The workflow imports the certificate into a temporary keychain, installs the supplied profile, validates that the profile's team and application identifier match the configured values, then runs Flutter's release IPA build with the iOS signing overrides in a temporary Xcode configuration. This lets Flutter prepare CocoaPods, Swift packages, generated configuration, and native assets as part of its normal build. Each dispatch uses the workflow run number and attempt as the build number. The workflow removes its temporary keychain, profile copy, API key file, and temporary config files when the signing step exits. Do not enable shell tracing in that step or print secret values. The workflow does not check in credentials or change the project's configured bundle ID.

## Signing and configuration constraints

- The Xcode project currently defaults to `com.puphr.crossscanmoto`. The signed job overrides `PRODUCT_BUNDLE_IDENTIFIER` and `DEVELOPMENT_TEAM` from repository settings. Set `APPLE_BUNDLE_ID` to the real registered identifier before signing.
- The signed job requires a production HTTPS origin and Apple product ID so release builds include the purchase configuration. An Android product ID can also be set as the optional `GOOGLE_UNLOCK_PRODUCT_ID` repository variable.
- The project and workflow use an iOS 15 deployment floor, compatible with the app's StoreKit 2 purchase implementation.
- The provisioning profile must match the configured bundle ID and team and be an App Store distribution profile that includes the certificate imported from `APPLE_CERTIFICATE_BASE64`. A profile from another app cannot be reused unless it is explicitly provisioned for this exact app ID. An Apple Distribution certificate may be reused across apps for the same team when the profile includes it. The certificate's private key must be present in the `.p12`.
- The signed job uses manually supplied signing assets. It does not create certificates, profiles, App Store app records, or entitlements. If the app adds capabilities, update the app ID and profile to include them.
- There is no automatic provisioning path in this workflow. The App Store Connect API key is used only for the explicitly requested upload; it does not replace the signing certificate or provisioning profile.
- Neither a base64 `.p12` nor a provisioning profile is committed to the repository. Keep signing values in GitHub Actions secrets and the bundle ID in repository variables.

The unsigned build path works without Apple signing credentials. A signed IPA requires the registered app ID, matching Apple team, valid distribution certificate and private key, and app-specific distribution profile described above.
