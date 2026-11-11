# GhostED

An anonymous internship outcome tracker. Students report what actually happened to their applications, and the aggregate becomes something you can't get from a company's careers page.

**Live:** [ghosted-eta.vercel.app](https://ghosted-eta.vercel.app)

---

## The problem

Applying to internships is an information vacuum. You send an application and nothing comes back. You don't know if the posting was real, if the company ever hired from your school, or if everyone gets ghosted or just you. Companies have no incentive to publish that, and the people who know are scattered across group chats.

GhostED collects the outcome, not the complaint. Four categories: ghosted, rejected, interviewed, offer. Each submission is tagged by school tier, GPA band, and class year, so the aggregate means something.

## What it does

- Anonymous submission. No account, no email, nothing that identifies the submitter.
- Four live metrics computed across all submissions: total volume, ghost rate, offer rate, companies covered.
- Per-company breakdowns, filterable.
- Everything recomputes on submit.

## Stack

| Layer | What |
|---|---|
| Frontend | Vanilla JavaScript, single page, no framework |
| Backend | Supabase (PostgreSQL) via its REST API |
| Hosting | Vercel |
| Auth | None by design. Anonymous key, locked down at the database. |

No framework was a deliberate choice. The app is one page and a handful of queries, and I wanted to understand what was happening at every layer rather than inherit it.

## The security part

I audited my own source and found a **stored cross-site scripting vulnerability** in the submission handler. Every user-supplied field was being written into the DOM with `innerHTML`, which parses its input as live markup. A company name containing an `<img onerror=...>` payload would execute in the browser of every visitor who loaded the page afterward.

I wrote it up properly: **[docs/stored-xss.md](docs/stored-xss.md)**

Short version of the fix, three layers:

1. **Output encoding.** All rendered values HTML-escaped at the render step. Fixes the bug.
2. **Database length constraints.** Three columns bounded, so a payload large enough to matter can't be stored in the first place.
3. **Row-level security verified.** Confirmed the public anon key is scoped to `SELECT` and `INSERT` only. No `UPDATE`, no `DELETE`. An attacker who gets a payload in can't go back and modify or remove records.

Layer one fixes it. Layers two and three exist because any single control can be bypassed, and I'd rather the failure of one not be the failure of all of them.

## Running it locally

```bash
git clone https://github.com/SavarSuri/ghosted
cd ghosted
```

Create your own Supabase project and run [docs/schema.sql](docs/schema.sql) in its SQL editor. Then set `SUPABASE_URL` and `SUPABASE_KEY` near the top of the script in `index.html` to your project's URL and anon key, and serve the directory with anything static:

```bash
python3 -m http.server 8000
```

Schema and RLS policies are in [docs/schema.sql](docs/schema.sql).

## Status

Live and accepting submissions. The dataset is small, which is the honest state of it.

## Security

Found something? See [SECURITY.md](SECURITY.md).

## License

MIT
