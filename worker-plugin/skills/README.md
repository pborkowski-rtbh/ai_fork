# Worker skills

Add a skill as `<skill-name>/SKILL.md` in this folder. Every worker dispatched after that can use it as `/fleet:<skill-name>`.

- Keep skills generic. A skill for one repo belongs in that repo's own `.claude/skills/`.
- Keep descriptions short, because each skill Claude can invoke on its own adds to every worker's context on every turn. Mark rarely used skills `disable-model-invocation: true`, though workers then won't invoke those on their own.
- A skill is an instruction a worker can ignore. Anything that must always hold belongs in `policy/`.
