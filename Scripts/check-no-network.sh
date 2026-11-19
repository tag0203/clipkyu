#!/usr/bin/env bash
# Fails if the app or core grows a network client. Documentation may mention the policy.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
matches="$(grep -RInE 'URLSession|import Network|NWConnection|com\.apple\.security\.network' \
  "$root/Sources" "$root/Tests" "$root/App" "$root/Package.swift" || true)"

if [[ -n "$matches" ]]; then
  echo "error: networking code or a network entitlement is not allowed" >&2
  echo "$matches" >&2
  exit 1
fi
