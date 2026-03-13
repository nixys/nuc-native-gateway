#!/bin/sh
set -eu

CHART_VERSION="$(awk '/^version:/ {print $2}' Chart.yaml)"
CURRENT_MAJOR="$(echo "$CHART_VERSION" | cut -d. -f1)"
CURRENT_MINOR="$(echo "$CHART_VERSION" | cut -d. -f2)"
CURRENT_PATCH="$(echo "$CHART_VERSION" | cut -d. -f3)"

if [ -z "$CURRENT_MAJOR" ] || [ -z "$CURRENT_MINOR" ] || [ -z "$CURRENT_PATCH" ]; then
  echo "ERROR: Failed to parse chart version from Chart.yaml"
  exit 1
fi

if [ "$CURRENT_MAJOR" -eq 0 ]; then
  echo "ERROR: Cannot determine previous major for version $CHART_VERSION"
  exit 1
fi

PREVIOUS_MAJOR=$((CURRENT_MAJOR - 1))
PREVIOUS_MINOR=$((CURRENT_MINOR - 1))

latest_stable_tag_for_major() {
  major="$1"
  git tag --list "v${major}.*" \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V \
    | tail -n 1
}

latest_stable_tag_for_major_minor() {
  major="$1"
  minor="$2"
  git tag --list "v${major}.${minor}.*" \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
    | sort -V \
    | tail -n 1
}

latest_previous_patch_tag() {
  major="$1"
  minor="$2"
  patch="$3"

  git tag --list "v${major}.${minor}.*" \
    | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
    | awk -F'[v.]' -v p="$patch" '$4 < p' \
    | sort -V \
    | tail -n 1
}

PREV_MAJOR_TAG="$(latest_stable_tag_for_major "$PREVIOUS_MAJOR")"
if [ -z "$PREV_MAJOR_TAG" ]; then
  echo "ERROR: No stable tag found for previous major ${PREVIOUS_MAJOR}.x"
  exit 1
fi

if [ "$PREVIOUS_MINOR" -lt 0 ]; then
  echo "ERROR: No previous minor exists for current version $CHART_VERSION"
  exit 1
fi

PREV_MINOR_TAG="$(latest_stable_tag_for_major_minor "$CURRENT_MAJOR" "$PREVIOUS_MINOR")"
if [ -z "$PREV_MINOR_TAG" ]; then
  echo "ERROR: No stable tag found for previous minor ${CURRENT_MAJOR}.${PREVIOUS_MINOR}.x"
  exit 1
fi

PREV_PATCH_TAG="$(latest_previous_patch_tag "$CURRENT_MAJOR" "$CURRENT_MINOR" "$CURRENT_PATCH")"
if [ -z "$PREV_PATCH_TAG" ]; then
  echo "ERROR: No stable tag found for previous patch ${CURRENT_MAJOR}.${CURRENT_MINOR}.x below ${CHART_VERSION}"
  exit 1
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

run_compat_check() {
  tag="$1"
  values_file="$TMP_DIR/values-${tag}.yaml"

  git show "${tag}:values.yaml" > "$values_file"

  echo "Checking compatibility with ${tag} values.yaml"
  helm lint . -f "$values_file"
  helm template "compat-${tag}" . -f "$values_file" > /dev/null
}

run_compat_check "$PREV_MAJOR_TAG"
run_compat_check "$PREV_MINOR_TAG"
run_compat_check "$PREV_PATCH_TAG"

echo "Backward compatibility checks passed for: ${PREV_MAJOR_TAG}, ${PREV_MINOR_TAG}, ${PREV_PATCH_TAG}"
