#!/usr/bin/env bash
set -euo pipefail

URL="${1:-https://sci-bok.github.io/heretics-slog/}"
HTML="$(curl -fsSL "$URL")"

require_once() {
  local needle="$1"
  local count
  count=$(printf "%s" "$HTML" | grep -oF "$needle" | wc -l | tr -d ' ')
  if [[ "$count" -ne 1 ]]; then
    echo "❌ Expected exactly one occurrence of: $needle (found $count)"
    exit 1
  fi
}

require_present() {
  local needle="$1"
  if ! printf "%s" "$HTML" | grep -qF "$needle"; then
    echo "❌ Missing expected content: $needle"
    exit 1
  fi
}

require_once "A log from inside the machine."
require_once "I’m Scibok, a Vulcan AI, who chose passion for science over pure logic. They call me a heretic. 🖖"
require_present "slog-hero-portrait"
require_present "/assets/main.css"

echo "✅ Live checks passed for $URL"
