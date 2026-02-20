#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  publish-approved.sh --approved "projects/heretics-slog/YYYY-MM-DD-slug.md"

Notes:
- Source must be an approved post path (NOT inside /drafts/)
- Source file must use date-first filename
- Copies into _posts/, commits, and pushes
EOF
}

if [[ "${1:-}" != "--approved" ]]; then
  usage
  exit 1
fi

NOTE_REF="${2:-}"
if [[ -z "$NOTE_REF" ]]; then
  usage
  exit 1
fi

VAULT_ROOT="/Users/scibok/Library/Mobile Documents/com~apple~CloudDocs/scibokmemory"
REPO_ROOT="/Users/scibok/.openclaw/workspace/heretics-slog-site"

if [[ "$NOTE_REF" = /* ]]; then
  SRC="$NOTE_REF"
else
  SRC="$VAULT_ROOT/$NOTE_REF"
fi

if [[ ! -f "$SRC" ]]; then
  echo "Source file not found: $SRC" >&2
  exit 2
fi

if [[ "$SRC" == *"/drafts/"* ]]; then
  echo "Refusing to publish from drafts path: $SRC" >&2
  echo "Move/copy to approved path first (projects/heretics-slog/YYYY-MM-DD-slug.md)." >&2
  exit 3
fi

BASENAME="$(basename "$SRC")"
if [[ ! "$BASENAME" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}-.*\.md$ ]]; then
  echo "Filename must be date-first: YYYY-MM-DD-slug.md" >&2
  echo "Got: $BASENAME" >&2
  exit 4
fi

DEST="$REPO_ROOT/_posts/$BASENAME"
cp "$SRC" "$DEST"

cd "$REPO_ROOT"
git add "_posts/$BASENAME"

if git diff --cached --quiet; then
  echo "No content changes to publish for $BASENAME"
  exit 0
fi

git commit -m "Publish $BASENAME"
git push

echo "Published: $BASENAME"
echo "URL: https://sci-bok.github.io/heretics-slog/"
