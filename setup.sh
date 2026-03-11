#!/bin/bash
# Conveo Social Command Center — Quick Setup
# Run this ONCE to scaffold the Next.js project with all dependencies.

set -e

echo "🚀 Setting up Conveo Social Command Center..."

# Create Next.js project
npx create-next-app@latest social-command-center \
  --typescript \
  --tailwind \
  --eslint \
  --app \
  --src-dir \
  --import-alias "@/*" \
  --no-turbopack

cd social-command-center

# Core dependencies
npm install @supabase/supabase-js @supabase/ssr
npm install @anthropic-ai/sdk
npm install @tanstack/react-query
npm install date-fns
npm install lucide-react
npm install clsx tailwind-merge class-variance-authority
npm install zod

# shadcn/ui init (uses defaults)
npx shadcn@latest init -d

# Install shadcn components we need
npx shadcn@latest add button card dialog dropdown-menu input label select separator sheet sidebar tabs textarea toast badge calendar popover command scroll-area avatar tooltip progress

# Google Fonts (IBM Plex Serif, IBM Plex Mono — Inter comes from Next.js)
npm install @fontsource/ibm-plex-serif @fontsource/ibm-plex-mono

# Create directory structure
mkdir -p src/app/\(dashboard\)/{calendar,create,library,ideas,accounts,analytics,settings}
mkdir -p src/components/{posts,editor,rubric,calendar,analytics,layout,ui}
mkdir -p src/lib/{supabase,buffer,ai,utils}
mkdir -p src/hooks
mkdir -p src/types
mkdir -p public/seed-images

# Copy CLAUDE.md into the new project root so Claude Code can find it
cp ../CLAUDE.md ./CLAUDE.md

echo ""
echo "✅ Setup complete! Directory: social-command-center/"
echo ""
echo "Next steps:"
echo "  1. Create a .env.local with your API keys:"
echo "     NEXT_PUBLIC_SUPABASE_URL=..."
echo "     NEXT_PUBLIC_SUPABASE_ANON_KEY=..."
echo "     SUPABASE_SERVICE_ROLE_KEY=..."
echo "     ANTHROPIC_API_KEY=..."
echo "     BUFFER_ACCESS_TOKEN=..."
echo ""
echo "  2. Run the Supabase SQL schema from CLAUDE.md in your Supabase dashboard"
echo ""
echo "  3. Open Claude Code in this directory and paste the starter prompt"
