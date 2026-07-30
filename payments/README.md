# Payment rails (LAS-5)

Everything needed to accept payment for the three advisory offers ($750 / $1,500 / $2,500)
and to invoice consulting clients and the property-marketing fee.

## What's here

| File | Purpose |
|---|---|
| `create_payment_links.sh` | Creates the 3 offers as Stripe Products + Prices + Payment Links. Works in test or live mode. `--dry-run` previews without touching Stripe. |
| `verify_test_payment.sh` | Test-mode-only check: confirms a $750 PaymentIntent with Stripe's test Visa. Refuses live keys. |
| `invoice-consulting.html` | Printable consulting invoice template (open in browser → fill brackets → print to PDF). |
| `invoice-dad-fee.html` | Printable marketing-services invoice for the land-sale fee, milestone-structured to match the LAS-7 agreement. |

## Ben's one-time setup (~15 min, only part agents can't do)

1. Go to <https://dashboard.stripe.com/register> and create an account with your email.
2. Activate the account (Settings → "Activate payments"): individual/sole-prop is fine —
   needs legal name, address, **last 4 of SSN**, and a **bank account** for payouts.
3. Note: Stripe holds the *first* payout 7–14 days from your first live charge; money still
   collects, it just lands in the bank after the hold. Starting sooner = paid sooner.

Then pick ONE of:

- **Option A — you click (no key sharing):** Dashboard → Payment Links → "+ New" → create three
  links: $750 / $1,500 / $2,500, one-time, USD, names from `create_payment_links.sh`. Paste the
  three `buy.stripe.com/...` URLs in the LAS-5 thread (they're public URLs, safe to share).
- **Option B — agents do it (recommended):** two keys, one per phase (add each as a
  Paperclip secret for the Coder agent — never paste keys in comments/chat):
  1. **Test phase — standard test secret key (`sk_test_...`):** Dashboard → toggle **Test mode**
     → Developers → API keys → copy the "Secret key". It must be the standard key, not a
     restricted one: the test-payment verification creates a PaymentIntent, which restricted
     keys scoped to Products/Prices/Payment Links can't do (and `verify_test_payment.sh`
     only accepts `sk_test_` keys). Test mode can't touch real money, so this is low-risk.
  2. **Live phase — restricted live key (`rk_live_...`):** Dashboard → **Live mode** →
     Developers → API keys → "Create restricted key" with **write** on Products, Prices,
     Payment Links only. That's all the live-link creation needs; agents never get broad
     live access.

## Running the scripts

```sh
STRIPE_SECRET_KEY=sk_test_... ./create_payment_links.sh   # prints 3 payment-link URLs
STRIPE_SECRET_KEY=sk_test_... ./verify_test_payment.sh    # proves a test payment completes
STRIPE_SECRET_KEY=rk_live_... ./create_payment_links.sh   # live links, run once (restricted key)
```

Final live verification: open a live link, pay the $750 offer with a real card, refund from the
dashboard if it was a self-test (refunds return the full amount; Stripe keeps the fee).
