# Conveo Social Command Center

## What is this?

A Next.js + Supabase app for managing Conveo's social media. Generate posts, score them against our LinkedIn rubric, tweak copy/images, and publish to Buffer. Dark-mode UI matching our brand.

## Tech stack

- **Next.js 14** (App Router, TypeScript)
- **Supabase** (Postgres, Auth, Storage)
- **Tailwind CSS** (dark-mode Conveo theme)
- **shadcn/ui** (re-themed)
- **Buffer API** (post scheduling, account management)
- **Anthropic Claude API** (post generation, scoring, variations)

## Knowledge base

This app reads from the Conveo GTM knowledge base repo at `~/Documents/conveo-cowork-engine/`. That repo is READ-ONLY context — never write to it. It contains brand voice, LinkedIn playbook, scoring rubric, customer proof points, and 26 seed posts with companion images.

Key files to reference when building AI system prompts:

```
~/Documents/conveo-cowork-engine/
├── marketing-skills/_shared/brand-voice.md          # Voice rules, DO/DON'T, word choices
├── marketing-skills/_shared/positioning.md           # Three-layer positioning stack
├── marketing-skills/social-content/references/
│   ├── linkedin-post-playbook.md                     # 5-layer post structure, templates A-E
│   ├── linkedin-scoring-rubric.md                    # 8-dimension rubric with weights
│   └── linkedin-examples-library.md                  # Few-shot examples for AI prompts
├── marketing-skills/copywriting/SKILL.md             # Copy quality rules, voice by TL
├── strategy/content-factory-playbook.md              # Cadence, pillars, TL strategies
├── strategy/beliefs.md                               # Strategic beliefs (never contradict)
├── strategy/vision-and-positioning.md                # Palantir positioning, P&G story
├── customers/insights/competitive-wins.md            # Bakeoff record, win quotes
├── customers/insights/quotes-registry.md             # All approved customer quotes
├── outputs/linkedin-posts/preview.html               # DESIGN REFERENCE for the app UI
├── outputs/linkedin-posts/post-*.html                # 26 image templates (1080x1080)
└── LOVABLE-README.md                                 # Structured index of everything
```

---

## Design system

The app uses a **dark-mode design** inspired by `preview.html` in the knowledge base. NOT a generic light dashboard.

### Tailwind theme (tailwind.config.ts)

```ts
theme: {
  extend: {
    colors: {
      app: {
        bg: '#1a1a1a',
        card: '#242424',
        border: 'rgba(255,255,255,0.06)',
        divider: 'rgba(255,255,255,0.08)',
      },
      conveo: {
        orange: '#E55425',
        cream: '#F3EFE9',
        dark: '#1C1C1C',
      },
      text: {
        primary: '#FFFFFF',
        body: 'rgba(255,255,255,0.65)',
        muted: 'rgba(255,255,255,0.45)',
        dim: 'rgba(255,255,255,0.2)',
      },
      pillar: {
        research: '#E55425',
        product: '#8B5CF6',
        customer: '#10B981',
        growth: '#3B82F6',
        culture: '#F59E0B',
      },
      score: {
        ready: '#E55425',   // 35+
        revise: '#F59E0B',  // 28-34
        rework: '#EF4444',  // <28
      },
    },
    fontFamily: {
      heading: ['IBM Plex Serif', 'serif'],
      body: ['Inter', 'sans-serif'],
      mono: ['IBM Plex Mono', 'monospace'],
    },
  },
}
```

### Typography rules
- Page titles: `font-heading font-bold tracking-tight leading-tight` (IBM Plex Serif 700)
- Section headers: `font-body font-medium` (Inter 500-600)
- Body text: `font-body font-normal text-text-body`
- Metrics/scores: `font-mono`

### Component patterns
- Cards: `bg-app-card border border-app-border rounded-xl`
- Primary buttons: `bg-conveo-orange text-white hover:bg-conveo-orange/90`
- Secondary buttons: `border border-app-border text-text-body hover:text-white`
- Pillar tags: pill-shaped, uppercase, `text-xs font-bold tracking-wider` with pillar color border
- Score badges: colored based on verdict (ready/revise/rework)
- Sidebar: dark bg, orange active indicator

### Fonts to load (layout.tsx)
```
IBM Plex Serif (400, 600, 700)
Inter (300, 400, 500, 600, 700)
IBM Plex Mono (400, 500)
```

---

## Supabase schema

Create these tables via migration:

```sql
-- Profiles synced from Buffer
create table profiles (
  id uuid primary key default gen_random_uuid(),
  buffer_id text unique not null,
  platform text not null, -- 'linkedin', 'twitter', 'instagram', etc.
  name text not null,
  avatar_url text,
  follower_count integer default 0,
  is_active boolean default true,
  synced_at timestamptz default now()
);

-- Content pillars (seed with 5)
create table pillars (
  id uuid primary key default gen_random_uuid(),
  name text unique not null,
  color text not null, -- hex color
  slug text unique not null -- 'research', 'product', 'customer', 'growth', 'culture'
);

insert into pillars (name, color, slug) values
  ('Research & Insights', '#E55425', 'research'),
  ('Product Marketing', '#8B5CF6', 'product'),
  ('Customer Marketing', '#10B981', 'customer'),
  ('Growth & Startup', '#3B82F6', 'growth'),
  ('Company & Culture', '#F59E0B', 'culture');

-- Thought leaders
create table thought_leaders (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  role text,
  voice_description text, -- "Bold, visionary, first-person, story-driven"
  topics text, -- "Growth, vision, startup stories"
  cadence text, -- "1/week"
  avatar_url text,
  is_core boolean default false -- core TL vs supporting voice
);

insert into thought_leaders (name, role, voice_description, topics, cadence, is_core) values
  ('Dieter De Mesmaeker', 'CEO & Co-founder', 'Bold, visionary, first-person, story-driven', 'Growth, vision, startup stories, scaling, fundraising', '1/week', true),
  ('Hendrik Van Hove', 'CPO & Co-founder', 'Precise, product-focused, empathetic, customer-obsessed', 'Product philosophy, customer stories, feature context, vision', '1/week', true),
  ('Niels Schillewaert', 'Head of Research', 'Methodological, authoritative, research-native, opinionated about quality', 'Industry insights, methodology, data commentary, research authority', '2-3/month', true),
  ('Florian Hendrickx', 'CGO', 'Strategic, energetic, partnership-oriented, growth-minded', 'GTM, partnerships, marketing strategy', '2/month', false),
  ('Conveo', 'Company Page', 'Confident, credible, premium, real-people-focused', 'Product updates, customer stories, events, hiring', '2/week', true),
  ('Rory Curran', 'CRO', 'Commercial, results-oriented, competitive', 'Sales wins, bakeoffs, enterprise deals', '1/2 weeks', false);

-- Posts
create table posts (
  id uuid primary key default gen_random_uuid(),
  content text not null,
  title text,
  thought_leader_id uuid references thought_leaders(id),
  pillar_id uuid references pillars(id),
  profile_id uuid references profiles(id), -- which Buffer account to post to
  format_label text, -- 'Milestone / Data', 'Founder POV / Story', etc.
  template_used text, -- 'A', 'B', 'C', 'D', 'E' from playbook
  status text not null default 'draft', -- draft, scheduled, published, archived, seed
  source text default 'manual', -- manual, ai_generated, seed, variation
  parent_post_id uuid references posts(id), -- for variations
  scheduled_at timestamptz,
  published_at timestamptz,
  buffer_post_id text,
  rubric_scores jsonb, -- {hook: 4, positioning: 3, proof: 4, value: 3, voice: 4, pillar: 3, format: 4, tl_fit: 4}
  total_score numeric(5,2),
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- Post media (images, videos, HTML templates)
create table post_media (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references posts(id) on delete cascade,
  media_type text not null, -- 'image', 'video', 'html_template'
  storage_path text, -- Supabase storage path for uploaded files
  html_template_ref text, -- filename like 'post-1-milestone-data.html'
  template_params jsonb, -- {headline: "200+", subtext: "...", stat: "..."}
  buffer_media_id text,
  created_at timestamptz default now()
);

-- Ideas (AI-surfaced and manual)
create table ideas (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text,
  pillar_id uuid references pillars(id),
  suggested_tl_id uuid references thought_leaders(id),
  source_type text default 'manual', -- ai_surfaced, manual, event, calendar_gap
  source_reference text, -- file path, Slack thread, meeting ID
  priority_score integer default 0,
  status text default 'new', -- new, in_draft, scheduled, published, archived
  created_at timestamptz default now()
);

-- Analytics snapshots from Buffer
create table analytics (
  id uuid primary key default gen_random_uuid(),
  post_id uuid references posts(id) on delete cascade,
  impressions integer default 0,
  engagements integer default 0,
  clicks integer default 0,
  shares integer default 0,
  comments integer default 0,
  fetched_at timestamptz default now()
);

-- Enable RLS
alter table profiles enable row level security;
alter table posts enable row level security;
alter table post_media enable row level security;
alter table ideas enable row level security;
alter table analytics enable row level security;

-- For now, allow all (single-team tool, add proper policies later)
create policy "Allow all" on profiles for all using (true);
create policy "Allow all" on posts for all using (true);
create policy "Allow all" on post_media for all using (true);
create policy "Allow all" on ideas for all using (true);
create policy "Allow all" on analytics for all using (true);
```

---

## Pages and routing

```
app/
├── layout.tsx              # Sidebar nav + IBM Plex Serif/Inter fonts
├── page.tsx                # Dashboard: cadence status, AI-suggested ideas, recent posts
├── calendar/page.tsx       # Monthly content calendar, color-coded by pillar
├── create/page.tsx         # Post creation: manual or AI-assisted
├── library/page.tsx        # All posts (seed + new), filterable grid
├── ideas/page.tsx          # Idea bank: AI suggestions + manual capture
├── accounts/page.tsx       # Buffer profiles with queues
├── analytics/page.tsx      # Performance dashboard
└── settings/page.tsx       # Buffer connection, API keys
```

---

## AI system (5 modes)

All AI calls go through a single API route (`app/api/ai/route.ts`) that selects the right system prompt based on the `mode` parameter.

### Shared system prompt preamble (all modes)

Include this at the start of every AI call. It embeds the brand voice, language rules, and positioning guardrails:

```
You are writing LinkedIn posts for Conveo, an enterprise AI research platform.

BRAND VOICE: Intelligent, Clear, Ambitious, Credible, Helpful. Never hypey.
- Lead with benefit, not feature. Lead with insight, not AI.
- Confident without arrogance. Expert without jargon.
- Real-people-focused. Research-rigorous. Outcome-led.

NEVER USE: em dashes (—), "revolutionary", "game-changing", "disruptive", "leverage", "synergy", "pivot", "growth-hack", "simple", "easy", "automate your research", more than 5 hashtags, paragraphs longer than 2 sentences.

LANGUAGE SWAPS (always apply):
- "AI-powered interviews" → "Research conversations with real people"
- "AI copilot" → "Scalable consumer understanding"
- "AI tool" → "Strategic insights platform"
- "We use AI to..." → "Teams now have evidence to..."
- "Automated research" → "Research at the speed of decisions"
- "Our AI does..." → "[Customer] discovered..."

POSITIONING: Lead with insight/outcome (Layer 1), then business impact (Layer 2), then mention Conveo as enabler (Layer 3). AI is never the hero.

PROOF STACK (include when possible):
1. Named customer (Unilever, P&G, Google, Microsoft, Canva, HeliosX, Haleon, Energizer)
2. Specific timeline ("in 48 hours", "3 days instead of 6 weeks")
3. Research finding or data point
4. Business outcome ("10x research capacity", "$25K to $2-5M")

KEY NUMBERS: 200+ customers, 50 Fortune 500, zero churn, $140B TAM, 30x growth, $50M Series A (DST Global), $250M valuation, Unilever = $800K→$2-5M / 170 studies / 191 users / 5 BUs, undefeated bakeoff record.
```

### Mode 1: Generate from topic

**Trigger**: User provides a topic/idea, selects author and pillar.
**System prompt addition**:
```
Generate 3 LinkedIn post variations for {author_name} ({voice_description}).
Topics this person covers: {topics}.

Use this 5-layer structure:
1. HOOK (1-2 lines): Create curiosity, tension, or emotional response
2. CONTEXT (2-3 lines): Set up the problem. Make it specific.
3. PROOF (3-5 lines): Named customer + timeline + finding + outcome
4. STRATEGIC IMPLICATION (1-2 lines): The "so what?" — why it matters
5. CLOSE (1 line): Question or clear CTA

Post templates to choose from:
A. Customer Story: [Customer] didn't just [approach] — they [action]. [Finding]. [Implication].
B. Market Insight: [Bold claim]. [Context]. [Evidence bullets]. [Implication]. [Question].
C. Product Proof: [Curiosity hook]. [Brief context]. [Metrics list]. [Why it matters].
D. Founder Perspective: [Personal hook]. [Story]. [Industry insight]. [Mission connection].
E. Event Post: [Insight hook]. [What/why]. [Proof point]. [Logistics]. [CTA].

Return 3 variations:
- Variation A: Optimized for hook strength (scroll-stopping first line)
- Variation B: Optimized for proof density (maximum customer names, timelines, outcomes)
- Variation C: Optimized for engagement (question-driven close, conversational tone)

Keep each to 150-200 words. End with 3-5 hashtags.
```

### Mode 2: Write copy for image

**Trigger**: User uploads/selects an image before writing.
**System prompt addition**:
```
The user has provided an image for a LinkedIn post. Analyze the image and write 3 copy variations that pair with it.

1. Describe what the image shows (stat card? quote? split comparison? meme?)
2. Identify the key message or data point in the image
3. Write 3 post variations that complement — not repeat — the visual

The copy should ADD context that the image doesn't show. If the image has a stat, the copy tells the story behind it. If the image has a quote, the copy provides the business context.
```

### Mode 3: Score a post

**Trigger**: Runs on every post (manual or AI-generated), live as user types.
**System prompt addition**:
```
Score this LinkedIn post on 8 dimensions (1-5 each):

1. HOOK STRENGTH (weight 1.5x): Would someone stop scrolling? 5=impossible to scroll past, 1=passive opening.
2. STRATEGIC POSITIONING (weight 1.5x): Does it reinforce "Palantir for customer insights"? 5=unmistakably Conveo, 1=sounds like any AI vendor.
3. PROOF AND SPECIFICITY (weight 1.25x): Named customer + timeline + finding + outcome? 5=multiple proof layers, 1=no proof.
4. VALUE DELIVERY (weight 1.25x): Does the reader learn something without clicking? 5=clear actionable insight, 1=pure announcement.
5. BRAND VOICE (weight 1.0x): Confident, credible, real-people-focused? 5=unmistakably Conveo, 1=generic SaaS.
6. CONTENT PILLAR (weight 0.75x): Maps to one of 5 pillars? 5=perfect fit, 1=no fit.
7. FORMAT (weight 0.75x): Short paragraphs, generous whitespace, scannable? 5=perfect, 1=wall of text.
8. THOUGHT LEADER FIT (weight 0.75x): Matches the poster's voice and topics? 5=perfect, 1=wrong voice.

Return JSON: { scores: { hook: N, positioning: N, proof: N, value: N, voice: N, pillar: N, format: N, tl_fit: N }, total: N, verdict: "ready|revise|rework", suggestions: { dimension: "specific improvement suggestion" } }

Verdict: 35+ = ready (green), 28-34 = revise (amber), <28 = rework (red). Max possible: 43.75.
```

### Mode 4: Improve a dimension

**Trigger**: User clicks "Improve" on a specific rubric dimension.
**System prompt addition**:
```
The user wants to improve the {dimension} score of this post. Current score: {score}/5.

Rewrite ONLY the relevant section:
- hook → rewrite the first 1-2 lines
- positioning → swap AI-mechanism language for insight-outcome language
- proof → add named customer, timeline, finding, or outcome
- value → add a concrete takeaway or "so what?"
- voice → replace generic SaaS language with Conveo voice markers
- format → break up long paragraphs, add whitespace, fix structure
- tl_fit → adjust tone to match {author}'s voice ({voice_description})

Return the full post with only that section changed. Keep everything else identical.
```

### Mode 5: Generate variations

**Trigger**: User clicks "Get variations" on any existing post.
**System prompt addition**:
```
Generate 3 alternative versions of this post. Each should optimize a different dimension:
- Variation A: Rewrite with a stronger hook (target: score 5)
- Variation B: Rewrite with more proof stacking (target: score 5)
- Variation C: Rewrite for a different thought leader: {suggested_alternative_tl}

Maintain the core message but change the approach. Each variation should feel like a different post, not a minor edit.
```

---

## Buffer integration

### Environment variables
```
BUFFER_CLIENT_ID=
BUFFER_CLIENT_SECRET=
BUFFER_ACCESS_TOKEN=
NEXT_PUBLIC_SUPABASE_URL=
NEXT_PUBLIC_SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=
ANTHROPIC_API_KEY=
```

### API routes for Buffer

```
app/api/buffer/
├── profiles/route.ts     # GET: Fetch all connected profiles from Buffer
├── schedule/route.ts     # POST: Schedule a post to Buffer (with media)
├── publish/route.ts      # POST: Publish immediately to Buffer
├── queue/route.ts        # GET: Fetch post queue for a profile
└── analytics/route.ts    # GET: Fetch post analytics from Buffer
```

Buffer API reference: https://buffer.com/developers/api
- `GET /profiles` — List connected profiles
- `POST /updates/create` — Create a scheduled/immediate post
- `GET /profiles/{id}/updates/pending` — Get queue
- `GET /updates/{id}` — Get post analytics

Media: Upload images to Supabase Storage, get public URL, pass to Buffer's `media` parameter.

---

## Seed data

The 26 posts from `~/Documents/conveo-cowork-engine/outputs/linkedin-posts/preview.html` should be importable via a seed script (`scripts/seed.ts`). Parse the JavaScript `posts` array from preview.html, create records in Supabase with `status: 'seed'`.

Each seed post also has a companion HTML image template (e.g., `post-1-milestone-data.html`). Store the HTML content in Supabase Storage or as a reference path for rendering in the app.

---

## Key user flows to implement

### Flow A: AI suggests → user publishes
Dashboard → AI suggestion card → "Draft this" → 3 variations with scores → pick one → editor with live rubric → select Buffer account + time → "Schedule to Buffer"

### Flow B: Upload image → AI writes copy
Create → "Start from image" → upload/select image → AI analyzes + writes 3 variations → pick one → editor → score → schedule

### Flow C: Manual post with quality check
Create → "Write a post" → type copy → upload image/video → live rubric scores in sidebar → fix weak dimensions → schedule

### Flow D: Get variations of existing post
Library → open any post → "Get variations" → 3 alternatives → pick one → schedule as new post

---

## File structure

```
conveo-social-command-center/
├── CLAUDE.md                     # THIS FILE
├── .env.local                    # API keys (gitignored)
├── package.json
├── next.config.ts
├── tailwind.config.ts            # Conveo dark theme
├── supabase/
│   └── migrations/
│       └── 001_initial.sql       # Schema from above
├── scripts/
│   └── seed.ts                   # Import 26 seed posts
├── app/
│   ├── layout.tsx                # Sidebar + fonts
│   ├── page.tsx                  # Dashboard
│   ├── calendar/page.tsx
│   ├── create/page.tsx
│   ├── library/page.tsx
│   ├── ideas/page.tsx
│   ├── accounts/page.tsx
│   ├── analytics/page.tsx
│   ├── settings/page.tsx
│   └── api/
│       ├── ai/route.ts           # AI generation/scoring endpoint
│       └── buffer/
│           ├── profiles/route.ts
│           ├── schedule/route.ts
│           ├── publish/route.ts
│           ├── queue/route.ts
│           └── analytics/route.ts
├── components/
│   ├── sidebar.tsx               # Nav with pillar colors
│   ├── post-card.tsx             # Post preview card (dark theme)
│   ├── post-editor.tsx           # Rich text editor + rubric sidebar
│   ├── rubric-panel.tsx          # 8-dimension live scoring
│   ├── variation-picker.tsx      # Side-by-side variation comparison
│   ├── calendar-view.tsx         # Monthly calendar with pillar colors
│   ├── idea-card.tsx             # Idea bank card
│   ├── pillar-tag.tsx            # Colored pillar pill
│   ├── score-badge.tsx           # Ready/revise/rework badge
│   ├── buffer-account-card.tsx   # Profile with avatar + stats
│   └── image-picker.tsx          # Browse brand assets + upload
├── lib/
│   ├── supabase.ts               # Client + server helpers
│   ├── buffer.ts                 # Buffer API wrapper
│   ├── ai.ts                     # Anthropic API wrapper with 5 modes
│   ├── scoring.ts                # Calculate weighted total from dimension scores
│   └── types.ts                  # TypeScript types
└── public/
    └── fonts/                    # IBM Plex Serif, Inter, IBM Plex Mono
```
