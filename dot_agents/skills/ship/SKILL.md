---
name: ship
description: Release an iOS app to TestFlight or the App Store from any repo that uses the shared fastlane lanes. Use when the user says they are ready to deploy, ship, release, cut a version, send a build to testers or TestFlight, submit to the App Store, or asks what would go out if they released now. Covers version bump choice, changelog curation, screenshots, and the submit gate.
allowed-tools: Bash, Read, Edit, Ask
---

## Purpose

Run the release **as a conversation**, not as a command the user has to remember. They release
rarely, so they will not recall the order, the flags, or which of the traps below applies. Do
the remembering for them.

**Run the commands yourself.** That is the entire point of this skill. The standing rule against
writing to remote or shared services **does not apply to iOS app releases** — the user has said
so explicitly. Uploading to TestFlight and App Store Connect is the job, so do it, do not hand
back a list of commands to paste. The single exception is `release confirm:true`, which submits
for review and needs its own explicit yes in the conversation.

Works in any repo that imports the shared lanes (`fastlane/Fastfile` containing
`import_from_git ... fastlane-lanes`): Spirit Voices / Night Vigil, FretKeys, the MOT and tax
tracker, and any future app. Nothing here is app-specific — read the state from the repo.

There is also a non-conversational front door: the `ship` script in
`~/a/personal/fastlane-lanes/ship`. Same questions, same lanes, for when the user is working
alone. If they would rather just run it, say so and stop.

## Step 1 — read the state before asking anything

Never ask a question the repo can answer. Gather all of this first, in one batch:

```bash
# Which app, which locale
sed -n 's/^app_identifier[( ]*"\([^"]*\)".*/\1/p' fastlane/Appfile | head -1
sed -n 's/^LOCALE=//p' fastlane/.env.default 2>/dev/null | head -1

# Version and build of the APP target specifically. Test and extension targets routinely lag,
# so never take the first or the lowest MARKETING_VERSION in the file.
sed -n 's/.*MARKETING_VERSION = \([^;]*\);.*/\1/p' <project>.xcodeproj/project.pbxproj | sort | uniq -c
sed -n 's/.*CURRENT_PROJECT_VERSION = \([^;]*\);.*/\1/p' <project>.xcodeproj/project.pbxproj | sort | uniq -c

# What the stores will show, and whether it fits
awk '/^## Unreleased/{f=1;next} /^## /{f=0} f' CHANGELOG.md

# Screenshot coverage, by pixel size
for f in fastlane/screenshots/<locale>/*.png; do sips -g pixelWidth -g pixelHeight "$f"; done

# Does the app ship for iPad? Decides whether iPad screenshots are required.
grep -o 'TARGETED_DEVICE_FAMILY = "[^"]*"' <project>.xcodeproj/project.pbxproj | sort -u

# Secrets: confirm the reference file exists. Do not check the variables - they are injected only
# inside `op run`, so they are correctly absent from any shell you can see. Never print values.
ls fastlane/.env.op

git status --porcelain | wc -l
git log --format='%G?' '@{upstream}..HEAD' 2>/dev/null | grep -c N
```

Then **show the user a short state block** — app, version (build), changelog size, screenshot
coverage, git state — so they can see where they are without asking.

## Step 2 — show the release notes and offer to curate

The `## Unreleased` section of `CHANGELOG.md` is the single source for both TestFlight's "What
to Test" and the App Store's "What's New". Both cap at **4000 characters**.

Show it, then judge it out loud. A changelog written during development is usually too long and
too internal for the App Store: orphaned directories, refactors and internal wording mean
nothing to a user. Offer to curate — group under headings, drop anything the user cannot
observe, keep anything embarrassing that affects them (a data-loss fix belongs in front of the
person it hit). Curate in `CHANGELOG.md` itself, never in the generated
`fastlane/metadata/<locale>/release_notes.txt`, which is regenerated from it.

`fastlane release_notes` prints exactly what the store will show without uploading anything.
Use it to check the wording before committing to a submission.

## Step 3 — ask, using the Ask tool

Ask only what state cannot decide. Usually two or three questions:

1. **Where is this going?** TestFlight internal / TestFlight external / App Store upload only /
   App Store upload and submit.
2. **Version?** Show the actual computed options from the current version, e.g. at 1.0.9 offer
   `leave it 1.0.9`, `patch 1.0.10`, `minor 1.1.0`, `major 2.0.0`. Never ask about the **build**
   number: every lane derives it from `latest_testflight_build_number + 1`, because a local
   counter drifts the moment a build happens elsewhere or an upload half-fails.
3. **Screenshots?** Only on the App Store paths — TestFlight does not use them. Recommend
   re-capture when the set is incomplete, otherwise default to using what is on disk.

Show the exact commands you are about to run before running them, so the underlying lanes stay
discoverable.

## Step 4 — run

Every lane needs the 1Password-injected secrets, so each call is wrapped. The user's `fl` shell
wrapper does this too, so `fl beta` and the line below are the same thing.

```bash
op run --env-file fastlane/.env.op -- fastlane screenshots        # only if re-capturing
op run --env-file fastlane/.env.op -- fastlane beta version:1.0.10  # omit version: to leave it
op run --env-file fastlane/.env.op -- fastlane release            # creates the version, uploads
                                                                  # notes, build and screenshots
op run --env-file fastlane/.env.op -- fastlane release confirm:true  # submits for review
op run --env-file fastlane/.env.op -- fastlane stamp_changelog    # right after submitting
```

Stop at the first failure; never run a later step over a broken earlier one.

**Submitting needs explicit consent in the same turn.** `release confirm:true` starts a review
clock that a rejection resets by days. Confirm it separately from everything else, and never
infer it from a general "ship it".

## Traps that have actually bitten

- **A lane must never prompt.** Lanes run under `op run`, which pipes stdout to mask secrets and
  so removes the TTY; every `UI.confirm` / `UI.input` / `UI.password` dies with "Could not
  retrieve response as fastlane runs in non-interactive mode". Ask the question *before* running
  fastlane — in conversation, or in `ship` — and pass the answer as a lane option. Never propose
  moving secrets onto disk to regain a TTY: the question simply belongs further out.
- **Do not gate on `op whoami`.** It reports "account is not signed in" on a machine where
  `op run` works perfectly through the desktop app integration, so checking it refuses a working
  setup. Let `op run` prompt for biometrics and report its own failures. `op` also costs ~1.8s
  per invocation even when unlocked, which is why per-directory templating is not viable.
- **Builds and versions are different things in App Store Connect.** Uploading to TestFlight
  creates a *build*, never a *version*. Nothing — screenshots included — can attach until a
  version exists, which `fastlane release` creates.
- **"What's New" is required for every locale on the listing.** Missing one fails submission with
  `appStoreVersions ... is not in valid state` plus `You must provide a value for the attribute
  'whatsNew'` — and the error names only the version, never the locale, so it looks mysterious.
  Check `fastlane/metadata/*/` against the locales the listing actually has; the App Store's
  primary language is often `en-US` even for a UK developer. `LOCALES` in `.env.default` lists
  them, and `deliver` uploads every locale folder it finds on disk.
- **Write the non-primary locales yourself, and translate the idiom, not just the spelling.**
  `CHANGELOG.md` is the primary. For `en-US` from `en-GB` that meant `labelled`→`labeled`,
  `Behaviour`→`Behavior`, but also `straight away`→`right away`, `part way`→`partway`,
  `afterwards`→`afterward` and `carrying on recording`→`continuing to record`. Never use a
  regex rule for this: a blanket `-ise`→`-ize` gives "advertize" and "promize". `stage_release_notes`
  refuses to ship a translation that is missing or older than `CHANGELOG.md`.
- **deliver's screenshot upload reports failure twice over, and neither is fatal.** First it
  uploads everything then claims files are "missing on App Store Connect" and retries — that is
  Apple's checksum check lagging its own ingest, and the second pass completes. Separately it can
  fall into `Waiting for screenshots to appear before uploading ... Server error got 500`, which
  does **not** recover and will spin for the full hour of `screenshot_processing_timeout`. Kill
  it, then check Media Manager: the images are usually already there and correct. Do not re-run
  the upload blind, which is how duplicates accumulate. Submit with `confirm:true`, which skips
  screenshots and metadata entirely.
- **Do not create the App Store version by hand first.** `deliver` calls `ensure_version!`,
  which *renames* an existing editable version instead of creating a new one, so a half-made
  draft turns into a confusing rename.
- **Screenshots are matched to a device by pixel size,** not filename or folder. 1320×2868 or
  1290×2796 is the 6.9" iPhone slot; 2064×2752 or 2048×2732 is the 13" iPad. If the app has
  `TARGETED_DEVICE_FAMILY = "1,2"`, iPad screenshots are **required** and their absence blocks
  submission. Uploading into the wrong slot in Media Manager gives a dimensions error naming
  the sizes that slot wants — check which slot before believing the images are wrong.
- **A stop is not an error.** Never end a successful lane with `UI.user_error!`; it prints
  "fastlane finished with errors" over a run where nothing went wrong. Use `UI.success` plus
  `UI.important` and let the lane end.
- **`increment_version_number` unifies all targets.** Mismatched `MARKETING_VERSION` across app
  and extensions is worth flagging before a build, not after a rejection.

## Repository hygiene

- Never commit to `main`, `master` or `trunk`. Branch from `origin/HEAD`.
- Agent commits are unsigned by design (`-c commit.gpgsign=false`). The user runs `gsign` to
  rebase and sign before pushing, which rewrites hashes — so a changed hash between two of your
  own checks is expected, not a symptom. Tell them when commits are waiting for it.
- The shared lanes live in `~/a/personal/fastlane-lanes` and are imported over git. A lane fix
  must be committed **and pushed** there before any repo will pick it up: `import_from_git`
  clones the remote, not the local working copy. It caches in `~/.fastlane`, so `rm -rf
  ~/.fastlane` forces a refresh.

## Before recommending a submission

The user's apps are field instruments; a plausible build is not a working one. If the changes
in this release have never been exercised on a real device, say so plainly and name the specific
checks worth doing first. Submitting is the one step that is expensive to undo.
