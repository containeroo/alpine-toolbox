# alpine-toolbox

## Description

Alpine Toolbox is a minimal Docker image based on Alpine Linux, designed to provide a lightweight and efficient environment for various command-line tasks. It includes essential tools and utilities commonly used in development, scripting, and system administration as well as debugging and testing.

## Packages

alpine linux (3.21.3) with following components:

- bash (5.2.37-r0)
- bind-tools (9.18.24-r1)
- catatonit (0.2.1)
- coreutils (9.5-r2)
- curl (8.12.1-r1)
- gettext (0.22.5-r0)
- inettools-telnet (2.4-r0)
- jq (1.7.1-r0)
- openssl (3.3.3-r0)
- rsync (3.4.0-r0)
- tzdata (2025b-r0)
- xmlstarlet (1.6.1-r2)
- yq (4.45.1)

## Package missing?

Feel free to create an issue or a pull request to add any missing package you need. You can also create a pull request to add any new package you want to be included in the image. Please make sure to follow the naming conventions and keep the image size as small as possible.

### User & Group Model (Why UID `10001` and Group `0`)

This image is built to run safely as **non-root** on vanilla Kubernetes **and** OpenShift, while still allowing write access where needed.

### Why UID `10001`?

- **Non-root by default.** Using a fixed, high, non-system UID like `10001` makes the image safe in vanilla Kubernetes and most CI/CD runners without extra flags.
- **Low collision risk.** High UIDs are unlikely to clash with host/system accounts inside the container.
- **Portable.** In OpenShift, the platform may **override** the UID at runtime with an arbitrary, non-root UID. Starting from a non-root UID keeps behavior consistent across platforms.

> TL;DR: `10001` is just a conventional, stable, non-root choice that works everywhere. OpenShift can still inject its own arbitrary UID at runtime.

### Why Group `0` (root group)?

- **Arbitrary-UID compatibility (OpenShift).** OpenShift commonly runs containers with a **random non-root UID**, and (by convention) includes **group 0** in the process’s groups.
- **Make dirs group-writable.** If your writable paths are **group-owned by `0`** and have **group-write** permissions, the arbitrary UID can still write there because it’s in group 0.
- **No special privileges.** Being in **group 0 ≠ root**. Privileges come from UID 0 or Linux capabilities, not from the group number. We also drop capabilities in the pod security context.

> TL;DR: Chown/chgrp writable paths to **group 0** and set **`g+w`**. That’s the standard pattern to make images “arbitrary-UID friendly” for OpenShift while remaining safe elsewhere.
