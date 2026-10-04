# Monday Money Move — Apple release checkpoint

Updated September 25, 2026. This file records verified preparation, not an App Store submission.

## Ready in the repository
- Native SwiftUI iPhone app; bundle ID `com.mondaymoneymove.app`.
- Version `1.0.0`, build `1`; raise the build number if Apple already has build 1.
- App icon and UserDefaults privacy manifest.
- StoreKit monthly product ID `com.mondaymoneymove.monthly`.
- Eligible-trial messaging, restore purchases, and transaction updates.
- App Store description, review instructions, and subscription setup copy in `APP_STORE_METADATA.md`.
- Generated Xcode project and shared scheme included. XcodeGen is not needed to open, test, archive, or upload this project on a Mac.
- Native CI run 35811725682 passed all 4 tests on September 23: persistence, deletion, corrupt saved data, and the full weekly check-in flow.

## Finish before Apple review
- [ ] Sign in to App Store Connect and verify the existing Monday Money Move draft.
- [ ] Confirm Paid Apps Agreement, tax forms, and payout banking status in Apple. Stripe banking does not complete Apple banking.
- [ ] Create or verify the monthly StoreKit subscription and its 7-day introductory trial; attach it to the first app submission.
- [ ] Test purchase, cancellation, restore, renewal/expiration, and revoked access using Apple's sandbox on the final build. The four core CI tests do not verify purchases.
- [ ] Test Monday reminder permission and delivery on a physical iPhone.
- [ ] Inspect the exported App Store screenshots and add them to the listing.
- [ ] Verify the public support, privacy, and terms pages load and match the native app. Live reachability was not confirmed by web retrieval on September 25.
- [ ] Complete privacy, age rating, pricing/availability, export compliance, and review-contact fields from verified facts.
- [ ] Archive, sign, validate, and upload from Xcode using Monday Money Move LLC's team.
- [ ] Wait for Apple to process the upload, select that build, and submit the version and subscription for review.

## Build and screenshot evidence
CI generates an Xcode project, runs the four native tests on a 6.9-inch iPhone simulator, exports screenshot candidates, and compiles a Release device build without signing. Unsigned CI output cannot be submitted to Apple. See the latest workflow run for current results.

## Continue on the Mac
1. Open `native-ios/MondayMoneyMove.xcodeproj` from this release branch/package.
2. In Xcode > Settings > Accounts, sign in to the existing Apple Developer account.
3. Select the MondayMoneyMove app target > Signing & Capabilities, keep automatic signing, and select the Monday Money Move LLC team.
4. Select the MondayMoneyMove scheme and an iPhone destination for testing. Use Product > Test for the included tests.
5. Test the subscription and reminder checks above on the final configuration.
6. Select Any iOS Device (arm64), then Product > Archive.
7. In Organizer, choose Validate App and resolve any errors, then Distribute App > App Store Connect > Upload.
8. Return to the existing App Store Connect app record to choose the processed build and complete review submission.

No Apple signing credentials are included in the repository. A passing simulator test or an accepted developer agreement is not proof that a build has been uploaded or submitted.
