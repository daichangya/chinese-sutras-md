#!/usr/bin/env bash
# 按部类目录分批 add / commit / push（Corpus V3 首次上 GitHub）
# 用法:
#   ./push-by-dept.sh              # 从 README 起全量推送
#   ./push-by-dept.sh --resume     # 跳过已有 commit 的部类
#   ./push-by-dept.sh --dept 般若   # 仅推送指定部类
#   ./push-by-dept.sh --dry-run    # 只打印计划
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

export GIT_SSH_COMMAND="${GIT_SSH_COMMAND:-ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=10}"

RESUME=false
DRY_RUN=false
DEPT_FILTER=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --resume) RESUME=true; shift ;;
    --dry-run) DRY_RUN=true; shift ;;
    --dept)
      DEPT_FILTER="${2:-}"
      shift 2
      ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

remote="${GIT_REMOTE:-origin}"
branch="${GIT_BRANCH:-main}"

log() { echo "[push-by-dept] $*"; }

has_commit_message() {
  git log --format=%s 2>/dev/null | grep -Fxq "$1"
}

commit_and_push() {
  local msg="$1"
  shift
  local paths=("$@")

  if $DRY_RUN; then
    log "DRY-RUN commit: $msg"
    printf '  %s\n' "${paths[@]}"
    return 0
  fi

  git add "${paths[@]}"
  if git diff --cached --quiet; then
    log "skip (nothing to stage): $msg"
    return 0
  fi

  git commit -m "$msg"
  log "committed: $msg"

  if ! git rev-parse --abbrev-ref --symbolic-full-name "@{u}" &>/dev/null; then
    git push -u "$remote" "$branch"
  else
    git push "$remote" "$branch"
  fi
  log "pushed: $msg"
}

DEPTS=()
while IFS= read -r d; do
  DEPTS+=("$d")
done < <(find . -mindepth 1 -maxdepth 1 -type d ! -name '.git' -print | sed 's|^\./||' | LC_ALL=C sort)

if [[ -n "$DEPT_FILTER" ]]; then
  DEPTS=("$DEPT_FILTER")
fi

bootstrap_msg="chore: add README and batch push tooling"
if $RESUME && has_commit_message "$bootstrap_msg"; then
  log "skip bootstrap (already committed)"
else
  bootstrap_files=(README.md .gitignore push-by-dept.sh)
  [[ -f git-add-n.sh ]] && bootstrap_files+=(git-add-n.sh)
  commit_and_push "$bootstrap_msg" "${bootstrap_files[@]}"
fi

for dept in "${DEPTS[@]}"; do
  msg="Add corpus: $dept"
  if $RESUME && has_commit_message "$msg"; then
    log "skip dept (already committed): $dept"
    continue
  fi
  if [[ ! -d "$dept" ]]; then
    log "warn: dept not found: $dept"
    continue
  fi
  commit_and_push "$msg" "$dept/"
done

log "done."
