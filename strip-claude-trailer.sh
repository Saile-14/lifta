#!/usr/bin/env bash
# One-off: remove the "Co-Authored-By: Claude ..." trailer from every commit
# message on main, then force-push the rewritten history.
#
# This rewrites history, so every commit gets a new SHA. That's safe here
# because this repo has a single author and no open pull requests, but it
# means anyone else with a clone would have to re-clone.
#
# Run from the repo root:   bash strip-claude-trailer.sh
# A backup of the current history is left on the branch backup-before-rewrite.
set -euo pipefail

cd "$(dirname "$0")"

git rev-parse --verify backup-before-rewrite >/dev/null 2>&1 ||
  git branch backup-before-rewrite main

before=$(git log --oneline --grep='Co-Authored-By: Claude' -i | wc -l)
echo "Commits carrying the trailer: $before"

FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --msg-filter \
  'perl -0pe "s/\n*^Co-Authored-By: Claude[^\n]*\n?//mg; s/\n+\z/\n/"' -- main

after=$(git log --oneline --grep='Co-Authored-By: Claude' -i | wc -l)
echo "Still carrying it after the rewrite: $after"

if [ "$after" -ne 0 ]; then
  echo "Rewrite didn't clean every commit -- not pushing. Restore with:"
  echo "  git reset --hard backup-before-rewrite"
  exit 1
fi

git push --force origin main
echo
echo "Done. Verify with: git log --format='%B' | grep -i claude   (expect no output)"
echo "Once you're happy, drop the backup: git branch -D backup-before-rewrite"
