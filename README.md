# nginx-mod-nchan COPR Build Repository

This repository automates building nginx-mod-nchan packages for Fedora COPR, always using:
- The latest nginx version available in Fedora repositories
- The latest nchan code from GitHub master branch
- Official Fedora nginx patches

## Features

- **Dynamic nginx version detection**: Queries Fedora repos for the current nginx version
- **Latest nchan**: Clones directly from GitHub master branch
- **Fedora patches**: Extracts patches from the official Fedora nginx SRPM
- **Restart support**: Uses `systemctl restart` instead of reload (nchan limitation)
- **COPR integration**: Fully automated builds via `.copr/Makefile`

## How It Works

1. The COPR Makefile queries DNF to find the current nginx version in Fedora
2. Downloads the nginx SRPM from Fedora and extracts patches
3. Downloads the nginx source tarball
4. Clones the latest nchan from GitHub
5. Generates a spec file with all correct versions
6. Builds the SRPM for COPR

## COPR Setup

1. Create a new COPR project at https://copr.fedorainfracloud.org/
2. Enable "Internet access during builds" in project settings
3. Set the source type to "Custom (SCM method)"
4. Set the SCM URL to this GitHub repository
5. Set the build method to "make srpm"

## Local Testing

To test the build locally:

```bash
cd .copr
make srpm outdir=.
```

This will:
- Query the current nginx version
- Download all required sources
- Generate the spec file
- Build the SRPM

## Requirements

The build environment needs:
- `dnf` with repoquery plugin
- `rpm-build`
- `git`
- `curl`
- `cpio`
- Internet access to:
  - Fedora repositories
  - nginx.org
  - github.com

## Notes

- The spec file is generated dynamically during build
- nginx version is never hardcoded - always pulled from Fedora
- nchan is always built from the latest git commit
- Patches are extracted from Fedora's nginx SRPM to ensure compatibility
- The package uses `systemctl restart` in %post because nchan doesn't support reload

## Troubleshooting

If the nginx version cannot be detected, the Makefile falls back to version 1.26.2.

If nginx.org doesn't have the exact version from Fedora, you may need to adjust the fallback version in the Makefile.

## License

The build scripts are provided as-is. nchan is licensed under MIT, nginx under 2-clause BSD.