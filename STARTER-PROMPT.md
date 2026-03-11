# Starter Prompt for Claude Code

Copy everything below the line and paste it as your first message in Claude Code.

---

Read the CLAUDE.md file in this repo. It contains the complete spec for a Conveo Social Command Center app — a Next.js 14 + Supabase social media management tool. Build the entire app from scratch following that spec exactly.

Start by:
1. Running `./setup.sh` to scaffold the project and install dependencies
2. Reading CLAUDE.md fully to understand the architecture, design system, data model, and AI prompts
3. Building the app in this order: Supabase schema → Tailwind theme → layout + sidebar → Library page (with seed data) → Create/Editor page (with live rubric) → Dashboard → Calendar → Ideas → Accounts → Analytics → Settings

The knowledge base repo is at `~/Documents/conveo-cowork-engine/` — read files from there for AI system prompts and seed data, but never write to it.

Key things to get right:
- Dark mode (#1a1a1a background) with Conveo orange (#E55425) accents — match the preview.html aesthetic
- IBM Plex Serif for headlines, Inter for body, IBM Plex Mono for scores
- Live 8-dimension rubric scoring in the post editor sidebar
- 3 AI variations (hook-optimized, proof-optimized, engagement-optimized) on every generation
- Buffer API integration for dynamic account loading and post scheduling
- Import all 26 seed posts from the preview.html JavaScript data array
