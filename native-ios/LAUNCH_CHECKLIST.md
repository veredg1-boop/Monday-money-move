# Monday Money Move — App Store Launch Status

## Completed
- Public beta web app on mondaymoneymove.com
- Company-owned product domain
- Live support, privacy policy, and terms URLs on the company domain
- Three-step weekly check-in
- Saved weekly move and completion history
- Local-device data storage
- Monday reminder logic in native iOS source
- Native SwiftUI application source
- StoreKit subscription manager scaffold
- App Store subscription screen with first-move trial gate
- Restore Purchases control
- Subscription status and purchase error messaging
- Native subscription product ID prepared: com.mondaymoneymove.monthly
- Native iOS purchase flow verified to use Apple StoreKit rather than Stripe
- Draft App Store title, subtitle, description, keywords, category, and URLs
- Privacy policy, terms, and support page
- Master brand icon artwork
- Final 1024×1024 opaque PNG App Store icon in the AppIcon asset catalog
- Apple privacy manifest for UserDefaults (CA92.1)
- iPhone and iPad target configuration
- Removed unneeded Apple Pay entitlement from native target
- Stripe payout bank account connected (USD account ending 2463)

## External setup required before submission
- Company-domain email address
- D-U-N-S Number for Monday Money Move LLC (request under review)
- Apple Developer Program organization enrollment
- Apple identity and legal-authority verification
- $99 annual Apple Developer membership purchase
- App Store Connect app record
- Create the App Store Connect auto-renewable subscription using product ID: com.mondaymoneymove.monthly
- Apple banking and tax agreements before paid App Store proceeds
- Final Xcode archive, device testing, screenshots, and App Review submission

## Product checks before review
- Compile with current Xcode
- Test reminder permission on device
- Test local history persistence
- Configure and test StoreKit subscription in sandbox
- Confirm privacy answers in App Store Connect

## Temporarily blocked
- Supabase dashboard connector authentication failed repeatedly; do not retry until the connection issue is resolved.
