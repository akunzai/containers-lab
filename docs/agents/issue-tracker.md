# Issue tracker: GitHub

Issues live as GitHub issues. Use the `gh` CLI for all
operations; it infers the repo when run inside a clone.

Write issue titles and descriptions in **English**.

## Conventions

- **Create**: `gh issue create --title "..." --body "..."`. Use a heredoc for multi-line bodies.
- **Read**: `gh issue view <number> --comments`
- **List**: `gh issue list --state open --json number,title,labels`
- **Comment**: `gh issue comment <number> --body "..."`
- **Label**: `gh issue edit <number> --add-label "..."`
- **Close**: `gh issue close <number>`

Use a concise descriptive title with no Conventional Commit prefix.

## Description shape

1. Open with what a product manager or a new engineer would observe: the
   symptom or the request, in plain language. Skip file paths and
   function names unless the reader cannot otherwise locate the issue.
2. Add a visual the forge renders inline — a screenshot or recording for
   a UI bug, a Mermaid diagram for a flow or state problem. In a Mermaid
   label, write a path parameter as `:id`, not `{id}`, and break lines
   with `<br/>`, not `\n`. Skip formats
   the description editor cannot render, such as a link to an external
   artifact or a raw HTML or SVG file. Upload it with the repeatable `--attach` flag
   (`gh issue create --attach './bug.png#The error state'`);
   alt text follows the path after `#`. Only when capture is genuinely
   impossible, leave `<!-- screenshot pending: <what it should show> -->`
   rather than omitting it silently.
3. Close with a collapsed technical section, so it does not push the
   human summary below the fold:

```markdown
<details>
<summary>Technical details</summary>

<everything an implementer needs — for example, suspected cause, related
code paths, repro commands, log excerpts>

</details>
```

<!-- Keep the line below even when the visual guidance above is cut
short. It is the one rule whose absence costs someone else. -->
**No personally identifiable information in any attachment**; use test
data, masking, or cropping.

## Spec issues

An issue an agent will implement from carries a different shape, because
its reader is building rather than triaging. Acceptance criteria stay
above the fold; only background goes into `<details>`.

```markdown
<one paragraph: the observable outcome, in English>

## Acceptance criteria

- [ ] <checkable statement about observable behaviour>
- [ ] <one per criterion; a reviewer can tick these without reading code>

## Scope

- In: <paths or areas>
- Out: <what this issue deliberately does not change>

## Verification

<how to prove it works, per `docs/agents/verification.md`; say here when
this needs a deployed environment rather than a local run>

<details>
<summary>Technical details</summary>

<only background — for example, related code paths, prior art, log
excerpts, open questions>

</details>
```

Use the vocabulary the project already defines for its domain, so the
issue, the tests, and the code name the same things.

An issue with unanswered open questions is not ready to implement. Say
so in the issue rather than letting an agent guess.

## Labels

This repo's own labels, read from
`gh label list --limit 100`. Both CLIs
default to 30 and report that page as the whole set, so a label past the
first page reads as absent. Do not write a label count into this file
either: the count a CLI prints is the page it fetched, a total copied out
of it reads as authoritative so nobody re-derives it, and it is wrong from
the next label onward. Nothing here invents a vocabulary; when a
label really is missing, that is a conversation with the maintainer, not
a label to create.

Check the other documents under `docs/agents/` before listing. Where one
already owns part of this vocabulary — `triage-labels.md` owns the triage
roles — point at it and list only what it does not cover. A label named in
both places has two owners and one of them goes stale on the next rename.

- **Required on every issue**: none
- **Applied when it applies**: `bug` (something is broken), `enhancement` (new lab or feature), `documentation` (README-only change), `question`

## When a skill says "publish to the issue tracker"

Create a GitHub issue.

## When a skill says "fetch the relevant ticket"

Run `gh issue view <number> --comments`.
