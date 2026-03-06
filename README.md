# elbe-demo-apt-repository-flat

Local **flat-layout** APT repository for the ELBE demo project. Holds custom
`.deb` packages that are installed into ELBE-built images.

> **Flat layout** means packages are stored directly in `repo/` alongside the
> APT index files. This is simpler to set up but **does not support**
> `elbe cyclonedx-sbom` (SBOM generation). Use
> [elbe-demo-apt-repository](../elbe-demo-apt-repository) (pool layout) if
> you need SBOM support.

## Quick start

```bash
# 1. Generate GPG signing keys (once, optional)
./gen-keys.sh

# 2. Copy .deb files into repo/
cp ../elbe-demo-pkg-hello/*.deb repo/

# 3. Build repository metadata
./build-repo.sh
```

## Using in ELBE XML

Add this to your ELBE image XML inside `<url-list>`:

```xml
<url-list>
  <url>
    <binary>file:///workspace/elbe-demo-apt-repository-flat/repo ./</binary>
    <key>file:///workspace/elbe-demo-apt-repository-flat/repo/repo-key.gpg</key>
  </url>
</url-list>
```

## Structure

```
elbe-demo-apt-repository-flat/
├── build-repo.sh      # Regenerate APT metadata from .deb files
├── gen-keys.sh        # Generate GPG key pair (run once, optional)
├── keys/              # GPG keys
│   ├── public.asc     # Public key (versioned)
│   └── private.gpg    # Private key (gitignored)
├── repo/              # Flat APT repository (generated)
│   ├── *.deb
│   ├── Packages
│   ├── Packages.gz
│   ├── Release
│   ├── Release.gpg    # Only present when GPG keys are configured
│   ├── InRelease      # Only present when GPG keys are configured
│   └── repo-key.gpg
└── README.md
```

## Prerequisites

All tools are available inside the ELBE dev container:

- `dpkg-scanpackages` (from `dpkg-dev`)
- `gpg`
- `gzip`
