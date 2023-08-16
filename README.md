# Inspired by [Universal Blue](https://github.com/ublue-os)

Intended for my own personal learning and use

# Starts from stock [Silverblue](https://quay.io/repository/fedora-ostree-desktops/silverblue?tab=tags) image and installs:
- Nvidia driver
- OpenZFS 2
- [v4l2loopback](https://github.com/umlaeute/v4l2loopback)
# removes:
- firefox
- gnome-software

```shell
rpm-ostree rebase --reboot ostree-unverified-registry:ghcr.io/kth8/silverblue:latest
rpm-ostree rebase --reboot ostree-image-signed:docker://ghcr.io/kth8/silverblue:latest
```

### Set kargs after rebasing

Setting kargs to disable nouveau and enabling nvidia early at boot is [currently not supported within container builds](https://github.com/coreos/rpm-ostree/issues/3738). They must be set after rebasing:

```shell
rpm-ostree kargs \
    --append-if-missing=rd.driver.blacklist=nouveau \
    --append-if-missing=modprobe.blacklist=nouveau \
    --append-if-missing=nvidia-drm.modeset=1 \
    --delete=nomodeset
```
### Video playback

Additional runtime packages are added for enabling hardware-accelerated video playback. This can the enabled in Firefox (RPM or flatpak) by setting the following options to `true` in `about:config`:

* `gfx.webrender.all`
* `media.ffmpeg.vaapi.enabled`
* `widget.dmabuf.force-enabled`

Extensive host access and reduced sandboxing is needed for Firefox flatpak to use `/usr/lib64/dri/nvidia_drv_video.so`:

```shell
flatpak override \
    --user \
    --filesystem=host-os \
    --env=LIBVA_DRIVER_NAME=nvidia \
    --env=LIBVA_DRIVERS_PATH=/run/host/usr/lib64/dri \
    --env=LIBVA_MESSAGING_LEVEL=1 \
    --env=MOZ_DISABLE_RDD_SANDBOX=1 \
    --env=NVD_BACKEND=direct \
    --env=MOZ_ENABLE_WAYLAND=1 \
    org.mozilla.firefox
```

### To revert back

```shell
rpm-ostree rebase --reboot fedora:fedora/38/x86_64/silverblue
```

## Verification

These images are signed with sigstore's [cosign](https://docs.sigstore.dev/cosign/overview/). You can verify the signature by downloading the `cosign.pub` key from this repo and running the following command:

```shell
cosign verify --key cosign.pub ghcr.io/kth8/silverblue:latest
```
