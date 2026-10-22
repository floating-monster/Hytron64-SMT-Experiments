#!/usr/bin/env bash
# Explicitly publishes this reviewed archive as a new public GitHub repository.
set -euo pipefail
root=$(cd "$(dirname "$0")/.." && pwd)
cd "$root"
python3 scripts/verify_release.py
python3 scripts/verify_evidence.py
if [ ! -d .git ]; then git init -b main; fi
test "$(git rev-parse --show-toplevel)" = "$root"
git add -- README.md NOTICE LICENSE LICENSE.SiFive LICENSE.Berkeley LICENSES \
  THIRD_PARTY_NOTICES.md PROVENANCE.json .gitignore RELEASE_SHA256SUMS docs scripts \
  snapshots tests evidence
git diff --cached --check
if ! git diff --cached --quiet; then
  git commit -m "Archive B1-B4 SMT experiments and SMP2 reference results"
fi
if ! command -v gh >/dev/null 2>&1; then
  printf 'LOCAL_COMMIT_READY; GitHub CLI gh is required for remote publication.\n' >&2
  exit 2
fi
gh auth status
gh repo create floating-monster/Hytron64-SMT-Experiments \
  --public --source "$root" --remote origin --push \
  --description "Paused Rocket two-context experiments B1-B4 with simulation evidence and an SMP2 reference"
printf 'GITHUB_PUBLICATION=PASS\n'
