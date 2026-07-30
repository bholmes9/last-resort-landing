#!/usr/bin/env bash
# Creates the three advisory offers as Stripe Products + Prices + Payment Links.
#
# Usage:
#   STRIPE_SECRET_KEY=sk_test_... ./create_payment_links.sh            # test mode
#   STRIPE_SECRET_KEY=sk_live_... ./create_payment_links.sh            # live mode
#   ./create_payment_links.sh --dry-run                                # print calls, hit nothing
#
# Run once per mode (test, then live). Re-running creates duplicate
# products/links — archive extras in the Stripe dashboard if that happens.
#
# A restricted key is enough; it needs write access to: Products, Prices,
# Payment Links. Never commit or paste the key anywhere — pass it via env.
set -euo pipefail

# Offer names are provisional until LAS-4 finalizes the offer kit; edit here.
OFFER_NAMES=(
  "Agentic AI Advisory — Strategy Session"
  "Agentic AI Advisory — Working Session Package"
  "Agentic AI Advisory — Pilot Engagement"
)
OFFER_DESCRIPTIONS=(
  "Deep-dive session on your agentic AI / SDLC-automation problem, with written recommendations."
  "Strategy session plus hands-on working sessions and an implementation roadmap."
  "End-to-end pilot: design, build guidance, and review of one agentic workflow in your stack."
)
OFFER_AMOUNTS_CENTS=(75000 150000 250000)  # $750 / $1,500 / $2,500
CURRENCY="usd"

DRY_RUN=0
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=1

if [[ $DRY_RUN -eq 0 && -z "${STRIPE_SECRET_KEY:-}" ]]; then
  echo "ERROR: STRIPE_SECRET_KEY is not set (use --dry-run to preview)." >&2
  exit 1
fi

api() {
  local path="$1"; shift
  if [[ $DRY_RUN -eq 1 ]]; then
    echo "DRY RUN: POST https://api.stripe.com/v1/${path} $*" >&2
    # Fake ids so the dry run exercises the full flow.
    echo "{\"id\": \"dryrun_${path//\//_}\", \"url\": \"https://buy.stripe.com/dryrun\"}"
    return 0
  fi
  curl -sS -X POST "https://api.stripe.com/v1/${path}" \
    -u "${STRIPE_SECRET_KEY}:" \
    "$@"
}

json_field() { # json_field <field> — extract a top-level string field from stdin
  python3 -c "import json,sys; print(json.load(sys.stdin).get('$1',''))"
}

echo "Creating ${#OFFER_NAMES[@]} offers (mode: $([[ $DRY_RUN -eq 1 ]] && echo dry-run || echo "${STRIPE_SECRET_KEY:0:7}..."))"
echo

RESULTS=()
for i in "${!OFFER_NAMES[@]}"; do
  name="${OFFER_NAMES[$i]}"
  desc="${OFFER_DESCRIPTIONS[$i]}"
  amount="${OFFER_AMOUNTS_CENTS[$i]}"

  product_json=$(api "products" \
    --data-urlencode "name=${name}" \
    --data-urlencode "description=${desc}")
  product_id=$(echo "$product_json" | json_field id)
  if [[ -z "$product_id" ]]; then
    echo "ERROR creating product '${name}': ${product_json}" >&2; exit 1
  fi

  price_json=$(api "prices" \
    -d "product=${product_id}" \
    -d "unit_amount=${amount}" \
    -d "currency=${CURRENCY}")
  price_id=$(echo "$price_json" | json_field id)
  if [[ -z "$price_id" ]]; then
    echo "ERROR creating price for '${name}': ${price_json}" >&2; exit 1
  fi

  link_json=$(api "payment_links" \
    -d "line_items[0][price]=${price_id}" \
    -d "line_items[0][quantity]=1")
  link_url=$(echo "$link_json" | json_field url)
  if [[ -z "$link_url" ]]; then
    echo "ERROR creating payment link for '${name}': ${link_json}" >&2; exit 1
  fi

  printf '%-50s $%-8s %s\n' "$name" "$((amount / 100))" "$link_url"
  RESULTS+=("${name}|${link_url}")
done

echo
echo "Done. Paste the links above into the LAS-5 issue thread (links are public URLs, safe to share)."
