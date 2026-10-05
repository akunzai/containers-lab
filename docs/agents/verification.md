# Verification

How an agent exercises a change in this repo before it reaches review.
Human setup narrative lives in each lab's `README.md`; this file
holds only what an agent needs.

## Starting the environment

This repo is a set of independent labs, each with its own `compose.yml`.
There is no repo-wide stack. For the lab you changed:

```sh
cd <lab> && podman-compose up -d
```

<!-- drift:forge github -->
<!-- drift:entrypoint-cmd podman-compose up -d -->
<!-- drift:file mise.toml -->

It never prompts. A step needing a human aborts non-zero naming the
prerequisite — see Human prerequisites below.

**Proof it ran**: `podman-compose ps` lists every service as running, and
the lab's own check from its `README.md` answers (for example, the URL it
opens, or the service's health check). A running container is not
evidence. Run `podman-compose down` afterwards.

Entry point: each lab's `README.md` names its URL and credentials; labs
publish fixed host ports (many use `127.0.0.1:8080`).

## Checks

Tools are pinned in `mise.toml`; run `mise install` once. The tasks mirror CI
(`.github/workflows/lint.yml`); `mise tasks` lists them.

| What | Command |
| --- | --- |
| Gate: Markdown, Dockerfile and shell lint | `mise run lint` |

## Human prerequisites

Run once, by a person. The start command fails until they are done.

- [ ] Install [mise](https://mise.jdx.dev/) and run `mise install` (provides `podman-compose`, `mkcert` and the lint tools)
- [ ] Install Podman (versions in each lab's `README.md`); mise does not manage it here
- [ ] Run `mkcert -install` and generate certificates, for labs that serve TLS (see the lab's `README.md`)

## Ports

Labs publish fixed host ports and many share `8080`, so **only one lab
runs at a time per machine**; stop the previous one with
`podman-compose down` first. Labs reached by hostname or TLS cannot have
their ports offset.

<!-- drift:port 8080 -->

## Changes that need a deployed environment

None. Every lab runs locally; no pipeline deploys this repo.

## Capturing evidence

- Recording: `record-walkthrough` for a lab with a web UI — otherwise attach terminal output
- Screenshots: `playwright-cli`
- UI locale: not applicable, the labs are third-party UIs with no locale of their own; capture at the default.

**This document is where the capture rules live**, and the request
document points here rather than restating them. A capture taken on the
developer's own machine carries their account's data, username, and home
paths as readily as a shared environment does. Assert on the frame, a
marker, or fixture data, and crop or mask what the tool happened to be
showing.

For a change behind a mode switch or feature flag, confirm the far end
received the call. A healthy container and a green build are not
evidence that an integration is wired up.

## Not verified

- Any lab whose `README.md` lists a licence, credential or external service this machine lacks: record the lab and the missing item here, and verify syntax with `podman-compose config` only.

A gap you could have closed is not a gap. Run the check whose dependency
you have already seen running, and report a check you skipped as untried,
rather than recording it here as one this repo cannot run.
