#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: release_with_signaro.sh [options]

Optional:
  --tag <tag>                Override the derived Git tag, e.g. v1.7.2-build12
  --title <text>             Override the derived GitHub release title
  --app <path>               Input .app bundle to sign and distribute
                             Default: /Users/helpdesk/Developer/Apps/ReportSimpleMDM.app
  --keychain-profile <name>  Signaro notarization profile
                             Default: Jay_SIGNARO
  --identity <name>          Developer ID Application signing identity
                             Default: Developer ID Application: Jesus Ayala (N859JA9UCJ)
  --repo <owner/name>        Primary GitHub repo to publish to
                             Default: hov172/ReportSimpleMDM
  --mirror-repo <owner/name> Secondary GitHub repo to mirror to
                             Default: hov172/Report-SimpleMDM
  --notes <text>             GitHub release notes used if the release does not exist yet
  --output-root <path>       Directory for staging and generated assets
                             Default: a temp directory under /private/tmp

The script stages the input app, runs SignaroCLI distribute app to sign/notarize/
staple it and create a DMG, then uploads the DMG to the requested GitHub release(s).
EOF
}

tag=""
release_title=""
app_path="/Users/helpdesk/Developer/Apps/ReportSimpleMDM.app"
keychain_profile="Jay_SIGNARO"
signing_identity="Developer ID Application: Jesus Ayala (N859JA9UCJ)"
primary_repo="hov172/ReportSimpleMDM"
mirror_repo="hov172/Report-SimpleMDM"
release_notes=""
output_root=""
project_path=""
scheme="ReportSimpleMDM"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tag)
      tag="${2:-}"
      shift 2
      ;;
    --app)
      app_path="${2:-}"
      shift 2
      ;;
    --keychain-profile)
      keychain_profile="${2:-}"
      shift 2
      ;;
    --identity)
      signing_identity="${2:-}"
      shift 2
      ;;
    --repo)
      primary_repo="${2:-}"
      shift 2
      ;;
    --mirror-repo)
      mirror_repo="${2:-}"
      shift 2
      ;;
    --title)
      release_title="${2:-}"
      shift 2
      ;;
    --notes)
      release_notes="${2:-}"
      shift 2
      ;;
    --output-root)
      output_root="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Unknown argument: %s\n' "$1" >&2
      usage >&2
      exit 64
      ;;
  esac
done

if [[ -z "$tag" ]]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  repo_root="$(cd "$script_dir/.." && pwd)"
  project_path="$repo_root/ReportSimpleMDM.xcodeproj"
  if [[ ! -d "$project_path" ]]; then
    printf 'Xcode project not found: %s\n' "$project_path" >&2
    exit 66
  fi

  build_settings="$(xcodebuild -project "$project_path" -scheme "$scheme" -configuration Release -showBuildSettings 2>/dev/null)"
  marketing_version="$(printf '%s\n' "$build_settings" | awk -F' = ' '/ MARKETING_VERSION = / {gsub(";", "", $2); print $2; exit}')"
  project_version="$(printf '%s\n' "$build_settings" | awk -F' = ' '/ CURRENT_PROJECT_VERSION = / {gsub(";", "", $2); print $2; exit}')"
  product_name="$(printf '%s\n' "$build_settings" | awk -F' = ' '/ PRODUCT_NAME = / {gsub(";", "", $2); print $2; exit}')"

  if [[ -z "${marketing_version:-}" || -z "${project_version:-}" ]]; then
    printf 'Failed to derive build settings from %s\n' "$project_path" >&2
    exit 70
  fi

  tag="v${marketing_version}-build${project_version}"
  release_title="${release_title:-${product_name:-ReportSimpleMDM} v${marketing_version} (Build ${project_version})}"
fi

if [[ ! -d "$app_path" ]]; then
  printf 'App bundle not found: %s\n' "$app_path" >&2
  exit 66
fi

command -v SignaroCLI >/dev/null 2>&1 || {
  printf 'SignaroCLI is not on PATH.\n' >&2
  exit 69
}
command -v gh >/dev/null 2>&1 || {
  printf 'gh is not on PATH.\n' >&2
  exit 69
}

release_root="${output_root:-$(mktemp -d /private/tmp/ReportSimpleMDM-release.XXXXXX)}"
stage_root="$release_root/stage"
mkdir -p "$stage_root"

staged_app="$stage_root/$(basename "$app_path")"
rm -rf "$staged_app"
ditto "$app_path" "$staged_app"

SignaroCLI distribute app \
  --app "$staged_app" \
  --identity-name "$signing_identity" \
  --keychain-profile "$keychain_profile" \
  --output-dir "$release_root"

dmg_path="$(find "$release_root" -maxdepth 1 -type f -name '*.dmg' | sort | tail -n 1)"
if [[ -z "${dmg_path:-}" ]]; then
  printf 'No DMG was produced in %s\n' "$release_root" >&2
  exit 70
fi

publish_release() {
  local repo="$1"
  if gh release view "$tag" --repo "$repo" >/dev/null 2>&1; then
    gh release upload "$tag" "$dmg_path" --repo "$repo" --clobber
  else
    local title="${release_title:-ReportSimpleMDM ${tag}}"
    if [[ -n "$release_notes" ]]; then
      gh release create "$tag" "$dmg_path" --repo "$repo" --title "$title" --notes "$release_notes"
    else
      gh release create "$tag" "$dmg_path" --repo "$repo" --title "$title" --notes "Automated release for ${tag}."
    fi
  fi
}

publish_release "$primary_repo"

if [[ -n "$mirror_repo" ]]; then
  publish_release "$mirror_repo"
fi

printf 'Published %s to %s%s\n' \
  "$dmg_path" \
  "$primary_repo" \
  "${mirror_repo:+ and $mirror_repo}"
