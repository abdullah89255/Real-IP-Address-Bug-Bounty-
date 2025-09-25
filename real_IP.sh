#!/usr/bin/env bash
set -euo pipefail

TARGET="example.com"
OUTDIR="./out/${TARGET}_$(date +%F_%T)"
mkdir -p "$OUTDIR"

# Safety config
MAX_ERRORS=5
ERROR_COUNT=0
RATE_LIMIT=40  # threads for httpx / tools

# 1) Passive subdomain enumeration
amass enum -passive -d "$TARGET" -o "$OUTDIR/amass.txt" || ((ERROR_COUNT++))

subfinder -d "$TARGET" -silent -o "$OUTDIR/subfinder.txt" || ((ERROR_COUNT++))

# Safety check
if (( ERROR_COUNT >= MAX_ERRORS )); then
  echo "Too many errors — aborting." >&2
  exit 1
fi

# 2) Consolidate subs
cat "$OUTDIR/"*.txt | sort -u > "$OUTDIR/subs_all.txt"

# 3) Get historical URLs (passive)
cat "$OUTDIR/subs_all.txt" | gau --subs > "$OUTDIR/gau_urls.txt" || ((ERROR_COUNT++))

# 4) Lightweight HTTP probing
cat "$OUTDIR/subs_all.txt" | httpx -threads "$RATE_LIMIT" -status-code -title -o "$OUTDIR/httpx.txt" || ((ERROR_COUNT++))

# Final safety check
if (( ERROR_COUNT > 0 )); then
  echo "Completed with $ERROR_COUNT non-fatal errors. Check logs." >&2
fi

echo "Passive pipeline finished. Results in $OUTDIR"
