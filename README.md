# UEFI Secure Boot for Arch Linux + btrfs snapshot recovery

Highly opinionated setup that provides minimal Secure Boot for Arch Linux, and a few recovery tools.

Bootloaders (such as `GRUB` or `systemd-boot`) are intentionally not supported, as they significantly increase the amount of code that runs during boot, therefore increasing the attack surface.

## Motivation

There are two key goals that motivated this project:

1. Achieve encrypted `/boot` without using GRUB (it is possible, contrary to popular belief)
2. Minimize amount of code that runs during boot (less code means less vulnerabilities to guard against)

Here's how it works:

1. Remove built-in Secure Boot keys, generate your own keys, leave private key on encrypted disk and register public key in BIOS
2. Keep `/boot` on encrypted disk, and mount unencrypted ESP FAT32 partition to `/efi`.
3. Generate a new `.efi` file that you will register in BIOS as boot target (i.e. instead of `grub.efi`), which consists of:

   - CPU microcode (`ucode.img`)
   - initramfs
   - vmlinuz
   - hardcoded kernel cmdline (that specifies exact kernel arguments to boot, including root btrfs subvolume)

   All of the above components are taken from the encrypted `/boot`, so cannot be tampered with while the computer is turned off.

4. Sign this `.efi` file with your own Secure Boot key and put this one file into unencrypted `/efi`.
5. Configure in your BIOS that this is the boot target (instead of e.g. GRUB)

Now evil-maid attack is not possible, because the only unencrypted file is your signed `.efi` file, and if it is being tampered with, Secure Boot will refuse to load it.

Because cmdline is hardcoded in the image, Secure Boot also guarantees that you or attackers cannot just change it (e.g. to boot in an old subvolume).

In addition, because there is less steps in the process, and especially because you aren't decrypting your disk twice (like it is the case with GRUB), the boot is so much faster!

This project automates everything above, and adds a few other integrations that I personally use:

- pacman hooks (similar to `snap-pac-grub`, so I can enable the tool and forget about it)
- integration with `fwupd`
- custom EFI shell (because at least Dell's built-in implementation was quite buggy at the time of creating the project)
- a simple script that provides UI for selecting snapshot to boot into (inspired by `grub-btrfs`)

## Installation

The package is available on AUR: [arch-secure-boot](https://aur.archlinux.org/packages/arch-secure-boot/)

## Configuration

See the available configuration options in the top of the script.

Add your overrides to `/etc/arch-secure-boot/config`.

Most notably, set `KERNEL=linux-hardened` if you use hardened Linux.

## Initial setup

- BIOS: Set admin password, disable Secure Boot, delete all Secure Boot keys
- Run `arch-secure-boot initial-setup` command, which:
  - Generates and enrolls keys
  - Generates EFI images and adds the main one to UEFI **(it's important, only the main one!)**
- BIOS: Enable Secure Boot

Note: If you want to preserve Microsoft Secure-Boot keys, don't use the `initial-setup` command above as will replace them. Instead, look in the source code to see which commands `initial-setup` executes and run them by hand, replacing `enroll-keys` entirely with `sbctl enroll-keys -m`. This hasn't been tested, but is assumed to work (see [#31](https://github.com/maximbaz/arch-secure-boot/issues/31)).

If enrolling keys via `initial-setup` does not work, it might be caused by a bad implementation of UEFI by the manufacturer. In this case, you can try to go to UEFI, enable Setup Mode and enroll the keys from the GUI. Follow [Arch wiki](https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot#Enrolling_keys_in_firmware) for some steps, and pay particular attention not to place Platform Key on the ESP partition, even temporarily!

## Recovery concept

When the system fails to boot, it is commonly caused by one of the two things:

1. Something is wrong on the system (late boot), which might be resolved by booting in a btrfs snapshot.
2. Something is wrong with the kernel (early boot), which might be resolved by booting in an LTS kernel.

That is why, in addition to generating the main image (which is added to your UEFI as boot target), this project generates two more `.efi` files:

1. One with:

   - initramfs
   - vmlinuz
   - NO microcode (in case it causes boot failures)
   - NO hardcoded cmdline (so that we can later select which subvolume to boot in)

2. Another just like the above, but with LTS kernel

These two are also signed with Secure Boot keys, but **NOT** added to UEFI boot targets.

- Attackers cannot use these `.efi` files because to boot into it they need to know your BIOS password.
- Evil maid attack is not possible because this image is signed with Secure Boot keys and at no point in time do we disable Secure Boot.
- Because `cmdline` is NOT hardcoded in these recovery images, Secure Boot will let us specify a custom one - one where you specify `rootflags=subvol=snapshots/123/snapshot` in order to boot into snapshot `123`.

In order to avoid typing a custom cmdline by hand, this project provides a simple `recovery.nsh` script that allows you to select a snapshot to boot into - DO inspect it before launching, as it is stored on unencrypted `/efi` partition when you need to use it.

## Recovery instructions

- BIOS: use admin password to boot into `efi-shell` image
- Inspect recovery script using `edit FS0:\recovery.nsh` (if `FS0` is not your hard disk, try other `FSn`)
- Run the script using `FS0:\recovery.nsh`
- Once recovered, remove `efi-shell` entry from UEFI

## Commands

- `arch-secure-boot initial-setup` runs all the steps below in the proper order
- `arch-secure-boot generate-keys` generates new keys for Secure Boot
- `arch-secure-boot enroll-keys` adds them to your UEFI
- `arch-secure-boot generate-efi` creates several images signed with Secure Boot keys
- `arch-secure-boot add-efi` adds UEFI entry for the main Secure Boot image
- `arch-secure-boot generate-snapshots` generates a list of btrfs snapshots for recovery

## Generated images

- `secure-boot-linux.efi` - the main image
  - `vmlinuz-linux` + `initramfs-linux` + `*-ucode` + hardcoded `cmdline`
- `secure-boot-linux-efi-shell.efi` - UEFI shell that is used to boot into a snapshot
  - because built-in UEFI shells are known to be buggy
- `secure-boot-linux-recovery.efi` - recovery image that can be a used to boot from snapshot
  - `vmlinuz-linux` + `initramfs-linux-fallback`
- `secure-boot-linux-lts-recovery.efi` - recovery LTS image that can be used to boot from snapshot
  - `vmlinuz-linux-lts` + `initramfs-linux-lts-fallback`

`fwupdx64.efi` image is also being signed.

## Related links:

- https://github.com/gdamjan/secure-boot
- https://github.com/andreyv/sbupdate
