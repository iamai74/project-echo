---
name: execute-md-task
description: Reads and executes implementation tasks from Markdown files.
---

# Execute Markdown Task

Execute the implementation task described in the Markdown file provided by the user.

## Workflow

### 1. Read the task
- Read the entire Markdown file.
- Understand its objectives, requirements, constraints, and acceptance criteria.
- Identify ambiguities or conflicting requirements. Ask the user if clarification is necessary.

### 2. Inspect the project
- Read applicable `AGENTS.md` / `Agents.md` instructions.
- Inspect relevant parts of the codebase.
- Identify existing implementations, architectural patterns, and conventions.
- Reuse existing components instead of introducing unnecessary abstractions.

### 3. Plan
- Determine which files need to be created or modified.
- Identify dependencies and potential impact on existing functionality.
- Prepare a concise implementation plan.

### 4. Implement
- Implement all requirements from the task.
- Follow project instructions and existing conventions.
- Keep changes within the task scope.
- Avoid unrelated refactoring and unnecessary dependencies.
- Do not modify the original task file unless explicitly requested.

### 5. Validate
- Run relevant tests, linters, and static analysis.
- Verify the acceptance criteria.
- Review the final diff.
- Fix issues introduced by the implementation.
- Never claim successful validation if it was not performed.

### 6. Report
Provide a concise completion report:

- **Implemented:** What was done.
- **Files changed:** Created, modified, or deleted files.
- **Validation:** Tests and checks performed, with results.
- **Remaining issues:** Limitations or incomplete requirements.

Explicitly state whether all acceptance criteria have been satisfied.

## Rules

- The task Markdown defines WHAT needs to be done.
- Project instructions define HOW the project should be developed.
- The existing codebase is the source of truth for the current implementation.
- Do not invent requirements or silently ignore them.
- Do not stop after planning: execute the task unless clarification is required.
- If a requirement cannot be implemented, explain why. 
