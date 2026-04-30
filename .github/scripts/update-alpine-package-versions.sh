#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${repo_root}"

dockerfile="${repo_root}/Dockerfile"

tmpdir="$(mktemp -d)"
trap 'rm -rf "${tmpdir}"' EXIT

declare -A repo_index_files=()

# Prints the pinned Alpine version from the Dockerfile, for example 3.23.4.
get_alpine_version() {
  sed -rn 's/^FROM[[:space:]]+alpine:([0-9]+\.[0-9]+\.[0-9]+)$/\1/p' "${dockerfile}"
}

# Downloads the APKINDEX for the configured Alpine series and stores it locally.
# This reads the same repository metadata that `apk update` would refresh inside
# an Alpine container, but it avoids shelling out to apk in CI.
download_repo_indexes() {
  local alpine_series="$1"
  local arch="${ALPINE_ARCH:-x86_64}"
  local base_url="${ALPINE_MIRROR:-https://dl-cdn.alpinelinux.org/alpine}/v${alpine_series}"

  for repo in main community; do
    local archive="${tmpdir}/${repo}.tar.gz"
    local index_file="${tmpdir}/${repo}.APKINDEX"
    curl -fsSL "${base_url}/${repo}/${arch}/APKINDEX.tar.gz" -o "${archive}"
    tar -xOzf "${archive}" APKINDEX > "${index_file}"
    repo_index_files["${repo}"]="${index_file}"
  done
}

# Looks up the newest published version of a package in a downloaded APKINDEX.
lookup_version() {
  local package_name="$1"
  local repo_name="$2"
  local index_file="${repo_index_files[${repo_name}]}"

  awk -F: -v pkg="${package_name}" '
    $1 == "P" && $2 == pkg { found = 1; next }
    found && $1 == "V" { print $2; exit }
    /^$/ { found = 0 }
  ' "${index_file}"
}

# Extracts the Alpine-managed version pins from the Dockerfile into a TSV file:
# ARG_NAME, package name, repository, current version.
build_package_manifest() {
  local manifest_file="$1"

  awk '
    /^# alpine-package:/ {
      name = ""
      repo = ""
      split(substr($0, 18), fields, " ")
      for (i in fields) {
        split(fields[i], kv, "=")
        if (kv[1] == "name") {
          name = kv[2]
        } else if (kv[1] == "repo") {
          repo = kv[2]
        }
      }
      next
    }
    /^ARG [A-Z0-9_]+_VERSION=/ && name != "" && repo != "" {
      split($0, arg_parts, "[ =]")
      split($0, version_parts, "=")
      print arg_parts[2] "\t" name "\t" repo "\t" version_parts[2]
      name = ""
      repo = ""
    }
  ' "${dockerfile}" > "${manifest_file}"
}

# Compares pinned versions against the latest APKINDEX versions and writes only
# changed ARG assignments to a TSV file.
build_update_manifest() {
  local package_manifest="$1"
  local updates_file="$2"

  while IFS=$'\t' read -r arg_name package_name repo_name current_version; do
    local latest_version
    latest_version="$(lookup_version "${package_name}" "${repo_name}")"
    if [ -z "${latest_version}" ]; then
      echo "Could not find ${package_name} in ${repo_name}" >&2
      exit 1
    fi

    if [ "${latest_version}" != "${current_version}" ]; then
      printf '%s\t%s\n' "${arg_name}" "${latest_version}" >> "${updates_file}"
    fi
  done < "${package_manifest}"
}

# Applies the resolved version bumps to the Dockerfile in-place.
apply_updates() {
  local updates_file="$1"
  local rewritten_dockerfile="${tmpdir}/Dockerfile.new"

  cp "${dockerfile}" "${rewritten_dockerfile}"
  while IFS=$'\t' read -r arg_name latest_version; do
    sed -i -r "s#^(ARG ${arg_name}=).*#\\1${latest_version}#" "${rewritten_dockerfile}"
  done < "${updates_file}"
  mv "${rewritten_dockerfile}" "${dockerfile}"
}

alpine_version="$(get_alpine_version)"
if [ -z "${alpine_version}" ]; then
  echo "Could not determine Alpine version from Dockerfile" >&2
  exit 1
fi

download_repo_indexes "${alpine_version%.*}"

package_manifest="${tmpdir}/packages.tsv"
updates="${tmpdir}/updates.tsv"

build_package_manifest "${package_manifest}"
build_update_manifest "${package_manifest}" "${updates}"

if [ ! -s "${updates}" ]; then
  echo "No Alpine package updates found"
  exit 0
fi

apply_updates "${updates}"

# Keep the README package table aligned with the Dockerfile after any bump.
"${repo_root}/.github/scripts/sync-readme.sh"

echo "Updated Alpine package versions:"
cat "${updates}"
