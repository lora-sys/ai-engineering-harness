#!/usr/bin/env bash
# Install the ai-engineering-harness skill onto agent platforms.
#
# Supports the major coding-agent CLIs the user has on this machine:
# codex, claude, agents, cursor, gemini, qwen, opencode, grok, hermes,
# aider-desk, continue, warp, kilocode, kiro, junie, roo, factory,
# openhands, pi, iflow, adal, augment, bob, codebuddy, commandcode,
# forge, kilocode, kode, marscode, mux, neovate, openhands, pi,
# pochi, snowflake/cortex, tabnine, trae, trae-cn, vibe, zencoder,
# devin, crush, goose, pohci
#
# Usage:
#   ./install.sh              # interactive menu (recommended)
#   ./install.sh --all        # try all known locations
#   ./install.sh --target codex   # one specific location
#   ./install.sh --uninstall  # remove previously installed copies

set -euo pipefail

SKILL_NAME="ai-engineering-harness"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="${SCRIPT_DIR}"

# Resolve the user's actual home directory.
USER_HOME="${HOME:-}"
if [[ -n "${SUDO_USER:-}" ]]; then
  USER_HOME="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
fi
[[ -z "${USER_HOME}" ]] && USER_HOME="${HOME}"

# Detect target list: most of these CLIs accept a skill installed under their
# well-known directory with the convention <skill>/SKILL.md.
TARGETS=(
  "codex:${USER_HOME}/.codex/skills/${SKILL_NAME}"
  "claude:${USER_HOME}/.claude/skills/${SKILL_NAME}"
  "agents:${USER_HOME}/.agents/skills/${SKILL_NAME}"
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
)

usage() {
  cat <<USAGE
Usage: $0 [--all] [--target <name>] [--uninstall] [--list]

Targets:
USAGE
  for entry in "${TARGETS[@]}"; do
    name="${entry%%:*}"
    printf '  %s\n' "$name"
  done
}

list_targets() {
  for entry in "${TARGETS[@]}"; do
    name="${entry%%:*}"
    path="${entry#*:}"
    if [[ -d "${path}" ]]; then
      echo "INSTALLED  $name  $path"
    else
      echo "available  $name  $path"
    fi
  done
}

writable_dir() {
  local p="$1"
  [[ -d "${p%/*}" ]] || mkdir -p "${p%/*}" 2>/dev/null || return 1
  [[ -w "${p%/*}" ]]
}

copy_skill() {
  local dst="$1"
  local plat="$2"
  if writable_dir "${dst}"; then
    echo "→ Installing to ${plat}: ${dst}"
    rm -rf "${dst}"
    cp -r "${SOURCE}" "${dst}"
    echo "  Installed."
  else
    echo "✗ ${plat} destination not writable: ${dst}"
    echo "  Run this to install (one time):"
    echo "    sudo mkdir -p \"${dst%/*}\" && sudo cp -r ${SOURCE} \"${dst}\""
    echo "  Or remount the parent as read-write, then re-run."
  fi
}

uninstall_skill() {
  local dst="$1"
  local plat="$2"
  if [[ -d "${dst}" ]]; then
    echo "→ Removing from ${plat}: ${dst}"
    rm -rf "${dst}"
  fi
}

TARGET_ONLY=""
ALL=0
UNINSTALL=0
LIST=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)        ALL=1; shift ;;
    --target)     TARGET_ONLY="$2"; shift 2 ;;
    --uninstall)  UNINSTALL=1; shift ;;
    --list)       LIST=1; shift ;;
    -h|--help)    usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ "${LIST}" -eq 1 ]]; then
  list_targets
  exit 0
fi

# --uninstall
if [[ "${UNINSTALL}" -eq 1 ]]; then
  if [[ -n "${TARGET_ONLY}" ]]; then
    found=0
    for entry in "${TARGETS[@]}"; do
      name="${entry%%:*}"; path="${entry#*:}"
      if [[ "${name}" == "${TARGET_ONLY}" ]]; then
        uninstall_skill "${path}" "${name}"
        found=1
        break
      fi
    done
    [[ "${found}" -eq 0 ]] && { echo "Unknown target: ${TARGET_ONLY}" >&2; exit 1; }
  else
    for entry in "${TARGETS[@]}"; do
      name="${entry%%:*}"; path="${entry#*:}"
      uninstall_skill "${path}" "${name}"
    done
  fi
  exit 0
fi

# --target <name>
if [[ -n "${TARGET_ONLY}" ]]; then
  found=0
  for entry in "${TARGETS[@]}"; do
    name="${entry%%:*}"; path="${entry#*:}"
    if [[ "${name}" == "${TARGET_ONLY}" ]]; then
      copy_skill "${path}" "${name}"
      found=1
      break
    fi
  done
  [[ "${found}" -eq 0 ]] && { echo "Unknown target: ${TARGET_ONLY}" >&2; exit 1; }
  exit 0
fi

# --all
if [[ "${ALL}" -eq 1 ]]; then
  for entry in "${TARGETS[@]}"; do
    name="${entry%%:*}"; path="${entry#*:}"
    copy_skill "${path}" "${name}"
  done
  exit 0
fi

# Interactive default
echo "Where would you like to install ${SKILL_NAME}?"
echo
echo "  0) all (try every known location)"
PS3="  Select number (or 'q' to quit): "
options=()
for entry in "${TARGETS[@]}"; do
  options+=("${entry%%:*}")
done
options+=("quit")
select opt in "${options[@]}"; do
  case "${opt}" in
    all) for entry in "${TARGETS[@]}"; do
           name="${entry%%:*}"; path="${entry#*:}"
           copy_skill "${path}" "${name}"
         done
         break ;;
    quit) exit 0 ;;
    "")
      # Some shells (zsh) leave REPLY when option is empty after invalid input.
      ;;
    *)
      for entry in "${TARGETS[@]}"; do
        name="${entry%%:*}"; path="${entry#*:}"
        if [[ "${name}" == "${opt}" ]]; then
          copy_skill "${path}" "${name}"
          break
        fi
      done
      break
      ;;
  esac
done

echo
echo "Done. Restart your agent if the skill doesn't appear immediately."
