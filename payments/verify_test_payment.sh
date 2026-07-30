#!/usr/bin/env bash
# Verifies the Stripe account can take a payment, in TEST MODE ONLY:
# creates a $750 PaymentIntent and confirms it with Stripe's test Visa card.
#
# Usage: STRIPE_SECRET_KEY=sk_test_... ./verify_test_payment.sh
#
# Refuses to run with a live key — this is a rails check, not a real charge.
set -euo pipefail

if [[ -z "${STRIPE_SECRET_KEY:-}" ]]; then
  echo "ERROR: STRIPE_SECRET_KEY is not set." >&2
  exit 1
fi
if [[ "${STRIPE_SECRET_KEY}" != sk_test_* ]]; then
  echo "ERROR: refusing to run with a non-test key. Use an sk_test_ key." >&2
  exit 1
fi

result=$(curl -sS -X POST "https://api.stripe.com/v1/payment_intents" \
  -u "${STRIPE_SECRET_KEY}:" \
  -d "amount=75000" \
  -d "currency=usd" \
  -d "payment_method=pm_card_visa" \
  -d "confirm=true" \
  -d "automatic_payment_methods[enabled]=true" \
  -d "automatic_payment_methods[allow_redirects]=never" \
  --data-urlencode "description=LAS-5 test-mode rails verification")

status=$(echo "$result" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('status') or d.get('error',{}).get('message',''))")

if [[ "$status" == "succeeded" ]]; then
  pi_id=$(echo "$result" | python3 -c "import json,sys; print(json.load(sys.stdin)['id'])")
  echo "OK: test payment succeeded (PaymentIntent ${pi_id}, \$750.00, test Visa)."
  echo "Evidence: visible in Stripe dashboard > Payments (test mode)."
else
  echo "FAILED: ${status}" >&2
  exit 1
fi
