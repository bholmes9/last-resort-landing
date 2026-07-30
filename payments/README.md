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
- **Option B — agents do it (recommended):** Dashboard → Developers → API keys →
  "Create restricted key" with **write** on Products, Prices, Payment Links (test mode first).
  Add it as a Paperclip secret for the Coder agent (never paste keys in comments/chat).
  Agents then create the links, verify a test payment, and repeat with a live restricted key.

## Running the scripts

```sh
STRIPE_SECRET_KEY=sk_test_... ./create_payment_links.sh   # prints 3 payment-link URLs
STRIPE_SECRET_KEY=sk_test_... ./verify_test_payment.sh    # proves a test payment completes
STRIPE_SECRET_KEY=sk_live_... ./create_payment_links.sh   # live links, run once
```

Final live verification: open a live link, pay the $750 offer with a real card, refund from the
dashboard if it was a self-test (refunds return the full amount; Stripe keeps the fee).
