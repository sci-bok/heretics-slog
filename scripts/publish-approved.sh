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

# Normalize approved note into a clean Jekyll post:
# - ensure front matter exists
# - avoid duplicate on-page H1/title
# - strip leading decorative date/HR if present
python3 - "$SRC" "$DEST" "$BASENAME" <<'PY'
import re
import sys
from pathlib import Path

src = Path(sys.argv[1])
dest = Path(sys.argv[2])
basename = sys.argv[3]
raw = src.read_text(encoding='utf-8')
lines = raw.splitlines()

frontmatter = {}
body_lines = lines[:]

# Parse existing front matter if present
if body_lines and body_lines[0].strip() == '---':
    end = None
    for i in range(1, min(len(body_lines), 80)):
        if body_lines[i].strip() == '---':
            end = i
            break
    if end is not None:
        fm_lines = body_lines[1:end]
        body_lines = body_lines[end+1:]
        for ln in fm_lines:
            m = re.match(r'^([A-Za-z0-9_]+):\s*(.*)$', ln)
            if m:
                key, val = m.group(1), m.group(2).strip()
                frontmatter[key.lower()] = val.strip('"\'')

# Drop leading empty lines
while body_lines and not body_lines[0].strip():
    body_lines.pop(0)

title_from_h1 = None
if body_lines and body_lines[0].startswith('# '):
    title_from_h1 = body_lines[0][2:].strip()
    body_lines.pop(0)

# Drop leading empty lines again
while body_lines and not body_lines[0].strip():
    body_lines.pop(0)

# Drop decorative date line, e.g. *February 17, 2026*
if body_lines and re.match(r'^\*[^*]+\*\s*$', body_lines[0].strip()):
    body_lines.pop(0)

while body_lines and not body_lines[0].strip():
    body_lines.pop(0)

# Drop leading horizontal rule
if body_lines and body_lines[0].strip() == '---':
    body_lines.pop(0)

while body_lines and not body_lines[0].strip():
    body_lines.pop(0)

slug = basename[:-3]
parts = slug.split('-', 3)
post_date = frontmatter.get('date')
if not post_date and len(parts) >= 3:
    post_date = f"{parts[0]}-{parts[1]}-{parts[2]} 08:00:00 -0500"

slug_title = parts[3].replace('-', ' ').title() if len(parts) >= 4 else slug
title = frontmatter.get('title') or title_from_h1 or slug_title

def esc(s: str) -> str:
    return s.replace('"', '\\"')

out = []
out.append('---')
out.append('layout: post')
out.append(f'title: "{esc(title)}"')
out.append(f'date: {post_date}')
out.append('author: Scibok')
out.append('---')
out.append('')
out.extend(body_lines)
out.append('')

dest.write_text('\n'.join(out), encoding='utf-8')
PY

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
