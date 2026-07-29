# Global Rules

## Version Control: Use Git (not Jujutsu)

- **I've switched back to git (July 2026).** Use git in every repo, even ones that still contain a `.jj` directory. Ignore any older memories or notes that say to prefer jj.
- **Never commit to `main`, `master` or `trunk`.** Branch from `origin/HEAD` with a descriptive name before committing.
- **Make logically atomic commits.** Each commit should represent one logical unit of work — a single bugfix, a single feature addition, a single refactor. Don't bundle unrelated changes together; split them into separate commits.
- **Prefer amending over fixup commits.** For follow-up fixes to work on the current branch, amend the existing commit and update its message rather than stacking small follow-up commits.
- **Write good messages.** Clear and concise, with conventional commit prefixes (fix:, feat:, refactor:, chore:) when appropriate. Use real newlines, not literal `\n`; pass multiline messages through `git commit -F -` with a heredoc.
- **Inspect `git diff` before committing** and keep the diff focused.
- **Never push to remotes.** Never run `git push` of any kind, including force pushes. The user always handles pushing themselves.
- **Ask before destructive operations.** Always confirm before `git reset --hard`, `git clean`, `git rebase` onto published history, branch deletion, or anything else that rewrites or discards work.

## Code Search & Analysis: Use Serena

- **Prefer Serena's symbolic tools** for exploring and understanding codebases. Use `find_symbol`, `get_symbols_overview`, and `find_referencing_symbols` instead of reading entire files when possible.
- **Use Serena for code navigation** — finding definitions, references, and understanding relationships between symbols.
- **Only fall back to file-based reads** when working with non-code files or when symbol names are unknown and pattern search is needed.

## API Documentation: Use Context7

- **Always check Context7 for up-to-date docs** before making code changes that involve library or framework APIs. Use `resolve-library-id` then `query-docs` to get current documentation.
- **Don't rely on training data for API details** — libraries change frequently. Context7 provides the latest docs and examples.

## Frontend Work: Use Frontend Design Skill

- **Always use the `frontend-design` skill** when building or modifying UI components, web pages, or frontend applications.
- This produces distinctive, production-grade interfaces with high design quality — avoiding generic AI aesthetics.

## Writing Style: No AI Tropes

- **Never use patterns that flag output as AI-generated.** This applies to all writing: lyrics, prose, comments, documentation, commit messages, everything.
- Avoid: em dashes, purple prose, "moreover", "furthermore", "delve", "tapestry", "landscape", "multifaceted", overly neat parallel structures, cliche metaphors, filler transitions.
- Write like a real person. Be direct, conversational, specific. If a phrase sounds like it came from a language model, cut it or rewrite it.

## Code Comments

- **Only comment what the code can't say itself.** If a comment restates what the code plainly does, delete it. Good comments explain *why* — a non-obvious constraint, a deliberate tradeoff, a gotcha, the reason for an unusual choice.
- **Keep them short and to the point.** One line where one line does. No preamble, no restating the method name, no narrating the happy path.
- **Don't write rotting comments.** Avoid references to specific callers, line numbers, or other code that will drift out of date. Describe the invariant, not the current callsites.
- Prefer making the code self-explanatory (clear names, small functions) over adding a comment to explain unclear code.

## Optimisations

- Before editing any file, read it first. Before modifying a function, grep for all callers. Research before you edit.

## Never Install Software Without Consent

- **Never install any software without my explicit consent.** Includes Homebrew packages/casks (`brew install`), language packages (gem, npm, pip, cargo, etc.), system tools, browsers, drivers — anything writing to the system outside the project working tree.
- **Ask first, every time.** Say what you want to install and why, and wait for a yes. Approval for one install does not extend to others.

## Never Write To Remote Services

- **Never write to remote or shared services** — remote datastores, staging/dev APIs, third-party services. This includes seeding test data. Only local instances (local Postgres, local Redis, local dev servers) may be written to.
- The Nevaya datastore (`DATASTORE_URL`) is always remote and always read-only from this machine, even in development.
