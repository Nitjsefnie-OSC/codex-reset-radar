#!/usr/bin/env bash
# Prints the body of the CHANGELOG.md section for a version (e.g. 0.1.0), without its heading.
# Prints nothing and exits 0 when the section is missing or empty, so callers can fall back.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION=${1:?usage: changelog-section.sh <version>}
[ -f CHANGELOG.md ] || exit 0

awk -v version="$VERSION" '
    /^## / {
        if (found) exit
        found = index($0, "## [" version "]") == 1
        next
    }
    /^\[[^]]+\]: / { if (found) exit }
    found { print }
' CHANGELOG.md | awk '
    NF { started = 1 }
    started { lines[++n] = $0 }
    END {
        while (n > 0 && lines[n] !~ /[^[:space:]]/) n--
        for (i = 1; i <= n; i++) print lines[i]
    }
'
