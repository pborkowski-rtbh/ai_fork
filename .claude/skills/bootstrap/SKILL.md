---
name: bootstrap
description: Interview the user and generate this machine's command center config in local/. Run with no argument for full setup, a repo name to add or update one repo, or --environments for cloud and production details only.
disable-model-invocation: true
argument-hint: "[repo | --environments]"
---

Set up the command center on this machine by asking the user. This skill knows nothing about any specific machine, repo, stack or provider, and must not assume any. What you see in folders is a starting point for questions, never a default answer.

Arguments: `$ARGUMENTS`

If you have no Write tool, you were started as hq. Stop and tell the user to run `claude --agent setup`, then `/bootstrap`.

## Ground rules

- Look before asking, and skip questions the scan already answered. Confirm anything a guess would make dangerous.
- Use `AskUserQuestion`, in small batches.
- Metadata only. Never read the contents of `.env` files, `~/.aws/credentials`, anything under `~/.ssh`, or any other secret. Names are fine.
- Make no calls to cloud providers.
- If an answer looks like a key, token or password, refuse to save it anywhere, and ask where it's stored instead.
- Never change tracked files in target repos. The only additions allowed are `.git/info/exclude` entries and, if the user chooses, an untracked `.worktreeinclude`.
- Don't change host settings such as branch protection. Report on them only.
- Don't edit `~/.claude/settings.json` or a user-level `CLAUDE.md` without showing the exact change and getting approval.
- Write nothing until step 8 is approved. Existing entries in `local/` are shown and updated, never overwritten blindly.

## Which steps to run

- No argument: all steps.
- A repo name: step 1, then steps 4 to 6 for that repo only, then 8 and 9.
- `--environments`: step 1, then only the cloud questions in step 3, then 8 and 9.

## 1. Check the machine

Run `bin/fleet doctor`. If something required is missing, stop and give the install hint for this OS.

Detect `aws`, `az`, `gcloud` and `kubectl`. If present, list names only, from local config: `aws configure list-profiles`, `az account list --query '[].name' -o tsv`, `gcloud config configurations list --format='value(name)'`, `kubectl config get-contexts -o name`. If a command would reach the network or needs a login, skip it.

## 2. Ask for the workspace folder

Ask which folder holds, or will hold, the repos. Offer no default path. If it doesn't exist, confirm and create it. This repo can be anywhere, inside or outside that folder.

## 3. Global questions

- hq's effort level, if they want something other than medium.
- Confirm auto mode works here: it's the only mode workers use, and it isn't a preference. If an organization has disabled it, stop and explain, since there's no fallback.
- Check that Opus, Sonnet and Haiku are all available on this account. The routing ladder needs them. If one is missing, stop and tell the user.
- How to be alerted when a worker needs approval, offering what this OS supports, such as `notify-send` on Linux or `osascript` on macOS. Remind them that `claude agents` also notifies while it's open.
- Do they use AWS, Azure, Google Cloud or another platform? Show what was detected and have them confirm, since a config on this machine may be stale or unrelated.
- For each production environment, and any others worth recording, collect:
  - Name, and whether it's production.
  - Provider, and the account, project or subscription, plus region.
  - What runs there, and why it's there.
  - Which repos deploy to it, and how.
  - What would be dangerous there, and how to roll back.
  - Where its secrets live, by name only.
  Warn that these details reach worker prompts and transcripts, so anything that must stay out of those shouldn't be recorded.
- Offer to add production details to `autoMode.environment` in user settings, which helps the auto mode classifier but applies to every repo. Show the exact text first, and only add it with approval.

## 4. Scan the workspace, metadata only

For each folder, collect: whether it's a git repo, its remote and host, default branch, last commit date, stack markers such as `package.json` or `pyproject.toml`, whether it has `CLAUDE.md` or `.claude/`, and the names of env files.

## 5. Choose repos

- If the workspace has folders, have the user pick which to register, in small batches. Show the scan results and flag likely duplicates, such as folders with the same remote.
- If it's empty, or the argument is a repo that isn't there yet, offer to clone from URLs the user provides.
- For each chosen repo, check that it's trusted. If it isn't, tell the user to run `claude` there once and accept the prompt, because workers can't start until then. Never edit trust settings yourself.

## 6. Per-repo questions

Skip anything the scan answered.

- Goal and current priority.
- What must never happen, and sensitive paths. These become `deny` rules.
- What's dangerous enough to ask first. These become `ask` rules.
- Whether it touches production, deployments or real money, and which recorded environments it relates to.
- What cloud access workers should have: `none` (the default), a named profile, or a production-capable profile. Recommend a limited role, and add `ask` rules for commands that change things if they choose production.
- Workers can push branches, open and rebase PRs and monitor CI by default. Should this repo be stricter? Don't ask about pushes to `main` or `master`, merges or approvals, since those are always refused.
- If the default branch has another name, such as `develop`: protect it the same way?
- May workers use credentials in `.env`-style files: allow or deny?
- A minimum rung for this repo. No minimum is the default.
- What command sets up a fresh worktree, such as installing dependencies? Suggest one from the scan and have them confirm.
- Which commands check that a change works, such as tests, lint and build, and how long can they take? Suggest them from the scan and have them confirm.
- Do those commands need any gitignored files in the worktree? Copy secrets only if they explicitly choose that.
- Does this repo need any claude.ai connectors or user-level MCP servers? None is the default for connectors. List what exists, and add deny rules for anything a repo that opts in shouldn't have.
- Non-git folders: read-only (the default) or `git init`.

Check branch protection and required approvals on the host where you can, read-only, using the repo's host CLI. Tell the user if they're missing or can't be checked, because they're the only real guarantee behind the push and merge rules.

## 7. Check user-level settings

`~/.claude/settings.json` and a user-level `CLAUDE.md` apply to every worker in every repo. Look for rules or text written for one specific project. This matters most for `autoMode` entries, because text describing one project as trusted reaches the classifier for all of them.

This check is about those files and the registered repos, not about the project they name. That project may be outside the workspace, so never ask about it or treat it as part of this setup. Raise something only if it could affect a registered repo, and explain it that way first, for example: "Your user settings tell auto mode that only one other project is trusted, which could block pushes from the repos you registered." Say that this effect is possible rather than confirmed. Then ask once whether to leave it or change it. Leaving it is a fine answer, so list it once in the final summary as a known risk and don't bring it up again.

## 8. Confirm

Show a summary of every file to be written, with the exact `ask` and `deny` rules for each repo, and write only after approval.

## 9. Write and finish

Create `local/fleet.json`:

```json
{ "workspace": "<absolute path>", "alert": "<method>", "cleanup_interval_hours": 2 }
```

For each repo, create `local/repos/<repo>.md` from `templates/repo.md`, and `local/repos/<repo>.settings.json` with its permission rules. Write environments to `local/environments.md`, with one `## <name>` section each, matching the `environment:` values in repo entries.

In each git repo, add `.claude/worktrees/` and `.worktreeinclude` to `.git/info/exclude`, without changing any tracked file.

Add `"agent": "hq"` to this repo's `.claude/settings.local.json` as the last step, keeping anything else in that file.

Run `bin/fleet doctor`, then tell the user how to start: run `claude` in this repo to talk to hq, and `claude agents` in another terminal to watch workers.
