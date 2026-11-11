-- GhostED schema and security policies
-- Run in the Supabase SQL editor.

create table if not exists submissions (
  id           bigint generated always as identity primary key,
  company      text not null,
  role         text not null,
  outcome      text not null,
  school       text,          -- school tier, e.g. 'State School', 'Ivy / Top 10'
  gpa          text,          -- GPA band, e.g. '3.3–3.6'
  year         text,          -- class year, e.g. 'Junior'
  note         text,
  created_at   timestamptz not null default now()
);

-- Outcome is a closed set. Anything else is a bug in the client.
alter table submissions
  add constraint outcome_valid
  check (outcome in ('ghosted', 'rejected', 'interview', 'offer'));

-- Length constraints.
-- These do not prevent XSS. They cap how much any single submission can carry,
-- and they are sensible data-integrity rules on their own. A company name is
-- not two kilobytes long.
alter table submissions
  add constraint company_len check (char_length(company) <= 120),
  add constraint role_len    check (char_length(role)    <= 120),
  add constraint note_len    check (char_length(note)    <= 500);

create index if not exists submissions_company_idx on submissions (lower(company));
create index if not exists submissions_created_idx on submissions (created_at desc);

-- Row-level security.
-- The anon key is public and visible in the page source. That is how the
-- client is designed to work. What matters is what the key is permitted to do.
alter table submissions enable row level security;

-- Anyone may read.
create policy "anon can read"
  on submissions for select
  to anon
  using (true);

-- Anyone may add a row.
create policy "anon can insert"
  on submissions for insert
  to anon
  with check (true);

-- Deliberately absent: no UPDATE policy, no DELETE policy.
-- With RLS enabled, an operation with no matching policy is denied. So the
-- anon role cannot modify or remove a row it created. Anyone who manages to
-- store something malicious cannot later edit it, hide it, or wipe the table.
-- Removal is mine alone, through the service role.
