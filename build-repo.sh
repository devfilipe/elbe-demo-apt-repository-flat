#!/usr/bin/env bash
# build-repo.sh — (Re)generate APT repository metadata (flat layout).
#
# Packages are stored directly in repo/ (no pool subdirectory structure).
# This is simpler but SBOM generation via elbe cyclonedx-sbom is NOT
# supported for packages from flat repos.
#
# Prerequisites: dpkg-dev, gzip, gpg
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="${SCRIPT_DIR}/repo"
GNUPG_HOME="${SCRIPT_DIR}/.gnupg"
KEYS_DIR="${SCRIPT_DIR}/keys"

if [ ! -d "${REPO_DIR}" ]; then
    echo "Error: repo/ directory not found."
    exit 1
fi

DEB_COUNT=$(find "${REPO_DIR}" -maxdepth 1 -name '*.deb' | wc -l)
SRC_COUNT=$(find "${REPO_DIR}" -maxdepth 1 -name '*.dsc' | wc -l)

SIGN=false
if [ -f "${KEYS_DIR}/private.gpg" ]; then
    SIGN=true
    gpg --homedir "${GNUPG_HOME}" --batch --import "${KEYS_DIR}/private.gpg" 2>/dev/null || true
    KEY_EMAIL="${1:-$(gpg --homedir "${GNUPG_HOME}" --batch --list-secret-keys --with-colons 2>/dev/null | grep '^uid' | head -1 | cut -d: -f10 | grep -oP '<\K[^>]+' || echo "elbe-demo@local")}"
else
    echo "Warning: No GPG private key found — generating unsigned index (requires [trusted=yes] in APT source)."
fi

echo "Scanning .deb packages (flat layout)..."
cd "${REPO_DIR}"

if [ "${DEB_COUNT}" -gt 0 ]; then
    dpkg-scanpackages --multiversion . > Packages
else
    : > Packages
fi
gzip -9c Packages > Packages.gz

if [ "${SRC_COUNT}" -gt 0 ]; then
    dpkg-scansources . > Sources
    gzip -9c Sources > Sources.gz
else
    : > Sources
    gzip -9c Sources > Sources.gz
fi

echo "Generating Release file..."
cat > Release <<EOF
Origin: elbe-demo-flat
Label: ELBE Demo Flat Repository
Suite: stable
Codename: local
Architectures: amd64 arm64 armhf all
Components: .
Description: Local flat APT repository (no pool layout, SBOM not supported)
EOF

INDEX_FILES="Packages Packages.gz Sources Sources.gz"
{
    echo "MD5Sum:"
    for f in ${INDEX_FILES}; do
        [ -f "$f" ] && echo " $(md5sum "$f" | cut -d' ' -f1) $(wc -c < "$f") $f"
    done
    echo "SHA256:"
    for f in ${INDEX_FILES}; do
        [ -f "$f" ] && echo " $(sha256sum "$f" | cut -d' ' -f1) $(wc -c < "$f") $f"
    done
} >> Release

if [ "${SIGN}" = "true" ]; then
    echo "Signing repository..."
    gpg --homedir "${GNUPG_HOME}" --batch --yes --default-key "${KEY_EMAIL}" \
        --armor --detach-sign --output Release.gpg Release
    gpg --homedir "${GNUPG_HOME}" --batch --yes --default-key "${KEY_EMAIL}" \
        --armor --clearsign --output InRelease Release
    gpg --homedir "${GNUPG_HOME}" --export "${KEY_EMAIL}" > repo-key.gpg
else
    rm -f InRelease Release.gpg
fi

echo ""
echo "Repository updated successfully (flat layout)."
echo "  Binary packages: ${DEB_COUNT}"
echo "  Source packages: ${SRC_COUNT}"
echo "  Note: SBOM generation requires pool layout repos."
