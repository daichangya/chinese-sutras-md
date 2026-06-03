#!/usr/bin/env bash
# 按部类分批 commit + push，避免单次 push 过大导致 GitHub 超时。
# 支持：经目迁入 经藏/（从仓库根下旧部类路径删除索引并添加 经藏/部类/）。
# 用法:
#   ./push-by-dept.sh              # README/脚本 + 辞典/知识图谱 + 经藏下 23 部类
#   ./push-by-dept.sh --resume     # 跳过 经藏/部类 已在索引中的部类
#   ./push-by-dept.sh --dept 般若  # 仅处理指定部类（经藏/般若）
#   ./push-by-dept.sh --dry-run    # 仅打印计划
#   ./push-by-dept.sh --no-push    # 仅本地 commit，不 push
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

SUTRAS_BASE="经藏"
AUX_DIRS=(辞典 知识图谱)
BOOTSTRAP_FILES=(README.md .gitignore push-by-dept.sh)
LOG_FILE="${PUSH_LOG:-.push-log.txt}"

DRY_RUN=0
RESUME=0
NO_PUSH=0
ONLY_DEPT=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run) DRY_RUN=1 ;;
    --resume) RESUME=1 ;;
    --no-push) NO_PUSH=1 ;;
    --dept)
      shift
      ONLY_DEPT="${1:-}"
      [[ -n "$ONLY_DEPT" ]] || { echo "error: --dept requires a name"; exit 1; }
      ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
    *)
      echo "unknown arg: $1" >&2
      exit 1
      ;;
  esac
  shift
done

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

run() {
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry-run] $*"
    return 0
  fi
  "$@"
}

has_commit_message() {
  git log --oneline --grep="$1" -n 1 2>/dev/null | grep -q .
}

dept_already_tracked() {
  local dept="$1"
  [[ -n "$(git ls-files "$SUTRAS_BASE/$dept/" 2>/dev/null | head -1)" ]]
}

aux_already_tracked() {
  local dir="$1"
  [[ -n "$(git ls-files "$dir/" 2>/dev/null | head -1)" ]]
}

legacy_dept_in_index() {
  local dept="$1"
  [[ -n "$(git ls-files "$dept/" 2>/dev/null | head -1)" ]]
}

commit_and_push() {
  local msg="$1"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry-run] git commit -m \"$msg\" && git push"
    return 0
  fi
  if git diff --cached --quiet; then
    log "skip commit (nothing staged): $msg"
    return 0
  fi
  git commit -m "$msg"
  log "committed: $msg"
  if [[ "$NO_PUSH" -eq 0 ]]; then
    local attempt=0
    while [[ $attempt -lt 5 ]]; do
      if git push origin HEAD; then
        log "pushed: $msg"
        return 0
      fi
      attempt=$((attempt + 1))
      log "push failed (attempt $attempt), retry in 30s..."
      sleep 30
    done
    echo "push failed after 5 attempts: $msg" >&2
    exit 1
  fi
}

commit_bootstrap() {
  local staged=0
  for f in "${BOOTSTRAP_FILES[@]}"; do
    [[ -e "$f" ]] || continue
    if [[ "$DRY_RUN" -eq 1 ]]; then
      echo "  [dry-run] git add $f"
      staged=1
      continue
    fi
    if ! git diff --quiet -- "$f" 2>/dev/null || ! git diff --cached --quiet -- "$f" 2>/dev/null; then
      git add "$f"
      staged=1
    elif [[ -n "$(git status --porcelain -- "$f" 2>/dev/null)" ]]; then
      git add "$f"
      staged=1
    fi
  done
  if [[ $staged -eq 0 ]] && [[ "$DRY_RUN" -eq 0 ]]; then
    log "bootstrap: no changes"
    return 0
  fi
  commit_and_push "chore: update corpus README and push tooling"
}

commit_aux_dir() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  if [[ "$RESUME" -eq 1 ]] && aux_already_tracked "$dir"; then
    log "skip aux (already tracked): $dir"
    return 0
  fi
  log "aux: $dir"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    echo "  [dry-run] git add $dir/ && commit Add corpus auxiliary: $dir"
    return 0
  fi
  git add "$dir/"
  commit_and_push "Add corpus auxiliary: $dir"
}

push_dept() {
  local dept="$1"
  local nested="$SUTRAS_BASE/$dept"
  local legacy=0
  legacy_dept_in_index "$dept" && legacy=1

  if [[ ! -d "$nested" ]]; then
    if [[ $legacy -eq 1 ]]; then
      log "dept: remove obsolete flat index (no 经藏 dir): $dept"
      if [[ "$DRY_RUN" -eq 1 ]]; then
        echo "  [dry-run] git rm -r --cached $dept/ && commit chore: remove obsolete flat corpus $dept"
        return 0
      fi
      git rm -r --cached --quiet "$dept/" 2>/dev/null || git rm -r --cached "$dept/"
      commit_and_push "chore: remove obsolete flat corpus $dept"
    else
      log "skip dept (not on disk, not in index): $dept"
    fi
    return 0
  fi

  if [[ "$RESUME" -eq 1 ]] && dept_already_tracked "$dept"; then
    log "skip dept (经藏 already tracked): $dept"
    return 0
  fi

  local msg="Add corpus: $dept"
  [[ $legacy -eq 1 ]] && msg="refactor(经藏): migrate $dept"

  log "dept: $dept -> $nested (legacy_index_removal=$legacy)"
  if [[ "$DRY_RUN" -eq 1 ]]; then
    if [[ $legacy -eq 1 ]]; then
      echo "  [dry-run] git rm -r --cached $dept/"
    fi
    echo "  [dry-run] git add $nested/ && commit \"$msg\""
    return 0
  fi

  if [[ $legacy -eq 1 ]]; then
    git rm -r --cached --quiet "$dept/" 2>/dev/null || git rm -r --cached "$dept/"
  fi
  git add "$nested/"
  commit_and_push "$msg"
}

# 经藏/ 下实存部类 + git 索引中仍有根路径的旧部类（去重排序）
collect_depts() {
  local -a names=()
  local d top
  shopt -s nullglob
  for d in "$SUTRAS_BASE"/*/; do
    names+=("$(basename "$d")")
  done
  shopt -u nullglob
  while IFS= read -r top; do
    case "$top" in
      经藏|辞典|知识图谱|.gitignore|README.md|git-add-n.sh|push-by-dept.sh) continue ;;
    esac
    legacy_dept_in_index "$top" && names+=("$top")
  done < <(git ls-files -z | tr '\0' '\n' | while IFS= read -r f; do printf '%s\n' "${f%%/*}"; done | sort -u)
  if [[ ${#names[@]} -eq 0 ]]; then
    return
  fi
  printf '%s\n' "${names[@]}" | LC_ALL=C sort -u
}

log "=== push-by-dept start (dry_run=$DRY_RUN resume=$RESUME no_push=$NO_PUSH) ==="

run git rev-parse --is-inside-work-tree >/dev/null

log "phase 1: bootstrap"
commit_bootstrap

log "phase 2: auxiliary corpus (辞典 / 知识图谱)"
for aux in "${AUX_DIRS[@]}"; do
  commit_aux_dir "$aux"
done

log "phase 3: sutras under $SUTRAS_BASE/"
if [[ -n "$ONLY_DEPT" ]]; then
  push_dept "$ONLY_DEPT"
else
  while IFS= read -r dept; do
    [[ -n "$dept" ]] || continue
    push_dept "$dept"
  done < <(collect_depts)
fi

log "=== push-by-dept done ==="
