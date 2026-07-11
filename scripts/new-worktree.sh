#!/usr/bin/env bash
# Create a new git worktree for an Issue.
# Usage: scripts/new-worktree.sh <issue-id> <slug>
set -euo pipefail

issue_id="${1:-}"
slug="${2:-}"

if [[ -z "$issue_id" || -z "$slug" ]]; then
  echo "Usage: $0 <issue-id> <slug>" >&2
  exit 1
fi

# Determine repo root + base branch
repo_root="$(git rev-parse --show-toplevel)"
base_branch="${BASE_BRANCH:-main}"

branch="feature/${issue_id}-${slug}"
parent_dir="$(dirname "${repo_root}")"
dir_name="$(basename "${repo_root}")-issue-${issue_id}"

worktree_path="${parent_dir}/${dir_name}"

# Skip if already exists
if [[ -d "${worktree_path}" ]]; then
  echo "Worktree already exists at: ${worktree_path}"
  exit 0
fi

git -C "${repo_root}" worktree add "${worktree_path}" -b "${branch}" "${base_branch}"

cat <<INFO
Created worktree:
  path:   ${worktree_path}
  branch: ${branch}
  base:   ${base_branch}

Next steps:
  cd "${worktree_path}"
  scripts/new-evidence.sh "${issue_id}"
INFO
