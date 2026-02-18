#!/usr/bin/env bash
# scripts/detect-changed-modules.sh
#
# Detects which modules have changed in a PR and outputs JSON for GitHub Actions matrix.
# Skips lza-foundation (validation-only, too slow for integration tests).

set -euo pipefail

BASE_REF="${GITHUB_BASE_REF:-main}"

# Get list of changed files compared to base branch
changed_files=$(git diff --name-only "origin/$BASE_REF"...HEAD 2>/dev/null || git diff --name-only HEAD~1)

# Extract unique module names from changed paths
declare -A modules_map
while IFS= read -r file; do
  if [[ "$file" =~ ^modules/([^/]+)/ ]]; then
    module="${BASH_REMATCH[1]}"
    # Skip lza-foundation (validation-only due to 60-90min deploy time)
    if [[ "$module" != "lza-foundation" ]]; then
      modules_map["$module"]=1
    fi
  fi
done <<< "$changed_files"

# Convert to array
modules=("${!modules_map[@]}")

# Output for GitHub Actions
if [[ ${#modules[@]} -eq 0 ]]; then
  echo "modules=[]" >> "$GITHUB_OUTPUT"
  echo "has_changes=false" >> "$GITHUB_OUTPUT"
  echo "No module changes detected"
else
  # Sort for consistent ordering
  IFS=$'\n' sorted=($(sort <<< "${modules[*]}")); unset IFS
  json=$(printf '%s\n' "${sorted[@]}" | jq -R . | jq -s -c .)
  echo "modules=$json" >> "$GITHUB_OUTPUT"
  echo "has_changes=true" >> "$GITHUB_OUTPUT"
  echo "Changed modules: ${sorted[*]}"
fi
