# Claude command center

One place to run Claude across many repos. You talk to **hq**, which runs on Sonnet and does no work itself. It classifies each task and dispatches it to a **worker**, a background session running inside the target repo on the most cost-effective model for the job.

`plan.md` has the full design, including why each part works the way it does.

## Requirements

Linux or macOS, with `claude`, `git` 2.31 or later, `bash` and `jq`. Repos on a git host also need that host's CLI, such as `gh` or `glab`, for PR and CI work.

## Set up a machine

```
claude --agent setup
/bootstrap
```

Bootstrap asks for your workspace folder, the repos to register, their restrictions, and your cloud and production details. Everything it generates goes in `local/`, which stays out of git, so each machine has its own setup.

## Daily use

Talk to hq by running `claude` in this repo. Watch workers by running `claude agents` in another terminal.

| Key in `claude agents` | Action |
|---|---|
| `↑` / `↓` | Select an agent |
| `Space` | Peek at its status, question or result |
| `Enter` or `→` | Attach |
| `←` on an empty prompt, or `/exit` | Detach |

**Three things to watch out for in `claude agents`:**

- **Deleting can lose work.** `Ctrl+X` twice removes a session's worktree, including uncommitted changes. `claude rm` keeps it.
- **`Esc` while attached interrupts the agent.** It doesn't leave the session.
- **The input box skips `fleet`.** Sessions started from it don't get the rules in `policy/`, so they may not get the push and merge blocks. Start workers through hq.

## Add a repo

1. Clone it into your workspace folder.
2. Run `claude` in it once, and accept the trust prompt.
3. In this repo, run `claude --agent setup`, then `/bootstrap <repo>`.

To update cloud and production details, use `/bootstrap --environments`.

## What workers can and can't do

Workers run in auto mode, in their own worktree, and don't ask questions.

| Can, without asking | Can't, in any repo |
|---|---|
| Commit and push their own branch | Push to `main` or `master` |
| Open, update and rebase PRs, using `--force-with-lease` | Merge or approve a PR |
| Monitor CI and fix failures | Clone repos |
| | Use claude.ai connectors, unless the repo opts in |
| | Use cloud tools, unless the repo is given access |

**Merging is your job.** hq tells you when a PR is ready.

**These rules are not a complete guarantee.** They run on your machine, as your user. A script could get around the merge rule, and `--no-verify` inside a script could get around the push rule. Turn on branch protection and required approvals on your git host, and give workers limited cloud roles.

## Cost and cleanup

`policy/routing.json` maps each class of task to a model and effort. Failed tasks move up one rung, with at most two retries.

If it's been over 2 hours since the last cleanup, hq spawns a small Haiku agent the next time you message it. It removes finished sessions, worktrees and local branches that `fleet` created, and only when everything in them is saved. It never changes anything on a remote. Anything with unsaved work is kept and reported, and only you can discard it, by running this in a real terminal:

```
bin/fleet clean --discard <task-id>
```

## Add skills for workers

Add `worker-plugin/skills/<name>/SKILL.md`. Every worker dispatched after that can use it as `/fleet:<name>`. See `worker-plugin/skills/README.md`.

## Tests

```
tests/run            # free: no model, uses a stub in place of claude
tests/run-model      # uses real quota, and asks you to confirm first
```

Run both on Linux and on macOS.
