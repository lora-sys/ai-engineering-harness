#!/usr/bin/env bash
# Install the ai-engineering-harness skill family onto agent platforms.
#
# This install.sh handles a SKILL FAMILY (multiple skills shipped from one
# repo). Each CLI agent has a skills directory; each family member lands
# in its own sub-directory.
#
# Modes:
#   --all                       install every family member to every TARGET
#   --target <name>             install selected skill(s) to a single TARGET
#   --skill <name>              ai-engineering-harness | build-agent-app | all (default)
#   --uninstall                 remove everything
#   --fat-install               git clone the repo + symlink per-agent-dir
#   --list                      show every TARGET name + current state
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Skill family — add new entries here as the family grows.
declare -A SKILL_SOURCES=(
  ["ai-engineering-harness"]="$SCRIPT_DIR"
  ["build-agent-app"]="$SCRIPT_DIR/skills/build-agent-app"
)

# Paths to exclude when copying a skill bundle
EXCLUDES=(--exclude=.git --exclude=.DS_Store)

USER_HOME="${HOME:-}"
[[ -n "${SUDO_USER:-}" ]] && USER_HOME="$(getent passwd "${SUDO_USER}" | cut -d: -f6)"
[[ -z "$USER_HOME" ]] && USER_HOME="${HOME}"

# Per-agent TARGETS — the placeholder __DIR__ is replaced per-skill at copy time.
TARGETS=(
  "claude:$USER_HOME/.claude/skills/__DIR__"
  "cursor:$USER_HOME/.cursor/skills/__DIR__"
  "gemini:$USER_HOME/.gemini/skills/__DIR__"
  "qwen:$USER_HOME/.qwen/skills/__DIR__"
  "opencode:$USER_HOME/.config/opencode/skills/__DIR__"
  "grok:$USER_HOME/.grok/skills/__DIR__"
  "hermes-agent:$USER_HOME/.hermes/hermes-agent/skills/__DIR__"
  "hermes:$USER_HOME/.hermes/skills/__DIR__"
  "aider-desk:$USER_HOME/.aider-desk/skills/__DIR__"
  "augment:$USER_HOME/.augment/skills/__DIR__"
  "bob:$USER_HOME/.bob/skills/__DIR__"
  "codebuddy:$USER_HOME/.codebuddy/skills/__DIR__"
  "commandcode:$USER_HOME/.commandcode/skills/__DIR__"
  "continue:$USER_HOME/.continue/skills/__DIR__"
  "crush:$USER_HOME/.config/crush/skills/__DIR__"
  "devin:$USER_HOME/.config/devin/skills/__DIR__"
  "factory:$USER_HOME/.factory/skills/__DIR__"
  "forge:$USER_HOME/.forge/skills/__DIR__"
  "goose:$USER_HOME/.config/goose/skills/__DIR__"
  "iflow:$USER_HOME/.iflow/skills/__DIR__"
  "junie:$USER_HOME/.junie/skills/__DIR__"
  "kilocode:$USER_HOME/.kilocode/skills/__DIR__"
  "kiro:$USER_HOME/.kiro/skills/__DIR__"
  "kode:$USER_HOME/.kode/skills/__DIR__"
  "marscode:$USER_HOME/.marscode/skills/__DIR__"
  "mux:$USER_HOME/.mux/skills/__DIR__"
  "neovate:$USER_HOME/.neovate/skills/__DIR__"
  "openhands:$USER_HOME/.openhands/skills/__DIR__"
  "pi:$USER_HOME/.pi/agent/skills/__DIR__"
  "pochi:$USER_HOME/.pochi/skills/__DIR__"
  "roo:$USER_HOME/.roo/skills/__DIR__"
  "snowflake:$USER_HOME/.snowflake/cortex/skills/__DIR__"
  "tabnine:$USER_HOME/.tabnine/skills/__DIR__"
  "trae:$USER_HOME/.trae/skills/__DIR__"
  "trae-cn:$USER_HOME/.trae-cn/skills/__DIR__"
  "vibe:$USER_HOME/.vibe/skills/__DIR__"
  "zencoder:$USER_HOME/.zencoder/skills/__DIR__"
  "adal:$USER_HOME/.adal/skills/__DIR__"
  "codex:$USER_HOME/.codex/skills/__DIR__"
  "agents:$USER_HOME/.agents/skills/__DIR__"
)

# ------- helpers -------

writable_dir() {
  local p="$1"
  [[ -d "${p%/*}" ]] || mkdir -p "${p%/*}" 2>/dev/null || return 1
  [[ -w "${p%/*}" ]]
}

# Substitute __DIR__ placeholders in $1 with $2, emit the result
resolve_path() { echo "${1//__DIR__/$2}"; }

copy_skill() {
  local skill="$1" src="$2" dst="$3" plat="$4"
  if writable_dir "$dst"; then
    echo "  → ${plat} (${skill}): ${dst}"
    rm -rf "$dst" 2>/dev/null || true
    if command -v rsync >/dev/null 2>&1; then
      rsync -a "${EXCLUDES[@]}" "$src/" "$dst" 2>/dev/null && return 0
    fi
    if cp -r "$src" "$dst" 2>/dev/null; then
      rm -rf "$dst/.git" "$dst/.DS_Store" 2>/dev/null || true
      return 0
    fi
    echo "    ✗ copy failed" >&2
    return 1
  fi
  echo "  ✗ ${plat} not writable: ${dst}"
  return 1
}

uninstall_one() {
  local skill="$1" dst="$2" plat="$3"
  if [[ -d "$dst" || -L "$dst" ]]; then
    rm -rf "$dst" 2>/dev/null && echo "  → removed ${plat} (${skill}): ${dst}"
  fi
}

skills_to_install() {
  if [[ "$SKILL_FILTER" == "all" ]]; then
    printf "%s\n" "${!SKILL_SOURCES[@]}"
  else
    printf "%s\n" "$SKILL_FILTER"
  fi
}

# ------- arg loop -------

TARGET_ONLY=""
ALL=0
UNINSTALL=0
LIST=0
FAT_MODE=0
FAT_CLONE_DIR=""
SKILL_FILTER="all"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)            ALL=1 ;;
    --target)         TARGET_ONLY="$2"; shift 2 ;;
    --uninstall)      UNINSTALL=1 ;;
    --fat-install)    FAT_MODE=1 ;;
    --skill)          SKILL_FILTER="$2"; shift 2 ;;
    --clonedir)       FAT_CLONE_DIR="$2"; shift 2 ;;
    --list)           LIST=1 ;;
    -h|--help)
      cat <<USAGE
Usage: install.sh [--all] [--target <name>] [--skill <name>] [--fat-install] [--uninstall] [--list]

  --all               install every family member to every TARGET
  --target <name>     install selected skill(s) to a single TARGET
  --skill <name>      ai-engineering-harness | build-agent-app | all (default: all)
  --uninstall         remove installed copies
  --fat-install       git clone + symlink per-agent-dir (works around npx skills thin canonical)
  --fat-install --clonedir <path>
                      override the fat-install clone target
  --list              show every TARGET name + current state

Examples:
  bash install.sh                                                   # everything, everywhere
  bash install.sh --skill build-agent-app                          # only build-agent-app
  bash install.sh --all --target claude                           # one platform
USAGE
      exit 0 ;;
    *) echo "unknown arg: $1" >&2; exit 1 ;;
  esac
  shift
done

# ------- dispatch -------

if [[ "$LIST" -eq 1 ]]; then
  echo "Skills in family:"
  for k in "${!SKILL_SOURCES[@]}"; do echo "  - $k → ${SKILL_SOURCES[$k]}"; done
  echo
  while IFS= read -r skill; do
    echo "=== $skill ==="
    for entry in "${TARGETS[@]}"; do
      name="${entry%%:*}"
      raw_path="${entry#*:}"
      path="$(resolve_path "$raw_path" "$skill")"
      if [[ -d "$path" || -L "$path" ]]; then
        echo "  INSTALLED  $name ($skill)  $path"
      else
        echo "  available  $name ($skill)  $path"
      fi
    done
  done < <(skills_to_install)
  exit 0
fi

if [[ "$FAT_MODE" -eq 1 ]]; then
  run_fat_install
  exit 0
fi

if [[ "$UNINSTALL" -eq 1 ]]; then
  while IFS= read -r skill; do
    for entry in "${TARGETS[@]}"; do
      name="${entry%%:*}"
      raw_path="${entry#*:}"
      path="$(resolve_path "$raw_path" "$skill")"
      uninstall_one "$skill" "$path" "$name"
    done
  done < <(skills_to_install)
  exit 0
fi

if [[ -n "$TARGET_ONLY" ]]; then
  found=0
  while IFS= read -r skill; do
    if [[ "$found" -eq 1 ]]; then break; fi
    for entry in "${TARGETS[@]}"; do
      name="${entry%%:*}"
      raw_path="${entry#*:}"
      if [[ "${name}" == "${TARGET_ONLY}" ]]; then
        path="$(resolve_path "$raw_path" "$skill")"
        copy_skill "$skill" "${SKILL_SOURCES[$skill]}" "$path" "$name"
        found=1; break
      fi
    done
  done < <(skills_to_install)
  [[ "$found" -eq 0 ]] && { echo "unknown target: ${TARGET_ONLY}" >&2; exit 1; }
  exit 0
fi

if [[ "$ALL" -eq 1 ]]; then
  while IFS= read -r skill; do
    echo "---- $skill ----"
    for entry in "${TARGETS[@]}"; do
      name="${entry%%:*}"
      raw_path="${entry#*:}"
      path="$(resolve_path "$raw_path" "$skill")"
      copy_skill "$skill" "${SKILL_SOURCES[$skill]}" "$path" "$name"
    done
  done < <(skills_to_install)
  exit 0
fi

# Default: interactive menu
echo "This is the ai-engineering-harness skill family installer."
echo "  Skills: ${!SKILL_SOURCES[@]}"
echo "  Targets: $(echo "${TARGETS[@]}" | wc -w) CLI agent dirs (deduped count below)"
echo
echo "  0) install ALL skills to ALL targets"
echo "  1) pick a target, install ALL skills there"
echo "  q) quit"
PS3="Select option: "
options=("all" "by-target" "quit")
select opt in "${options[@]}"; do
  case "${opt}" in
    all)
      while IFS= read -r skill; do
        echo "---- $skill ----"
        for entry in "${TARGETS[@]}"; do
          name="${entry%%:*}"
          raw_path="${entry#*:}"
          path="$(resolve_path "$raw_path" "$skill")"
          copy_skill "$skill" "${SKILL_SOURCES[$skill]}" "$path" "$name"
        done
      done < <(skills_to_install)
      break ;;
    "by-target")
      target_names=()
      for entry in "${TARGETS[@]}"; do target_names+=("${entry%%:*}"); done
      unique_targets=($(printf "%s\n" "${target_names[@]}" | sort -u))
      echo "Choose a target:"
      PS3="Target number: "
      select t in "${unique_targets[@]}"; do
        if [[ -n "$t" ]]; then
          found=0
          while IFS= read -r skill; do
            if [[ "$found" -eq 1 ]]; then break; fi
            for entry in "${TARGETS[@]}"; do
              name="${entry%%:*}"
              raw_path="${entry#*:}"
              if [[ "${name}" == "${t}" ]]; then
                path="$(resolve_path "$raw_path" "$skill")"
                copy_skill "$skill" "${SKILL_SOURCES[$skill]}" "$path" "$name"
                found=1; break
              fi
            done
          done < <(skills_to_install)
          break
        fi
      done
      break ;;
    quit) exit 0 ;;
    *) ;;
  esac
done

# ------- fat install -------

run_fat_install() {
  local clone_into="${FAT_CLONE_DIR:-/tmp/ai-engineering-harness-skills-fat}"
  echo "fat-install: cloning to ${clone_into}"
  rm -rf "$clone_into" 2>/dev/null || true
  if ! git clone --depth 1 https://github.com/lora-sys/ai-engineering-harness.git "$clone_into" 2>/dev/null; then
    echo "  git clone failed; falling back to source dir"
    if [[ ! -d "$SCRIPT_DIR/workflows" ]]; then
      echo "  source missing workflows/; abort" >&2
      return 1
    fi
    rm -rf "$clone_into" 2>/dev/null
    ln -s "$SCRIPT_DIR" "$clone_into"
  fi
  echo "  source ready at: $(readlink -f "$clone_into")"
  echo
  while IFS= read -r skill; do
    echo "---- $skill ----"
    for entry in "${TARGETS[@]}"; do
      name="${entry%%:*}"
      raw_path="${entry#*:}"
      path="$(resolve_path "$raw_path" "$skill")"
      rm -rf "$path" 2>/dev/null || true
      if [[ -d "${path%/*}" ]]; then
        if [[ -w "${path%/*}" ]]; then
          # For aeh, bundle is at clone_into/ (root of repo). For nested skills,
          # bundle is at clone_into/skills/<name>.
          local bundle="$clone_into"
          if [[ "$skill" != "ai-engineering-harness" ]]; then
            bundle="$clone_into/skills/$skill"
          fi
          if ln -sf "$bundle" "$path" 2>/dev/null; then
            echo "  ✓ $name ($skill): symlink -> $bundle"
          elif cp -r "$bundle" "$path" 2>/dev/null; then
            echo "  ✓ $name ($skill): full copy"
          else
            echo "  ✗ $name ($skill): skipped (write failed)"
          fi
        else
          echo "  ✗ $name ($skill): parent dir read-only (${path%/*})"
        fi
      fi
    done
  done < <(skills_to_install)
  echo
  echo "Done. Verify both skills land at every agent:"
  echo "  ls ~/.claude/skills/ai-engineering-harness/workflows/"
  echo "  ls ~/.claude/skills/build-agent-app/workflows/"
}
