# alpine-toolbox

## Description

Alpine Toolbox is a minimal Docker image based on Alpine Linux, designed to provide a lightweight and efficient environment for various command-line tasks. It includes essential tools and utilities commonly used in development, scripting, and system administration as well as debugging and testing.

## Images & tags

We publish two variants so you can choose what fits your platform:

- **Non-root (OpenShift-friendly)**
  Tags: `ghcr.io/containeroo/alpine-toolbox:latest`, `ghcr.io/containeroo/alpine-toolbox:<version>`
  - Runs as **UID 10001, GID 0** by default.
  - Compatible with vanilla Kubernetes and OpenShift restricted policies.
  - Best for production and clusters that require non-root.
  - Runtime `apk add` is **not** supported (install at build time or use user-space binaries).

- **Root (runtime installs)**
  Tags: `ghcr.io/containeroo/alpine-toolbox:root`, `ghcr.io/containeroo/alpine-toolbox:<version>-root`
  - Runs as **root** by default.
  - Allows `apk add` at **runtime**.
  - On OpenShift you’ll need an SCC that allows root (e.g., `anyuid`).

### Quick start

```bash
# Non-root (recommended)
docker run --rm -it ghcr.io/containeroo/alpine-toolbox:latest sh

# Root (allows runtime apk)
docker run --rm -it ghcr.io/containeroo/alpine-toolbox:root sh
```

## Packages

alpine linux (3.22.1) with following components:

- bash (5.2.37-r0)
- bind-tools (9.20.13-r0)
- catatonit (0.2.1)
- coreutils (9.7-r1)
- curl (8.14.1-r1)
- gettext (0.24.1-r0)
- git (2.49.1-r0)
- inetutils-telnet (2.6-r0)
- jq (1.8.0-r0)
- openssl (3.5.2-r0)
- rsync (3.4.1-r0)
- tzdata (2025b-r0)
- xmlstarlet (1.6.1-r2)
- yq (4.47.1)

> The list and versions are auto-updated by CI from the Dockerfile.

## Package missing?

Feel free to create an issue or a pull request to add any missing package you need. Please keep the image small and follow naming conventions.

## User & Group Model (Why UID `10001` and Group `0`)

This image is built to run safely as **non-root** on vanilla Kubernetes **and** OpenShift, while still allowing write access where needed.

### Why UID `10001`?

- **Non-root by default.** Using a fixed, high, non-system UID like `10001` makes the image safe in vanilla Kubernetes and most CI/CD runners without extra flags.
- **Low collision risk.** High UIDs are unlikely to clash with host/system accounts inside the container.
- **Portable.** In OpenShift, the platform may **override** the UID at runtime with an arbitrary, non-root UID. Starting from a non-root UID keeps behavior consistent across platforms.

> TL;DR: `10001` is a conventional, stable, non-root choice that works everywhere. OpenShift can still inject its own arbitrary UID at runtime.

### Why Group `0` (root group)?

- **Arbitrary-UID compatibility (OpenShift).** OpenShift commonly runs containers with a **random non-root UID**, and includes **group 0** in the process’s groups.
- **Make dirs group-writable.** If your writable paths are **group-owned by `0`** and have **group-write** permissions, the arbitrary UID can still write there because it’s in group 0.
- **No special privileges.** Being in **group 0 ≠ root**. Privileges come from UID 0 or Linux capabilities, not from the group number. We also drop capabilities in the pod security context.

> TL;DR: chown/chgrp writable paths to **group 0** and set **`g+w`**. That’s the standard pattern to make images “arbitrary-UID friendly” for OpenShift while remaining safe elsewhere.
