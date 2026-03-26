# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a custom Fedora Atomic OS image based on [Bluefin DX](https://github.com/ublue-os/bluefin) with DisplayLink support for multi-screen docking stations. It uses the [BlueBuild](https://blue-build.org) framework to build container-based OS images.

**Base Image**: `ghcr.io/ublue-os/bluefin-dx:latest`
**Output Image**: `ghcr.io/evilpandas/evilpandas-os:latest`

## Build System

### Building the Image

The image is built automatically via GitHub Actions on:
- Daily schedule at 06:00 UTC (20 minutes after ublue images build)
- Push to main branch (excluding markdown-only changes)
- Pull requests
- Manual workflow dispatch

To trigger a manual build:
```bash
# Via GitHub web interface: Actions → bluebuild → Run workflow
```

### Local Testing

BlueBuild does not support local builds easily. To test changes:
1. Push to a branch
2. Open a PR (this triggers a build)
3. Check the GitHub Actions build logs for errors

### Validating Recipe Syntax

BlueBuild recipe files follow a specific YAML schema. Check the [BlueBuild documentation](https://blue-build.org) for module syntax.

## Architecture

### Recipe Structure (`recipes/recipe.yml`)

The recipe is the core configuration file that defines:
- Base image and metadata
- Modules to apply during build (containerfile snippets, scripts, etc.)

**Critical**: This recipe uses a complex multi-stage installation process for DisplayLink drivers due to akmod build requirements. The process is:
1. Add Negativo17 multimedia repository
2. Install kernel-devel, kernel-headers, kernel-core, akmods
3. Install libevdi (without akmod-evdi)
4. Download DisplayLink packages with `dnf download --resolve`
5. Install packages with `--noscripts` to prevent premature akmod builds
6. Manually trigger `akmods --force` to build evdi kernel module
7. Install the resulting kmod-evdi RPM to integrate module into ostree image

**Key points**:
- akmods builds a kmod-evdi RPM in `/usr/src/akmods/` that must be explicitly installed
- The module must be in `/lib/modules/$(uname -r)/` for the ostree image
- `depmod -a` must run to update module dependencies
- **Do not simplify or reorder these steps** without testing thoroughly

### Directory Structure

```
recipes/
  └── recipe.yml          # Main BlueBuild recipe file
files/
  ├── scripts/            # Shell scripts executed during image build
  │   ├── displaylink-fix.sh  # Enables DisplayLink service & configures evdi
  │   └── example.sh      # Template for new scripts
  └── system/
      ├── etc/            # Files to overlay into /etc
      └── usr/            # Files to overlay into /usr
modules/                  # For custom BlueBuild modules (currently unused)
.github/workflows/
  └── build.yml           # GitHub Actions build workflow
```

### Scripts (`files/scripts/`)

Scripts referenced in `recipe.yml` run during image build. They must:
- Include `set -oue pipefail` for proper error handling
- Exit cleanly (non-zero exit codes fail the build)
- Be executable (checked by Git)

Current scripts:
- **displaylink-fix.sh**: Enables displaylink.service, configures evdi module parameters, sets up udev rules for DisplayLink USB devices (vendor ID 17e9)

## DisplayLink Configuration

The image includes DisplayLink support via:
- **akmod-evdi**: Kernel module for EVDI (Extensible Virtual Display Interface)
- **libevdi**: Userspace library
- **displaylink**: DisplayLink manager daemon

Post-install configuration (in displaylink-fix.sh):
- Service: `systemctl enable displaylink.service`
- Module options: `options evdi initial_device_count=4` in `/etc/modprobe.d/evdi.conf`
- Udev rule: Auto-starts displaylink.service when USB vendor 17e9 devices connect

## Testing and Deployment

### After Building

Images are signed with cosign. To verify:
```bash
cosign verify --key cosign.pub ghcr.io/evilpandas/evilpandas-os
```

### Installing on a System

```bash
# First rebase (unsigned, to install signing keys)
sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/evilpandas/evilpandas-os:latest
sudo systemctl reboot

# Then rebase to signed image
sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/evilpandas/evilpandas-os:latest
sudo systemctl reboot
```

### Rollback

```bash
# After booting into new deployment
sudo rpm-ostree rollback
sudo systemctl reboot

# Before rebooting (cancel pending deployment)
sudo rpm-ostree cancel
```

### Verifying DisplayLink

```bash
# Check service status
systemctl status displaylink.service

# Check kernel module
lsmod | grep evdi

# Check logs
journalctl -u displaylink.service
```

## Troubleshooting

### DisplayLink Service Fails: "modprobe evdi" Error

**Symptoms**: `systemctl status displaylink` shows enabled but failed with `ExecStartPre=/sbin/modprobe evdi (code=exited, status=1/FAILURE)` and `lsmod | grep evdi` returns nothing.

**Root cause**: The evdi kernel module wasn't built or installed correctly during image build.

**Solution**: The recipe must:
1. Build the module with akmods (creates kmod-evdi RPM)
2. Install the resulting kmod-evdi RPM from `/usr/src/akmods/`
3. Run `depmod -a` to update module dependencies
4. Verify with `modinfo evdi`

Check the GitHub Actions build logs for:
- "Building evdi module for kernel X.X.X"
- "Looking for built kmod RPM:"
- "Installing kmod-evdi RPM:"
- "Verifying module installation:"

If any of these steps fail in the logs, the module won't be available at runtime.

## Important Notes

- This is an **ostree-based atomic OS**: Changes require image rebuilds, not package installs
- The BlueBuild GitHub Action (v1.10) handles all build complexity
- Recipe changes require testing via PR builds (no local build support)
- DisplayLink driver installation is fragile due to akmod + root user + ostree constraints
- Never modify the DisplayLink installation sequence without testing thoroughly
