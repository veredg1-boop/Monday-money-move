# Monday Money Move — App Store Launch Status

## Completed
- Public beta web app
- Three-step weekly check-in
- Saved weekly move and completion history
- Local-device data storage
- Monday reminder logic in native iOS source
- Native SwiftUI application source
- StoreKit subscription manager scaffold
- App Store subscription screen with first-move trial gate
- Restore Purchases control
- Subscription status and purchase error messaging
- Draft App Store title, subtitle, description, keywords, and category
- Privacy policy, terms, and support page
- Master brand icon artwork
- Apple privacy manifest for UserDefaults (CA92.1)
- iPhone and iPad target configuration
- Removed unneeded Apple Pay entitlement from native target

## External setup required before submission
- Generate final 1024×1024 PNG App Store icon from the master artwork and add it to an AppIcon asset catalog
- Company-owned neutral domain
- Company-domain email address
- D-U-N-S Number for Monday Money Move LLC
- Apple Developer Program organization enrollment
- Apple identity and legal-authority verification
- $99 annual Apple Developer membership purchase
- App Store Connect app record
- In-App Purchase product: com.mondaymoneymove.monthly
- Banking and tax agreements before paid proceeds
- Final Xcode archive, device testing, screenshots, and App Review submission

## Product checks before review
- Compile with current Xcode
- Test reminder permission on device
- Test local history persistence
- Configure and test StoreKit subscription in sandbox
- Confirm privacy answers in App Store Connect
- Confirm no Stripe purchase links are present in the native iOS build
