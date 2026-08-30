---
name: commit
description: Write git commits for this repo using Conventional Commits, always in English. Use when the user asks to commit, stage changes, or split work into commits — including when they ask in Portuguese.
---

# Commit

Commit messages in this repository follow [Conventional Commits](https://www.conventionalcommits.org)
and are **always written in English**, even when the conversation is in
Portuguese. The code comments and the README are pt-BR; the git history is not.

## Format

```
type(scope): subject

Body explaining why, wrapped at 72 columns.

Footer
```

### Type

| Type | Use for |
|---|---|
| `feat` | New user-facing capability |
| `fix` | Bug fix |
| `refactor` | Restructuring with no behaviour change |
| `perf` | Change made for speed or memory |
| `test` | Adding or correcting tests |
| `docs` | Documentation only |
| `style` | Formatting only — no logic touched |
| `build` | Build targets, Gradle, Xcode, Vercel, web shell |
| `chore` | Tooling, dependencies, config, housekeeping |
| `revert` | Reverting a previous commit |

### Scope

Optional, but include it when the change is confined to one area. Scopes in
use — reuse an existing one before inventing another:

`core` · `data` · `app` · `ui` · `auth` · `trips` · `expenses` ·
`itinerary` · `dashboard` · `board` · `firebase` · `build` · `deps`

### Subject

- Imperative mood: `add`, `fix`, `remove` — not `added`, `adds`.
- Lowercase first word, no trailing period.
- 72 characters or fewer, including the type and scope.
- Say what changed for the user, not which file you edited.

```
feat(expenses): derive installment value from total and split
fix(itinerary): stop clipping the floating label in form sheets
```

Not:

```
feat: updates                          # says nothing
fix(expenses): fixed bill_form_sheet.dart   # names a file, past tense
Feat(ui): Add card.                    # capitals, trailing period
```

## Body

Skip it when the subject is the whole story. Write one when the change has a
reason that is not visible in the diff — and then explain **why**, not what.
The diff already shows what.

Worth a body: a workaround for an SDK bug, a constraint that forced the
design, a rounding rule, a security-rule subtlety, a regression being fixed.

```
fix(firebase): split delete from create and update in the rules

On a delete, request.resource is null, so a rule that inspects the
document fields denies the operation silently. Deleting a bill appeared
to succeed in the UI and left the document in place.
```

## Footers

Breaking changes get a `BREAKING CHANGE:` footer describing the migration,
and the type carries a `!` — `feat(data)!: ...`.

End every commit message with:

```
Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>
```

## Working rules

**Commit only when asked.** Never commit or push as a side effect of finishing
some other task.

**One concern per commit.** Read `git status` and `git diff` first, group the
changes by concern, and stage each group with explicit paths. Prefer several
readable commits over one bundle. Never reach for `git add -A` without
checking what it would take.

**Never commit credentials.** These are gitignored and must stay that way:

- `lib/firebase_options.dart`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

Before pushing anything new, confirm nothing matching `AIzaSy`, the project
id, or the sender id entered the history:

```bash
git grep -nIE 'AIzaSy[A-Za-z0-9_-]{20}|24120516223|vacation-itinerary-5d307' $(git rev-list --all)
```

**Green before committing.** `flutter analyze` clean and `flutter test`
passing. If something fails and the user still wants the commit, say so in the
message rather than leaving it silent.

**Branch.** If on `main` and the change is not trivial, create a branch first.
Push only when the user asks.
