-- GhostED schema and security policies
-- Matches the live database. Run in the Supabase SQL editor.

create table if not exists submissions (
  id          uuid primary key default gen_random_uuid(),
  company     text not null,
  role        text not null,
  school      text not null,   -- school tier, e.g. 'State School', 'Ivy / Top 10'
  gpa         text not null,   -- GPA band, e.g. '3.3–3.6'
  year        text not null,   -- class year, e.g. 'Junior'
  outcome     text not null,   -- 'ghosted' | 'rejected' | 'interview' | 'offer'
  note        text,
  created_at  timestamp default now()
);

-- Outcome is validated in the client (VALID_OUTCOMES in index.html), not by
-- the database. A request sent straight to the REST API could store any value.

-- Length constraints.
-- These do not prevent XSS. They cap how much any single submission can carry,
-- and they are sensible data-integrity rules on their own. A company name is
-- not two kilobytes long. The client trims to the same limits before sending.
alter table submissions
  add constraint company_len check (char_length(company) <= 100),
  add constraint role_len    check (char_length(role)    <= 100),
  add constraint note_len    check (note is null or char_length(note) <= 500);

-- Row-level security.
-- The anon key is public and visible in the page source. That is how the
-- client is designed to work. What matters is what the key is permitted to do.
alter table submissions enable row level security;

-- Anyone may read.
create policy "Anyone can read"
  on submissions for select
  to anon
  using (true);

-- Anyone may add a row.
create policy "Anyone can insert"
  on submissions for insert
  to anon
  with check (true);

-- Deliberately absent: no UPDATE policy, no DELETE policy.
-- With RLS enabled, an operation with no matching policy is denied. So the
-- anon role cannot modify or remove a row it created. Anyone who manages to
-- store something malicious cannot later edit it, hide it, or wipe the table.
-- Removal is mine alone, through the service role.
