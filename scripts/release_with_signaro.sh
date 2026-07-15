#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: release_with_signaro.sh --tag <release-tag> [options]

Required:
  --tag <tag>                Git tag / release tag to publish, e.g. v1.7.2-build12

Optional:
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
  --title <text>             GitHub release title used if the release does not exist yet
  --notes <text>             GitHub release notes used if the release does not exist yet
  --output-root <path>       Directory for staging and generated assets
                             Default: a temp directory under /private/tmp

The script stages the input app, runs SignaroCLI distribute app to sign/notarize/
staple it and create a DMG, then uploads a zip of the signed app bundle plus the
DMG to the requested GitHub release(s).
EOF
}

tag=""
app_path="/Users/helpdesk/Developer/Apps/ReportSimpleMDM.app"
keychain_profile="Jay_SIGNARO"
signing_identity="Developer ID Application: Jesus Ayala (N859JA9UCJ)"
primary_repo="hov172/ReportSimpleMDM"
mirror_repo="hov172/Report-SimpleMDM"
release_title=""
release_notes=""
output_root=""

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
  printf 'Missing required --tag.\n' >&2
  usage >&2
  exit 64
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

asset_base="ReportSimpleMDM-${tag}"
app_zip="$release_root/${asset_base}.app.zip"
rm -f "$app_zip"
ditto -c -k --keepParent "$staged_app" "$app_zip"

publish_release() {
  local repo="$1"
  if gh release view "$tag" --repo "$repo" >/dev/null 2>&1; then
    gh release upload "$tag" "$app_zip" "$dmg_path" --repo "$repo" --clobber
  else
    local title="${release_title:-ReportSimpleMDM ${tag}}"
    if [[ -n "$release_notes" ]]; then
      gh release create "$tag" "$app_zip" "$dmg_path" --repo "$repo" --title "$title" --notes "$release_notes"
    else
      gh release create "$tag" "$app_zip" "$dmg_path" --repo "$repo" --title "$title" --notes "Automated release for ${tag}."
    fi
  fi
}

publish_release "$primary_repo"

if [[ -n "$mirror_repo" ]]; then
  publish_release "$mirror_repo"
fi

printf 'Published %s and %s to %s%s\n' \
  "$app_zip" \
  "$dmg_path" \
  "$primary_repo" \
  "${mirror_repo:+ and $mirror_repo}"
