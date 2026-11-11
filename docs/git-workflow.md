# Git commands for each member

Run the blocks from the repository root unless a block starts with `git clone`. If a command fails, fix it before continuing. Each person uses their own GitHub account and a verified email or GitHub noreply email for commits.

## Member 1 — Publish the starter

Run this once in the existing project clone. The starter includes the instruction-path RTL, integration shell, testbench and handoff docs.

```sh
git status --short --branch
git remote -v
git var GIT_AUTHOR_IDENT
make -B test-instruction
git add .gitignore Makefile README.md docs rtl testbench
git diff --cached --check
git diff --cached --stat
git commit -m "Set up Phase I and implement the instruction path"
git push -u origin main
```

Check that the files appear on GitHub. Invite the other four members in repository settings and have them accept. For a follow-up integration fix, use a separate branch after the starter is published:

```sh
git switch main
git pull --ff-only origin main
git switch -c feature/integration
```

After the fix, stage only the files changed for that fix. For example, if the fix changed only the top-level wiring:

```sh
git add rtl/harvard_top.v
git diff --cached --check
git diff --cached
git commit -m "Fix Harvard top-level integration"
git push -u origin feature/integration
```

## Members 2–5 — Clone and confirm your Git identity

Each person runs this once after Member 1 publishes. If you already cloned the repo, enter that clone and run `git switch main` and `git pull --ff-only origin main` before creating your branch.

```sh
git clone https://github.com/Anshuman-utd/MCA_Project.git
cd MCA_Project
git var GIT_AUTHOR_IDENT
```

If the identity is wrong, use your own name and email in this clone:

```sh
git config user.name "Your Full Name"
git config user.email "Your verified GitHub email or GitHub noreply email"
git var GIT_AUTHOR_IDENT
```

Run only your own branch creation command. The test, commit and push commands come **after** you finish the assigned work.

### Member 2 — Data path

```sh
git switch -c feature/data-path
```

```sh
make test-data
git add rtl/address_decoder.v rtl/read_write_control.v rtl/data_memory.v rtl/data_path.v testbench/tb_data_path.v
git diff --cached --check
git diff --cached --stat
git commit -m "Implement and test the Harvard data path"
git push -u origin feature/data-path
```

### Member 3 — Controller and Harvard verification

```sh
git switch -c feature/controller-simulation
```

While waiting for the data path, compile the controller independently as described in the work guide. After Member 2 merges, commit any work in progress or put it safely aside, then bring in the dependency using the update commands below. After the integrated test passes and you have saved the PNG:

```sh
make test-harvard
git add rtl/controller.v testbench/tb_harvard.v docs/controller.md docs/harvard-waveform.png
git diff --cached --check
git diff --cached --stat
git commit -m "Add controller, Harvard integration test and waveform"
git push -u origin feature/controller-simulation
```

### Member 4 — Shared port and measurements

```sh
git switch -c feature/shared-memory
```

While waiting for the data path, compile your baseline independently. After Member 2 merges, bring in that dependency and finish the comparison, screenshot and synthesis evidence. Member 4's comparison uses the workload directly and can run without Member 3's controller.

```sh
make test-comparison
git add rtl/shared_memory.v testbench/tb_comparison.v docs/comparison.md docs/comparison-waveform.png synthesis/results.md
git diff --cached --check
git diff --cached --stat
git commit -m "Add shared-memory baseline and measured comparison"
git push -u origin feature/shared-memory
```

### Member 5 — Direct Harvard tests

```sh
git switch -c feature/harvard-directed-tests
```

After Member 2 merges, update your branch using the dependency commands below. Run the test and push your code PR:

```sh
make test-harvard-directed
git add testbench/tb_harvard_directed.v
git diff --cached --check
git diff --cached --stat
git commit -m "Test independent Harvard paths and rejected requests"
git push -u origin feature/harvard-directed-tests
```

### Member 5 — Report handoff and demo

After Anshuman hands you the final source and PDF, create the report branch from updated `main`:

```sh
git switch main
git pull --ff-only origin main
git switch -c docs/report-demo
```

Copy the supplied PDF to `docs/IEEE_Project_Report.pdf` and the supplied source under `docs/report/`. Verify the PDF and add the accessible video URL to the README. Then push the report PR:

```sh
git add docs/IEEE_Project_Report.pdf docs/report/ README.md
git diff --cached --check
git diff --cached --stat
git commit -m "Add IEEE Phase I report and prototype video link"
git push -u origin docs/report-demo
```

## Update a feature branch and open a PR

When a dependency merges, stay on your own branch and run these commands with a clean working tree:

```sh
git status --short --branch
git fetch origin
git merge origin/main
```

If a conflict appears in another member's files, coordinate with the owner. After updating, rerun your tests and push your branch. Use `git push` once the upstream is set.

On GitHub, open a pull request with **base `main`** and **compare your own branch**. Include your name, what you implemented, commands run and their results, and any pending checks. Members 3 and 4 include the path to their screenshot. Member 5 includes the directed test result in the code PR and the PDF path and video link in the report PR. Each member can make several meaningful commits as the work progresses.

## Review, merge and verify

1. Member 1 merges Member 2's PR first, then reviews and merges the code PRs from Members 3, 4 and 5 after their integrated checks pass. Anshuman prepares the final report with that evidence, and Member 5 commits it in the report PR.
2. Use **Create a merge commit** if available so each person's original commits stay in the history. On GitHub, confirm the commits are attributed to the correct accounts.
3. Run the final check in a fresh clone. Use an unused destination directory for the clone.

```sh
git clone https://github.com/Anshuman-utd/MCA_Project.git MCA_Project_phase1_check
cd MCA_Project_phase1_check
make test-instruction
make test-data
make test-harvard
make test-harvard-directed
make test-comparison
git shortlog -sne HEAD
git log --format='%h %an <%ae> %s' HEAD
git status --short
```

Open both PNGs and the PDF in the repo, test the video link with the evaluator's expected permissions, and send the GitHub repository URL through the [course form](https://docs.google.com/forms/d/e/1FAIpQLSc6Cx8OrOQLGj_X2ZMkyG5jc8mokq36mGRq2x8jGRNV1sbegA/viewform).
