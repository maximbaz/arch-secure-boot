# UEFI Secure Boot for Arch Linux + btrfs snapshot recovery

## Installation

The package is available on AUR: [arch-secure-boot](https://aur.archlinux.org/packages/arch-secure-boot/)

## Configuration

See the available configuration options in the top of the script.
Add your overrides to `/etc/arch-secure-boot/config`.

## Commands

- `arch-secure-boot generate-keys` generates new keys for Secure Boot
- `arch-secure-boot enroll-keys` adds them to your UEFI
- `arch-secure-boot generate-efi` creates several images signed with Secure Boot keys
- `arch-secure-boot add-efi` adds UEFI entry for the main Secure Boot image
- `arch-secure-boot generate-snapshots` generates a list of btrfs snapshots for recovery
- `arch-secure-boot initial-setup` runs all the steps in the proper order

## Generated images

- `secure-boot-linux.efi` - the main image
  - `vmlinuz-linux` + `initramfs-linux` + `*-ucode` + hardcoded `cmdline`
- `secure-boot-linux-efi-shell.efi` - UEFI shell that is used to boot into a snapshot
  - needed only because default Dell UEFI shell is buggy
- `secure-boot-linux-recovery.efi` - recovery image that can be a used to boot from snapshot
  - `vmlinuz-linux` + `initramfs-linux-fallback`
- `secure-boot-linux-lts-recovery.efi` - recovery LTS image that can be used to boot from snapshot
  - `vmlinuz-linux-lts` + `initramfs-linux-lts-fallback`

`fwupdx64.efi` image is also being signed.

## Initial setup

- BIOS: Set admin password, disable Secure Boot, delete all Secure Boot keys
- Generate and enroll keys
- Generate EFI images and add the main one (only!) to UEFI
- BIOS: Enable Secure Boot

## Recovery instructions

- BIOS: use admin password to boot into `efi-shell` image
- Inspect recovery script using `edit FS0:\recovery.nsh` (if `FS0` is not your hard disk, try other `FSn`)
- Run the script using `FS0:\recovery.nsh`
- Once recovered, remove `efi-shell` entry from UEFI

## Related links:

- https://github.com/gdamjan/secure-boot
- https://github.com/andreyv/sbupdate/
