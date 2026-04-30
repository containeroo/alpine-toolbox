#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${repo_root}"

dockerfile="${repo_root}/Dockerfile"
update_report_file="${ALPINE_UPDATE_REPORT_FILE:-}"

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

# Resolves a package version using the preferred repo first, then falls back to
# the other downloaded repos if the package moved or the repo hint is stale.
resolve_version() {
  local package_name="$1"
  local preferred_repo="$2"
  local latest_version

  latest_version="$(lookup_version "${package_name}" "${preferred_repo}")"
  if [ -n "${latest_version}" ]; then
    printf '%s\t%s\n' "${preferred_repo}" "${latest_version}"
    return 0
  fi

  for repo_name in "${!repo_index_files[@]}"; do
    if [ "${repo_name}" = "${preferred_repo}" ]; then
      continue
    fi

    latest_version="$(lookup_version "${package_name}" "${repo_name}")"
    if [ -n "${latest_version}" ]; then
      echo "Package ${package_name} was not found in ${preferred_repo}; using ${repo_name}" >&2
      printf '%s\t%s\n' "${repo_name}" "${latest_version}"
      return 0
    fi
  done

  return 1
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
# changed packages to a TSV file including the old and new version.
build_update_manifest() {
  local package_manifest="$1"
  local updates_file="$2"

  while IFS=$'\t' read -r arg_name package_name repo_name current_version; do
    local resolved resolved_repo latest_version
    resolved="$(resolve_version "${package_name}" "${repo_name}")"
    if [ -z "${resolved}" ]; then
      echo "Could not find ${package_name} in ${repo_name} or any configured Alpine repo" >&2
      exit 1
    fi
    resolved_repo="${resolved%%$'\t'*}"
    latest_version="${resolved#*$'\t'}"

    if [ "${latest_version}" != "${current_version}" ]; then
      printf '%s\t%s\t%s\t%s\t%s\n' \
        "${arg_name}" \
        "${package_name}" \
        "${current_version}" \
        "${latest_version}" \
        "${resolved_repo}" >> "${updates_file}"
    fi
  done < "${package_manifest}"
}

# Applies the resolved version bumps to the Dockerfile in-place.
apply_updates() {
  local updates_file="$1"
  local rewritten_dockerfile="${tmpdir}/Dockerfile.new"

  cp "${dockerfile}" "${rewritten_dockerfile}"
  while IFS=$'\t' read -r arg_name _package_name _current_version latest_version _repo_name; do
    sed -i -r "s#^(ARG ${arg_name}=).*#\\1${latest_version}#" "${rewritten_dockerfile}"
  done < "${updates_file}"
  mv "${rewritten_dockerfile}" "${dockerfile}"
}

# Writes a Markdown table for the PR body so version changes are easy to review.
write_update_report() {
  local updates_file="$1"
  local report_file="$2"

  {
    echo "| Package | From | To | Repo |"
    echo "| --- | --- | --- | --- |"
    while IFS=$'\t' read -r _arg_name package_name current_version latest_version repo_name; do
      printf '| `%s` | `%s` | `%s` | `%s` |\n' \
        "${package_name}" \
        "${current_version}" \
        "${latest_version}" \
        "${repo_name}"
    done < "${updates_file}"
  } > "${report_file}"
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

if [ -n "${update_report_file}" ]; then
  write_update_report "${updates}" "${update_report_file}"
fi

echo "Updated Alpine package versions:"
cat "${updates}"
