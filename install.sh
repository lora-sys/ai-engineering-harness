#!/usr/bin/env bash
# Install the ai-engineering-harness skill onto agent platforms.
#
# Modes:
#   --all                  copy to every TARGET below (default coverage)
#   --target <name>        copy to a single TARGET (e.g., --target claude)
#   --uninstall            remove every previously installed copy
#   --fat-install          git clone + symlink per-agent-dir (works around
#                          the Vercel `npx skills add` thin-canonical quirk
#                          where symlinked agents only see SKILL.md)
#   --fat-install --clonedir <path>   override the clone target
#   --list                 show every TARGET name + current state

set -uo pipefail

SKILL_NAME="ai-engineering-harness"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="${SCRIPT_DIR}"

# Resolve HOME (handles sudo)
USER_HOME="${HOME:-}"
if [[ -n "${SUDO_USER:-}" ]]; then
  USER_HOME="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
fi
[[ -z "${USER_HOME}" ]] && USER_HOME="${HOME}"

# Per-agent TARGETS — each CLI agent puts skills in its own dir.
# The repo's canonical install lives at ~/.agents/skills/, but on
# read-only mounts that dir is locked; we treat it as optional.
TARGETS=(
  "claude:${USER_HOME}/.claude/skills/${SKILL_NAME}"
  "cursor:${USER_HOME}/.cursor/skills/${SKILL_NAME}"
  "gemini:${USER_HOME}/.gemini/skills/${SKILL_NAME}"
  "qwen:${USER_HOME}/.qwen/skills/${SKILL_NAME}"
  "opencode:${USER_HOME}/.config/opencode/skills/${SKILL_NAME}"
  "grok:${USER_HOME}/.grok/skills/${SKILL_NAME}"
  "hermes-agent:${USER_HOME}/.hermes/hermes-agent/skills/${SKILL_NAME}"
  "hermes:${USER_HOME}/.hermes/skills/${SKILL_NAME}"
  "aider-desk:${USER_HOME}/.aider-desk/skills/${SKILL_NAME}"
  "augment:${USER_HOME}/.augment/skills/${SKILL_NAME}"
  "bob:${USER_HOME}/.bob/skills/${SKILL_NAME}"
  "codebuddy:${USER_HOME}/.codebuddy/skills/${SKILL_NAME}"
  "commandcode:${USER_HOME}/.commandcode/skills/${SKILL_NAME}"
  "continue:${USER_HOME}/.continue/skills/${SKILL_NAME}"
  "crush:${USER_HOME}/.config/crush/skills/${SKILL_NAME}"
  "devin:${USER_HOME}/.config/devin/skills/${SKILL_NAME}"
  "factory:${USER_HOME}/.factory/skills/${SKILL_NAME}"
  "forge:${USER_HOME}/.forge/skills/${SKILL_NAME}"
  "goose:${USER_HOME}/.config/goose/skills/${SKILL_NAME}"
  "iflow:${USER_HOME}/.iflow/skills/${SKILL_NAME}"
  "junie:${USER_HOME}/.junie/skills/${SKILL_NAME}"
  "kilocode:${USER_HOME}/.kilocode/skills/${SKILL_NAME}"
  "kiro:${USER_HOME}/.kiro/skills/${SKILL_NAME}"
  "kode:${USER_HOME}/.kode/skills/${SKILL_NAME}"
  "marscode:${USER_HOME}/.marscode/skills/${SKILL_NAME}"
  "mux:${USER_HOME}/.mux/skills/${SKILL_NAME}"
  "neovate:${USER_HOME}/.neovate/skills/${SKILL_NAME}"
  "openhands:${USER_HOME}/.openhands/skills/${SKILL_NAME}"
  "pi:${USER_HOME}/.pi/agent/skills/${SKILL_NAME}"
  "pochi:${USER_HOME}/.pochi/skills/${SKILL_NAME}"
  "roo:${USER_HOME}/.roo/skills/${SKILL_NAME}"
  "snowflake:${USER_HOME}/.snowflake/cortex/skills/${SKILL_NAME}"
  "tabnine:${USER_HOME}/.tabnine/skills/${SKILL_NAME}"
  "trae:${USER_HOME}/.trae/skills/${SKILL_NAME}"
  "trae-cn:${USER_HOME}/.trae-cn/skills/${SKILL_NAME}"
  "vibe:${USER_HOME}/.vibe/skills/${SKILL_NAME}"
  "zencoder:${USER_HOME}/.zencoder/skills/${SKILL_NAME}"
  "adal:${USER_HOME}/.adal/skills/${SKILL_NAME}"
  "codex:${USER_HOME}/.codex/skills/${SKILL_NAME}"
  "agents:${USER_HOME}/.agents/skills/${SKILL_NAME}"
)

# --- Helpers ---
writable_dir() {
  local p="$1"
  [[ -d "${p%/*}" ]] || mkdir -p "${p%/*}" 2>/dev/null || return 1
  [[ -w "${p%/*}" ]]
}

copy_skill() {
  local dst="$1"; local plat="$2"
  if writable_dir "${dst}"; then
    echo "  → ${plat}: ${dst}"
    rm -rf "${dst}" 2>/dev/null || true
    # Copy the source but exclude repo-internal noise (.git/, test artifacts,
    # dotfiles that an agent does not need). Use rsync if available; fall back
    # to cp + find filtering.
    if command -v rsync >/dev/null 2>&1; then
      rsync -a --exclude='.git' --exclude='.DS_Store' "${SOURCE}/" "${dst}" 2>/dev/null && return 0
    fi
    # Fallback: cp everything then prune .git/
    if cp -r "${SOURCE}" "${dst}" 2>/dev/null; then
      rm -rf "${dst}/.git" "${dst}/.DS_Store" 2>/dev/null || true
      return 0
    fi
    echo "    ✗ copy failed" >&2
    return 1
  fi
  echo "  ✗ ${plat} not writable: ${dst}"
  return 1
}

uninstall_one() {
  local dst="$1"; local plat="$2"
  if [[ -d "${dst}" || -L "${dst}" ]]; then
    rm -rf "${dst}" 2>/dev/null && echo "  → removed ${plat}: ${dst}"
  fi
}

# --- Fat install: git clone + per-agent-dir symlink ---
# This is the workaround for `npx skills add` which only puts SKILL.md in
# ~/.agents/skills/<name>/ — symlinked agents see nothing else.
run_fat_install() {
  local clone_into="${FAT_CLONE_DIR:-/tmp/ai-engineering-harness-fat}"
  echo "fat-install: cloning to ${clone_into}"
  rm -rf "${clone_into}" 2>/dev/null || true
  if ! git clone --depth 1 https://github.com/lora-sys/ai-engineering-harness.git "${clone_into}" 2>/dev/null; then
    echo "  ✗ git clone failed; falling back to source dir"
    if [[ ! -d "${SOURCE}/workflows" ]]; then
      echo "  ✗ source missing workflows/; abort" >&2
      return 1
    fi
    rm -rf "${clone_into}" 2>/dev/null
    ln -s "${SOURCE}" "${clone_into}"
  fi
  echo "  source ready at: $(readlink -f "${clone_into}")"
  echo
  echo "fat-install: replacing each agent's install with a symlink to the full bundle"
  for entry in "${TARGETS[@]}"; do
    local name="${entry%%:*}"
    local path="${entry#*:}"
    rm -rf "${path}" 2>/dev/null || true
    if [[ -d "${path%/*}" ]]; then
      if [[ -w "${path%/*}" ]]; then
        if ln -sf "${clone_into}" "${path}" 2>/dev/null; then
          echo "  ✓ ${name}: symlink → ${clone_into}"
        elif cp -r "${clone_into}" "${path}" 2>/dev/null; then
          echo "  ✓ ${name}: full copy"
        else
          echo "  ✗ ${name}: skipped (write failed)"
        fi
      else
        echo "  ✗ ${name}: parent dir read-only (${path%/*})"
      fi
    fi
  done
  echo
  echo "Done. To verify workflows land at every agent:"
  echo "  ls -la \${HOME}/.claude/skills/ai-engineering-harness/workflows/"
  echo
  echo "To uninstall / revert:"
  echo "  bash install.sh --uninstall"
}

# --- List ---
list_targets() {
  for entry in "${TARGETS[@]}"; do
    local name="${entry%%:*}" path="${entry#*:}"
    if [[ -d "${path}" || -L "${path}" ]]; then
      echo "INSTALLED  ${name}  ${path}"
    else
      echo "available  ${name}  ${path}"
    fi
  done
}

# --- Argument parsing ---
TARGET_ONLY="" ; ALL=0 ; UNINSTALL=0 ; LIST=0 ; FAT_MODE=0 ; FAT_CLONE_DIR=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)            ALL=1 ;;
    --target)         TARGET_ONLY="$2"; shift 2 ;;
    --uninstall)      UNINSTALL=1 ;;
    --fat-install)    FAT_MODE=1 ;;
    --clonedir)       FAT_CLONE_DIR="$2"; shift 2 ;;
    --list)           LIST=1 ;;
    -h|--help)
      cat <<USAGE
Usage: install.sh [--all] [--target <name>] [--fat-install] [--uninstall] [--list]
  --all              install to every TARGET (default behavior)
  --target <name>    install to one specific TARGET
  --fat-install      git clone + symlink (works around thin canonical)
  --clonedir <path>  override the clone target for --fat-install
  --uninstall        remove everything
  --list             show all TARGETS and their state
  -h, --help         this message
USAGE
      exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
  shift
done

# --- Dispatch ---
if [[ "$LIST" -eq 1 ]]; then list_targets; exit 0; fi
if [[ "$FAT_MODE" -eq 1 ]]; then run_fat_install; exit 0; fi

if [[ "$UNINSTALL" -eq 1 ]]; then
  if [[ -n "$TARGET_ONLY" ]]; then
    found=0
    for entry in "${TARGETS[@]}"; do
      name="${entry%%:*}"; path="${entry#*:}"
      if [[ "$name" == "$TARGET_ONLY" ]]; then
        uninstall_one "${path}" "${name}"
        found=1; break
      fi
    done
    [[ "$found" -eq 0 ]] && { echo "unknown target: $TARGET_ONLY" >&2; exit 1; }
  else
    for entry in "${TARGETS[@]}"; do
      name="${entry%%:*}"; path="${entry#*:}"
      uninstall_one "${path}" "${name}"
    done
  fi
  exit 0
fi

if [[ -n "$TARGET_ONLY" ]]; then
  for entry in "${TARGETS[@]}"; do
    name="${entry%%:*}"; path="${entry#*:}"
    if [[ "$name" == "$TARGET_ONLY" ]]; then
      copy_skill "${path}" "${name}"
      exit 0
    fi
  done
  echo "unknown target: $TARGET_ONLY" >&2
  exit 1
fi

if [[ "$ALL" -eq 1 ]]; then
  for entry in "${TARGETS[@]}"; do
    name="${entry%%:*}"; path="${entry#*:}"
    copy_skill "${path}" "${name}"
  done
  exit 0
fi

# No flag selected — interactive menu
echo "Where would you like to install ${SKILL_NAME}?"
echo
echo "  0) all"
PS3="Select number (or 'q' to quit): "
options=()
for entry in "${TARGETS[@]}"; do options+=("${entry%%:*}"); done
options+=("quit")
select opt in "${options[@]}"; do
  case "${opt}" in
    all)
      for entry in "${TARGETS[@]}"; do
        name="${entry%%:*}"; path="${entry#*:}"
        copy_skill "${path}" "${name}"
      done
      break ;;
    quit) exit 0 ;;
    *)
      for entry in "${TARGETS[@]}"; do
        name="${entry%%:*}"; path="${entry#*:}"
        if [[ "$name" == "${opt}" ]]; then
          copy_skill "${path}" "${name}"
          break
        fi
      done
      break ;;
  esac
done
