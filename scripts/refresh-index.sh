#!/usr/bin/env bash
# Refresh docs/.index/ from the docs/ tree.
# This is a minimal, dependency-free implementation.
# For larger projects, swap in a real indexer (mdast, cody, etc.).

set -euo pipefail

if [[ ! -d "docs" ]]; then
  echo "No docs/ directory at repo root." >&2
  exit 1
fi

mkdir -p docs/.index

# Build manifest.json by walking *.md files in docs/
manifest_path="docs/.index/manifest.json"
echo "{" > "${manifest_path}"
echo "  \"generated\": \"$(date -Iseconds)\"," >> "${manifest_path}"
echo "  \"docs\": [" >> "${manifest_path}"

first=1
while IFS= read -r f; do
  rel="${f#./}"
  id="${rel#docs/}"
  type="doc"
  case "${rel}" in
    docs/decisions/*) type="adr" ;;
    docs/evidence/*) type="evidence" ;;
    docs/architecture/*) type="architecture" ;;
    docs/design/*) type="design" ;;
    docs/product/*) type="product" ;;
    docs/sessions/*) type="session" ;;
  esac

  if [[ "${first}" -eq 1 ]]; then
    first=0
  else
    echo "    ," >> "${manifest_path}"
  fi

  printf '    {"id": "%s", "type": "%s", "path": "%s"}' "${id}" "${type}" "${rel}" >> "${manifest_path}"
done < <(find docs -type f \( -name '*.md' -o -name '*.mdx' \) | sort)

echo "" >> "${manifest_path}"
echo "  ]" >> "${manifest_path}"
echo "}" >> "${manifest_path}"

# Build freshness.json (last-touched map)
freshness_path="docs/.index/freshness.json"
echo "{" > "${freshness_path}"
echo "  \"generated\": \"$(date -Iseconds)\"," >> "${freshness_path}"
echo "  \"thresholds\": {\"warn_days\": 60, \"stale_days\": 90}," >> "${freshness_path}"
echo "  \"docs\": {" >> "${freshness_path}"

first=1
while IFS= read -r f; do
  rel="${f#./}"
  ts="$(stat -c '%y' "${f}" 2>/dev/null || stat -f '%Sm' "${f}")"
  ts_iso="${ts%% *}"

  if [[ "${first}" -eq 1 ]]; then
    first=0
  else
    echo "    ," >> "${freshness_path}"
  fi

  printf '    "%s": "%s"' "${rel}" "${ts_iso}" >> "${freshness_path}"
done < <(find docs -type f \( -name '*.md' -o -name '*.mdx' \) | sort)

echo "" >> "${freshness_path}"
echo "  }" >> "${freshness_path}"
echo "}" >> "${freshness_path}"

# relations.json: simple co-occurrence on explicit ADR/doc links (placeholder).
relations_path="docs/.index/relations.json"
echo "{\"generated\": \"$(date -Iseconds)\", \"relations\": []}" > "${relations_path}"

echo "Refreshed:"
echo "  ${manifest_path}"
echo "  ${freshness_path}"
echo "  ${relations_path}"
