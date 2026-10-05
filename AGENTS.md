# Containers Lab Developer Guidelines

This is a collection of Docker Compose / Dockerfile examples for various container development and application scenarios; each subdirectory is self-contained with its own `README.md`.

## Commands

- CI (`.github/workflows/lint.yml`) lints `**/*.md` (markdownlint-cli2), Dockerfiles (hadolint) and shell scripts (shellcheck).

## Pointers

- When filing or triaging an issue, read `docs/agents/issue-tracker.md`
- When opening a pull request, read `docs/agents/pull-request.md`
- Before running or reporting verification, read `docs/agents/verification.md`
- Triage labels (default five-label vocabulary): `docs/agents/triage-labels.md`
- Domain docs (single-context `GLOSSARY.md` + `docs/adr/`): `docs/agents/domain.md`

## Prevent Recurrence

- **Candidate**: Name who hits this again, in which file, on what change. No such scenario, nothing to propose.
- **Promote**: Offer the first tier that reaches them and only that one, pending confirmation — enforce it (assert/type/test) with its size quoted, else a comment at that site, else an agent-facing doc (`docs/agents/<topic>.md`, else `docs/agents/lessons-learned.md`) with one backtick-path line under Pointers and one sentence on why the tiers above cannot hold it.
- **Prune**: When adding to a file, audit the rest of it in the same pass. Drop entries once stale (obsolete version, now enforced, duplicated, or a transcript) — not by a fixed count.
