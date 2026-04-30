#!/usr/bin/env bash

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${repo_root}"

# Extracts the Dockerfile dependency display names and versions in the same
# order the README package list expects.
get_version_lines() {
  awk '
    /^# alpine-package:/ {
      package_name = ""
      split(substr($0, 18), fields, " ")
      for (i in fields) {
        split(fields[i], kv, "=")
        if (kv[1] == "name") {
          package_name = kv[2]
        }
      }
      next
    }
    /^# renovate:/ {
      package_name = ""
      if (match($0, /depName=[^ ]+/)) {
        dep = substr($0, RSTART + 8, RLENGTH - 8)
        split(dep, dep_parts, "/")
        package_name = dep_parts[length(dep_parts)]
      }
      next
    }
    /^(ARG|ENV)[[:space:]]+[A-Z0-9_]+_VERSION(=|[[:space:]])/ {
      split($2, parts, "=")
      name = package_name
      if (name == "") {
        name = parts[1]
        sub(/_VERSION$/, "", name)
        name = tolower(name)
        gsub(/_/, "-", name)
      }
      print name " " parts[2]
      package_name = ""
    }
  ' Dockerfile
}

# Rewrites the package list entries in README.md so they match the Dockerfile.
sync_package_versions() {
  mapfile -t lines < <(get_version_lines)
  for l in "${lines[@]}"; do
    local name="${l% *}"
    local ver="${l#* }"
    perl -0pi -e "s{(^- *\\Q${name}\\E)( .*|\$)}{\$1 (${ver})}mg" README.md
  done
}

# Rewrites the documented Alpine base version in README.md.
sync_alpine_version() {
  local ver
  ver="$(sed -rn 's/^FROM[[:space:]]+alpine:(.*)$/\1/p' Dockerfile)"
  [ -n "${ver}" ] && perl -0pi -e "s{(alpine linux )\\([^)]*\\)( with)}{\$1(${ver})\$2}img" README.md
}

sync_package_versions
sync_alpine_version
