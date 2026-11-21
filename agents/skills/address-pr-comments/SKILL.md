---
name: address-pr-comments
description: Systematically work through unresolved pull request review comments — especially from CodeRabbit AI and other automated reviewers — by validating each concern against the actual code, fixing real issues with atomic commits, replying on GitHub to push back on false positives, and then monitoring the PR until CodeRabbit finishes its re-review and has no further outstanding threads. Use whenever the user asks to "address the PR comments", "go through CodeRabbit feedback", "handle review comments", "respond to reviewers", "fix what the bot flagged", "deal with this PR review", or drops a PR URL and says something like "take care of this". Operates on the PR attached to the current branch; requires `gh` and `git` locally.
---

# Address PR Comments

Work through unresolved review threads on a pull request, then keep watching until CodeRabbit has re-reviewed and has no more outstanding comments. For each thread, decide whether the concern is a real issue or a false positive, then either fix it with an atomic commit or reply on GitHub explaining why it doesn't apply. Push at the end of each pass; loop until the reviewer is satisfied or a safety cap is hit.

CodeRabbit is the most common source of these comments and generates false positives frequently — so skeptical validation matters. The whole point of this skill is to be a discerning filter, not a rubber stamp.

## Workflow overview

1. **Detect** the PR on the current branch
2. **Fetch** all unresolved review threads (minus anything already in the session ledger)
3. **For each thread**: read the code, validate the concern, fix it *or* reply to dismiss
4. **Push** all new commits
5. **Monitor**: wait for CodeRabbit to re-review; when it goes quiet, re-fetch threads
6. If new threads appeared, go back to step 3. Otherwise, summarize and stop.

The rest of this document covers each step. Work through them in order.

---

## Step 1 — Detect the PR

Run:

```bash
gh pr view --json number,url,headRepositoryOwner,headRepository,headRefName,baseRefName
```

If this fails with "no pull requests found for current branch", stop and tell the user the current branch has no PR. Don't create one.

From the JSON, grab:
- `number` → PR number
- `headRepositoryOwner.login` → owner
- `headRepository.name` → repo

You'll need all three for the GraphQL query and for replies. Keep them in variables for the rest of the run.

## Step 2 — Fetch unresolved review threads

The REST `/pulls/{n}/comments` endpoint doesn't expose thread resolution state, so use GraphQL:

```bash
gh api graphql \
  -F owner="$OWNER" -F repo="$REPO" -F number="$NUMBER" \
  -f query='
    query($owner: String!, $repo: String!, $number: Int!) {
      repository(owner: $owner, name: $repo) {
        pullRequest(number: $number) {
          reviewThreads(first: 100) {
            nodes {
              id
              isResolved
              isOutdated
              path
              line
              originalLine
              comments(first: 50) {
                nodes {
                  databaseId
                  author { login }
                  body
                  path
                  line
                  createdAt
                }
              }
            }
          }
        }
      }
    }'
```

Filter client-side:
- Keep threads where `isResolved == false`
- Exclude thread `id`s that are in the session ledger (see Step 3 — the ledger starts empty on the first pass)
- Keep `isOutdated == true` threads by default — outdated doesn't mean resolved — but be extra skeptical of them, because the referenced code may have been refactored past the concern.

If the filtered set is empty on the first pass, you're done before you started — tell the user there are no unresolved threads and stop. Otherwise continue.

## Step 3 — Process each thread

Work serially, one thread at a time. Don't fan out — each thread needs judgment, fixes can touch each other, and the commits need to stay atomic.

Maintain a **session ledger** as you go: a list of thread `id`s you've already handled (fixed, dismissed, or explicitly skipped). This is the data structure that makes the monitor loop in Step 5 work correctly. Keep it in memory for the run.

For each thread:

### a) Read the full context

Don't act on a comment in isolation. Open the file at `path` and read **at least** the whole enclosing function — ideally the whole file if it's short. CodeRabbit comments frequently miss upstream validation, type guarantees, framework conventions, or existing tests that invalidate their concern.

### b) Validate whether the issue is real

Ask yourself, in this order:

1. **Does the concern still apply to the current code?** The comment might be on an earlier version of the line. Read the current code at that path, not just the diff snippet CodeRabbit quoted.
2. **Is the claimed failure mode actually reachable?** E.g., "this could be null" → trace where the value comes from. If there's a guard upstream, the null path doesn't exist.
3. **Is there a framework/language guarantee the bot missed?** E.g., Laravel's `findOrFail` throws on miss, TypeScript's discriminated unions exhaustively narrow, Rust's `match` is checked. The bot often doesn't have the full type context.
4. **Is there a test that already covers this?** If yes, the behavior is locked down — doesn't automatically make the bot wrong, but it narrows the risk.
5. **Is this a style preference vs. a real bug?** CodeRabbit sometimes suggests rewrites that are a matter of taste (extract helper, inline variable, prefer X over Y). Treat those as discretionary.

**Default to fixing when uncertain.** The cost of a small defensive change is usually lower than the cost of a missed bug, and a good fix generally improves the code regardless. Only dismiss when you're confident the concern doesn't apply.

### c) Act

**If the issue is real → fix + atomic commit.**

- Make only the change that addresses this one thread. Don't scope-creep into adjacent refactors.
- Run tests / linters locally if the repo has them configured and the change is non-trivial.
- Commit message: short imperative subject naming the concern + file; body referencing the review thread. Example:

  ```
  fix(auth): guard against null token on expired session

  Addresses review on src/auth/session.ts:42 flagging that
  `token` could be null after session expiry before the redirect.
  ```

- Don't push yet — push at the end of the pass (Step 4).
- Add the thread `id` to the session ledger.

**If the issue is not real → reply on the thread.**

Reply to the most recent comment in the thread (not a new top-level PR comment) so it stays threaded. Use the REST reply endpoint with the comment's `databaseId`:

```bash
gh api \
  --method POST \
  -H "Accept: application/vnd.github+json" \
  "/repos/$OWNER/$REPO/pulls/$NUMBER/comments/$COMMENT_DATABASE_ID/replies" \
  -f body="$REPLY_BODY"
```

Reply style:
- Lead with the conclusion: "This doesn't apply because …"
- Cite the specific code, line, or test that invalidates the concern
- Be brief and non-defensive — 2–4 sentences is plenty
- Don't apologize or hedge; state the technical reason

Example:
> The null case isn't reachable here — `session` is guaranteed non-null by the `requireAuth` middleware on line 12, which redirects before this handler runs. No change needed.

Add the thread `id` to the session ledger.

### d) If genuinely ambiguous

If you read the code carefully and still can't tell whether the concern applies, don't guess. Add the thread `id` to the ledger as **skipped**, note it for the final summary, and move on. Don't reply on GitHub — an unfounded dismissal is worse than no reply.

## Step 4 — Push

Once every thread in the current batch has been handled:

```bash
git push
```

Single push per pass. If the branch needs upstream, run `git push --set-upstream origin $(git branch --show-current)` instead. Don't force-push unless the user explicitly asked.

If this pass produced **zero commits** (everything was dismissed or skipped), skip the push — there's nothing to push. Still proceed to Step 5 so CodeRabbit gets a chance to react to the replies.

Record the push timestamp — Step 5 uses it to distinguish new CodeRabbit activity from old.

## Step 5 — Monitor CodeRabbit's re-review

After pushing, CodeRabbit typically kicks off a re-review within 30–90 seconds. It auto-resolves threads whose concerns have been addressed and opens new threads for any issues it finds in the new commits. The skill needs to wait for CodeRabbit to finish the cycle, then see what's left.

### The polling loop

```
sleep 45           # give CR time to start reviewing
last_activity_at = push_timestamp
while True:
    fetch reviewThreads (same query as Step 2)
    fetch issue comments too — CR posts walkthrough/summary there
    latest_cr_activity = max(createdAt) across threads and comments from
                         any author whose login contains "coderabbit",
                         restricted to items after push_timestamp
    if latest_cr_activity > last_activity_at:
        last_activity_at = latest_cr_activity

    quiet_for = now - last_activity_at
    unresolved = threads where isResolved == false
    new_unresolved = unresolved minus session ledger

    if new_unresolved is non-empty AND quiet_for >= 90s:
        break out — go back to Step 3 to process them
    if new_unresolved is empty AND quiet_for >= 90s AND
       we've seen at least one CR activity event after push_timestamp:
        DONE — break out of the whole loop, go to Step 6
    if total monitoring time > 20 minutes:
        bail out — tell the user CR seems unresponsive
    if no CR activity at all > 10 minutes after push:
        bail out — CR may be down or disabled on this repo
    sleep 30
```

A few clarifying points on this loop:

- **"Quiet for 90s"** means no new CR comments, threads, or reviews in the last 90 seconds. CodeRabbit reviews tend to stream over ~1–2 minutes, so 90s of silence is a reasonable "finished" signal.
- **Require at least one CR activity event after the push** before declaring done. Otherwise on a fast first poll you could see "no unresolved threads, no activity" and exit prematurely if CR hadn't even started.
- **The ledger is crucial** — dismissed threads stay `isResolved == false` until CR (or the user) resolves them, so without the ledger the skill would keep seeing "new unresolved threads" that are actually already handled.

### What counts as "CodeRabbit activity"

Any of the following, created after the push timestamp, from an author whose `login` contains `coderabbit` (covers both `coderabbitai` and `coderabbitai[bot]` variants):

- A new review thread on the PR
- A new comment on an existing thread
- A top-level issue comment (walkthrough / summary). Fetch these separately:
  ```bash
  gh api "/repos/$OWNER/$REPO/issues/$NUMBER/comments" \
    --jq '.[] | select(.user.login | contains("coderabbit")) | {created_at, id}'
  ```
- A new review submission. These show up on the PR via:
  ```bash
  gh api "/repos/$OWNER/$REPO/pulls/$NUMBER/reviews" \
    --jq '.[] | select(.user.login | contains("coderabbit")) | {submitted_at, state}'
  ```

### Cycle cap

Cap the whole push → monitor → re-process loop at **5 iterations** by default. If CodeRabbit keeps finding new issues after 5 cycles, stop and hand back to the user — that usually means the PR needs human design input, not more auto-fixes. Tell the user how many cycles ran and what's still outstanding.

### Interaction with `git` during monitoring

Don't edit files or run git during the monitor sleep — just poll. This keeps the branch stable so CR's re-review matches what was pushed. If the user has a local dev server running that rebuilds on commit, that's fine; just don't kick off anything that changes git state.

## Step 6 — Final summary

When the loop terminates (either clean exit or cap hit), summarize for the user:

- **Fixed** (N): one line per commit — short SHA + thread subject
- **Dismissed** (M): one line per reply — the thread location + one-clause reason
- **Skipped** (K): ambiguous threads you didn't act on — thread location + why
- **Cycles**: how many push/review rounds ran
- **Exit reason**: "CodeRabbit has no more outstanding comments" / "hit cycle cap" / "CR unresponsive" / etc.

Format as a readable brief, not a giant table. The user wants to see at a glance what went out.

---

## Edge cases

**Multiple comments in one thread.** Threads can have back-and-forth between CodeRabbit and humans. Read the whole thread before deciding — a later comment may supersede the original concern or add context you'd otherwise miss. Reply to the most recent comment's `databaseId` to keep threading correct.

**Threads referencing files not on the current branch.** If `path` doesn't exist on HEAD (file renamed or deleted), the thread is usually stale. Add to the ledger as skipped; don't reply.

**Author is the user.** Sometimes threads include the PR author's own comments (self-review). Process them the same way — the thread is still unresolved until someone resolves it.

**Issue comments from CodeRabbit.** CodeRabbit posts walkthroughs and review summaries as top-level issue comments, not review threads. Those are informational and shouldn't generate commits or replies from this skill — they're used only as CR activity signals in the monitor loop.

**Very large PRs.** If the first fetch returns 50+ unresolved threads, warn the user before starting and offer to scope to a file, a directory, or a specific reviewer. 50+ judgments in one shot is a lot, and batching gives the user control.

**New commits appear from elsewhere during the run.** If `git fetch` shows the remote branch has advanced (teammate pushed), pause, tell the user, and let them decide whether to rebase/merge before continuing. Don't silently force-push over someone.

**CodeRabbit re-opens the same concern.** If a thread you dismissed gets a new CR comment after your reply arguing back, treat it as a fresh decision: re-read, re-validate, and either concede-and-fix or reply again with more detail. Move the thread `id` out of the ledger temporarily while you re-process.

**No commits produced, nothing to push.** If every thread is dismissed, skip the push but still run the monitor — CR sometimes resolves threads just based on the dismissal replies.

---

## What NOT to do

- **Don't squash fixes together.** One thread → one commit keeps the review history mappable and the PR diff narrative clean.
- **Don't resolve threads programmatically.** The user asked for the GitHub side to stay clean aside from dismissal replies. CodeRabbit will resolve fixed threads on its own; dismissed threads staying open is fine.
- **Don't create issues, branches, or new PRs.** Work only on the current branch.
- **Don't blanket-reply "fixed in $SHA" on threads you fixed.** That's noise; CR will resolve them after re-review.
- **Don't rewrite history** (`commit --amend`, rebase, force-push) unless the user explicitly asks.
- **Don't tight-loop the API.** Always sleep between polls. GitHub rate-limits authenticated requests at 5000/hr, which is plenty if you sleep 30s between polls but trivial to blow through with a tight loop.
- **Don't keep looping past the cycle cap.** If CR keeps finding new issues after 5 rounds, the PR has a structural problem that needs the user.
