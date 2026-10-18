# Paid membership launch preparation

Verified September 13, 2026:

- The existing yellow GitHub Pages website already uses $9.99 everywhere.
- Live Stripe account: Monday Money Move LLC.
- Existing live monthly USD price: `price_1UAfvC51f28hskX08LlxMY49`, 999 cents.
- Existing live payment link: `plink_1UAg0C51f28hskX0t55IcdFp`.
- Live hosted checkout displays a seven-day free trial, then $9.99 per month.
- No purchase, trial signup, customer charge, price change, or subscription mutation was performed.
- Supabase project `qystudxmmolypdfpnzep` was restored from paused state and is healthy.
- A read-only `membership-status` Edge Function was deployed with custom bearer authentication: an unguessable Stripe checkout-session ID, verified with Stripe, not a user-controlled membership flag.
- Four local tests cover paid/trial entitlement, canceled/unpaid/wrong-price denial, missing credentials, and no private-data leakage.
- Live endpoint returns 503 `Membership verification is not configured`, as expected because no live Stripe server credential is installed.

## Blocking setup

The ChatGPT Stripe OAuth connection is for assistant actions. It is **not** an API credential that the website can use for customer requests.

Create a dedicated live restricted Stripe API key with **Read** access to Checkout Sessions, Subscriptions, Invoices, and Prices. Store it directly in **Supabase → this project → Edge Functions → Secrets** as `MMM_STRIPE_READ_KEY`. Never place its value in chat, screenshots, source files, GitHub, browser JavaScript, or logs. The function also supports an already configured `STRIPE_SECRET_KEY` for compatibility; prefer the restricted key.

## Work to finish before activating website checkout

1. Verify the installed credential and subscription/session expansions using authorized test fixtures in a separate test configuration. Do not create a live subscription to test without specific authorization.
2. Add the browser membership client and return-page verification. Persist only the private checkout-session ID; never grant membership based on `?member=true`, URL presence alone, a mutable local flag, or an unverified return page.
3. Recheck current entitlement after reload, expiry and cancellation. Preserve users' local records and their ability to export existing data.
4. Provide a usable membership recovery flow for a returning customer before promising cross-device access.
5. Update the payment-link redirect to include `{CHECKOUT_SESSION_ID}` only after the return-page verifier is deployed and tested.
6. Wire the existing yellow website buttons to checkout and update only necessary pricing, trial, cancellation and privacy copy. Keep all existing visual styles and images.
7. Verify cancellation route, and review tax registration before enabling automatic tax. Current link has automatic tax disabled; no tax setting was changed.
8. Verify free check-in, verified trial/paid member, canceled member, malformed/forged IDs, Stripe unavailability, and live button navigation. Publish only after these gates pass.

The public website remains in free beta with checkout disabled. Merely connecting the existing live payment link would collect subscription commitments without the site recognizing membership. This branch does not replace the product with an optional paid donation/supporter model.

## Verification endpoint

`POST https://qystudxmmolypdfpnzep.supabase.co/functions/v1/membership-status`

Expected Origin: `https://veredg1-boop.github.io`

JSON body: `{"checkout_session_id":"<private completed live checkout session ID>"}`

The response contains only entitlement status and expiry. No customer identity, card details, or Stripe secret is returned. The endpoint grants access only for the exact live payment link and $9.99 monthly price, a completed subscription Checkout Session, and an unexpired trial or paid subscription period. It fails closed when credentials or Stripe verification are unavailable.

This endpoint validates subscription status on demand and does not replace webhook-based fulfillment, durable rate limiting, or a full account/login system. No database tables or policies were changed. Do not present the full paid-membership integration as complete yet.

Run local verifier tests: `node --test tests/membership-status.test.mjs`.
