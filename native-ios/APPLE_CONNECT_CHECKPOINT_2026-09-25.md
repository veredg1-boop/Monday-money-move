# Apple App Store Connect checkpoint — September 25, 2026

Status: NOT SUBMITTED. Apple app ID 6815024954; bundle ID com.mondaymoneymove.app; draft iOS version 1.0.

## Completed and verified in App Store Connect
- Four genuine 1320×2868 iPhone simulator screenshots uploaded to the 6.9-inch slot, inherited by the 6.5-inch slot. Order: home, check-in, recommendation, saved move.
- Age-rating questionnaire saved; Apple calculated 4+ with regional equivalents.
- Content rights saved: native app does not contain, show, or access third-party content.
- App download price set to $0.00. Initial app availability set to United States.
- Subscription group created: Monday Money Move Membership, ID 22412310, English (U.S.) localization.
- Monthly auto-renewable product created: com.mondaymoneymove.monthly, Apple ID 6815980788; duration 1 month; English display name Monday Money Move Monthly.
- Subscription price $9.99 USD, with Apple-generated regional price equivalents. Initial subscription sale availability is United States only.
- Introductory offer configured: free for 1 week, start September 25, 2026, no end date, for eligible new subscribers. Regional offer configuration exists but does not expand sale availability.
- Subscription review notes and actual saved-move screenshot uploaded.
- App privacy questionnaire saved as Data Not Collected, based on native source; NOT published. Publication presents an accuracy/legal agreement and requires the account holder's confirmation.
- Existing listing copy, keywords, support/marketing URLs and app review notes already populated. Review contact details remain incomplete and were not saved; Apple requires a phone number.

## Build evidence
GitHub Actions run 36105896253 completed successfully for release commit 0238e23634be13ffd43f22211e9e05e3d4f915fe. Native tests, screenshot export and unsigned Release device build passed. Screenshots artifact 10851367174. This is NOT a signed App Store upload.

## Required before submission
1. Signed archive/upload: TestFlight explicitly shows No Builds. Use Xcode on an authorized Mac with the Monday Money Move LLC developer team; validate/upload the prepared release branch, then select Apple's processed build. No signing credentials were available to this session.
2. Finish Apple payout bank and U.S. W-9 information. Paid Apps Agreement is Pending User Info; Free Apps Agreement is Active. Never place banking numbers or tax identifiers in this repository.
3. Verify and fix the live privacy/support/terms URLs before publishing privacy answers and submitting. Native source and listing still reference /privacy.html, /support.html and /terms.html. Web retrieval could not verify them. Wix confirms the canonical site is https://www.mondaymoneymove.com/ but this does not verify the policy paths or contents. Privacy Policy URL in App Privacy is still empty.
4. Complete and save Apple review contact name, phone and email from the owner's approved business contact details.
5. Test real StoreKit sandbox purchase, restore, cancellation/expiration and revoked access; verify reminder permission/delivery on a physical iPhone. Core CI does not cover these.
6. Confirm subscription is included with the first app version, finish build export-compliance responses, and submit only once all requirements are satisfied.
7. Initial availability is United States. EU trader verification is not completed; resolve it before expanding to EU distribution.

Automatic approval review rejected the Add for Review action because the required signed build is missing. No submission was sent. Do not retry or work around that block without satisfying the prerequisite.
