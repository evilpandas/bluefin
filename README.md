# evilpandas-os &nbsp; [![bluebuild build badge](https://github.com/evilpandas/bluefin/actions/workflows/build.yml/badge.svg)](https://github.com/evilpandas/bluefin/actions/workflows/build.yml)

A custom Bluefin OS image with DisplayLink support for multi-screen docking stations.

This image is based on [Bluefin DX](https://github.com/ublue-os/bluefin) and includes:
- DisplayLink driver and manager
- EVDI kernel modules for DisplayLink support
- Kernel development tools needed for module compilation
- Automatic DisplayLink service configuration

See the [BlueBuild docs](https://blue-build.org/how-to/setup/) for more information about BlueBuild.

## Installation

> [!WARNING]  
> [This is an experimental feature](https://www.fedoraproject.org/wiki/Changes/OstreeNativeContainerStable), try at your own discretion.
> 
> **Important**: Make sure to save your work before rebasing, as this process will replace your current OS deployment.

To rebase an existing atomic Fedora installation to the latest build:

- First rebase to the unsigned image, to get the proper signing keys and policies installed:
  ```bash
  sudo rpm-ostree rebase ostree-unverified-registry:ghcr.io/evilpandas/evilpandas-os:latest
  ```
- Reboot to complete the rebase:
  ```bash
  sudo systemctl reboot
  ```
- Then rebase to the signed image, like so:
  ```bash
  sudo rpm-ostree rebase ostree-image-signed:docker://ghcr.io/evilpandas/evilpandas-os:latest
  ```
- Reboot again to complete the installation
  ```bash
  sudo systemctl reboot
  ```

The `latest` tag will automatically point to the latest build. That build will still always use the Fedora version specified in `recipe.yml`, so you won't get accidentally updated to the next major version.

## Rollback / Fallback

If the rebase fails or you encounter issues, you can easily rollback to your previous deployment:

### Rollback to Previous Deployment

If you've already rebooted into the new deployment and want to go back:

```bash
sudo rpm-ostree rollback
sudo systemctl reboot
```

### Rollback Before Reboot

If the rebase command succeeded but you haven't rebooted yet, you can cancel it:

```bash
# Check the current deployment status
rpm-ostree status

# Reset to the current deployment (cancels the pending rebase)
sudo rpm-ostree cancel
```

### Rollback During Boot (if system won't boot)

If your system fails to boot after a rebase:

1. At the boot menu (GRUB), select "Boot from previously booted entry" or select the previous deployment from the menu
2. Once booted, you can make the rollback permanent:
   ```bash
   sudo rpm-ostree rollback
   sudo systemctl reboot
   ```

### Verify Current Deployment

To check which deployment you're currently on:

```bash
rpm-ostree status
```

This will show you:
- The current booted deployment (marked with `*`)
- All available deployments
- Pending changes (if any)

### Troubleshooting

If you experience issues:

1. **Check deployment status**: `rpm-ostree status`
2. **View logs**: `journalctl -b` (current boot) or `journalctl -b -1` (previous boot)
3. **Check for DisplayLink**: `systemctl status displaylink.service` and `lsmod | grep evdi`
4. **Rollback if needed**: Use the rollback commands above

## ISO

If build on Fedora Atomic, you can generate an offline ISO with the instructions available [here](https://blue-build.org/learn/universal-blue/#fresh-install-from-an-iso). These ISOs cannot unfortunately be distributed on GitHub for free due to large sizes, so for public projects something else has to be used for hosting.

## Verification

These images are signed with [Sigstore](https://www.sigstore.dev/)'s [cosign](https://github.com/sigstore/cosign). You can verify the signature by downloading the `cosign.pub` file from this repo and running the following command:

```bash
cosign verify --key cosign.pub ghcr.io/evilpandas/evilpandas-os
```
