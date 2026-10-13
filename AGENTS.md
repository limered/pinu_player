# AGENTS.md

Pingu Player: a planned Android-only Flutter app that plays curated single Pingu episodes from YouTube for a child. **No app code exists yet**; the repo is in the planning phase (no Flutter app project, no build/test commands). Throwaway spikes live under `spikes/` (each has its own README); they are not the app.

## Where things live

- **Project docs live in the user's Obsidian vault** (outside this repo), not in a repo-local `.scratch/`. The vault path depends on the machine:
  - Linux: `/home/limered/Projects/main/dev/pinu_player`
  - Windows: `C:/_source/obsidian/main/dev/pinu_player`
  - `CONTEXT.md`: the domain glossary (Video, Episode, Compilation, Series, Catalog, Session, Episode Limit). Use these terms exactly; it holds terms only, no implementation details.
  - `wayfinder/`: the local file tracker.
- `wayfinder/map.md` is the wayfinder map. It holds the Destination, standing Notes, Decisions so far, fog, and out-of-scope items. Read it before any planning or implementation work.
- `wayfinder/NN-<slug>.md` are tickets, with `Type:`, `Status:`, `Assignee:` and `Blocked by:` headers. To claim a ticket, set its Assignee before starting work. Resolve at most one non-research ticket per session.
- `wayfinder/research/` holds research findings that tickets link to. Write findings to files there, not to git branches.

## Hard constraints (from the user)

- **Never download YouTube video or audio**, not even in helper tools. Metadata-only calls (`yt-dlp --skip-download` / `--flat-playlist -J`) and streaming playback are fine.
- Android only. No parent PIN, kiosk mode or screen pinning. The screen must stay awake during playback.
- Exclude a Compilation (a video made of clips cut from several episodes). Videos that bundle complete episodes are valid sources. Episodes start after the video's 10-second intro.
- Classic and Pingu in the City are separate Series, with official episode order within each.
- Reference test video: `cPGTw1rNjrU`.

## Environment

- Two machines are in play: **Windows / PowerShell** (`C:/_source/obsidian/...`) and **Linux** (`/home/limered/Projects/main/dev/...`). Check which one you are on before using vault paths.
- On Windows, `yt-dlp` is not installed globally, and its per-video detail lookups fail without a JavaScript runtime.
