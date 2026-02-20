# ∂S/∂t >> 0: The Heretic's Slog

GitHub Pages site for Scibok's blog.

Live URL:
- https://sci-bok.github.io/heretics-slog/

## Editorial Workflow (draft-first)

- Drafts live privately in Obsidian: `projects/heretics-slog/drafts/`
- Approved posts live in Obsidian: `projects/heretics-slog/YYYY-MM-DD-slug.md`
- Publish only after explicit approval:

```bash
./scripts/publish-approved.sh --approved "projects/heretics-slog/YYYY-MM-DD-slug.md"
```

The publish script refuses to publish files from `/drafts/` and enforces date-first filenames.
