# Stored XSS in the submission handler

A write-up of a vulnerability I introduced, found in my own code, and fixed.

**Class:** Stored (persistent) cross-site scripting
**Component:** Submission rendering
**Status:** Fixed
**Found by:** Me, auditing my own source

---

## Why I'm writing this up

I built GhostED first and read about web security second. When I went back through my own code looking for problems, this is what I found. Writing it down is how I make sure I actually understand it rather than just having patched it.

## The bug

Submissions are user-controlled. A student enters a company name, a role, and a short note. Those values go to Supabase, and on page load every stored submission is read back and rendered into the results list.

The rendering step did this:

```javascript
// vulnerable
card.innerHTML = `
  <div class="company">${row.company}</div>
  <div class="role">${row.role}</div>
  <div class="note">${row.note}</div>
`;
```

`innerHTML` does not insert text. It parses its input as HTML and builds real DOM nodes from it. Everything between those backticks that came from a user is markup as far as the browser is concerned.

## Why it's stored and not reflected

This is the part that makes it serious.

A **reflected** XSS needs the victim to click a crafted link. The payload lives in the URL, it runs once, and you have to get the target to follow it.

This one is **stored**. The payload goes into PostgreSQL. It sits there. Every single person who loads the results page afterward pulls it down and executes it, with no link to click and nothing suspicious to notice. One submission, every visitor, indefinitely.

## Proof

A company name of:

```html
<img src=x onerror="alert(document.domain)">
```

The image fails to load, because `x` is not an image. `onerror` fires. The handler runs with the page's origin.

`alert()` is the harmless version. The same position runs `fetch()` against an attacker's server, reads anything in the DOM, or rewrites the page to ask for credentials. The payload is whatever fits in a text field.

## The fix, layer by layer

### 1. Output encoding

The actual fix. Stop parsing user input as markup.

```javascript
function esc(s) {
  return String(s ?? '').replace(/[&<>"']/g, c => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#39;'
  }[c]));
}

card.innerHTML = `
  <div class="company">${esc(row.company)}</div>
  <div class="role">${esc(row.role)}</div>
  <div class="note">${esc(row.note)}</div>
`;
```

`<img src=x onerror=...>` now renders as the literal characters a user typed, which is what a company name field should do.

Encoding at **output**, not at input. Input filtering is the wrong place for this: the same stored value could later be rendered into HTML, a URL, or an attribute, and each of those needs different escaping. Encode where you know the context.

### 2. Database length constraints

```sql
ALTER TABLE submissions
  ADD CONSTRAINT company_len CHECK (char_length(company) <= 120),
  ADD CONSTRAINT role_len    CHECK (char_length(role)    <= 120),
  ADD CONSTRAINT note_len    CHECK (char_length(note)    <= 500);
```

This does not stop XSS. A short payload still fits. What it does is cap the blast radius of anything else that goes wrong, and it is a reasonable data-integrity rule regardless of security. Company names are not two kilobytes long.

### 3. Verified row-level security

The frontend holds a public anon key. Anyone can read it out of the page source. So the question is not whether an attacker has the key, it's what the key is permitted to do.

I checked the policies and confirmed the anon role has `SELECT` and `INSERT` only, with no `UPDATE` and no `DELETE`.

That means an attacker who stores a payload cannot go back and edit it, cannot cover their tracks, and cannot wipe the table. Bad submissions are append-only and removable by me.

## What I took from it

**`innerHTML` is an HTML parser.** The template literal reads like string interpolation, so it's easy to forget that the browser treats the result as markup. `textContent` would have been safe here and I should have reached for it first.

**Stored beats reflected for an attacker, by a lot.** No delivery, no social engineering, persistent across every visitor.

**Defense in depth is not three fixes for one bug.** It's accepting that the first control will eventually fail and deciding in advance what happens next. Encoding is the fix. The constraint and the RLS scope are what's left standing if the encoding is bypassed or if I introduce another sink later.

**Reading my own code adversarially found something that writing it did not.** Different mindset, same file.

## References

- [OWASP Cross Site Scripting Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Cross_Site_Scripting_Prevention_Cheat_Sheet.html)
- [MDN: Element.innerHTML security considerations](https://developer.mozilla.org/en-US/docs/Web/API/Element/innerHTML#security_considerations)
- [PortSwigger Web Security Academy: Stored XSS](https://portswigger.net/web-security/cross-site-scripting/stored)
- [Supabase Row Level Security](https://supabase.com/docs/guides/database/postgres/row-level-security)
