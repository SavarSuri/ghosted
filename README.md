# GhostED

**Live: https://ghosted-eta.vercel.app**

The internship black box, cracked open. Students anonymously share what
actually happened when they applied — ghosted, rejected, interviewed, or
offered.

Application outcomes are opaque. You send fifty applications, hear nothing
back from most, and have no idea whether that's normal for a given company
or a signal about you. GhostED aggregates real outcomes so students can see
the actual pattern.

## Features

- Anonymous submissions — no accounts, no email, no tracking
- Live aggregate stats: submission count, ghost rate, offer rate, companies covered
- Filter the feed by outcome (ghosted / rejected / interview / offer)
- Per-company breakdowns
- Submissions tagged by school tier, GPA range, and class year for context

## Stack

Single-page vanilla HTML/CSS/JS, deployed on Vercel.

## Security

- All user-submitted content is HTML-escaped before rendering (stored XSS mitigation)
- Length caps enforced client-side and at the database layer
- Supabase RLS policies scope the public anon key to SELECT and INSERT only

## Roadmap

- Company-level ghost-rate leaderboard
- Response-time distribution per company
- Submission rate limiting
