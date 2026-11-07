# Updating WhateverXe

WhateverXe has **two halves that must match**. Update both together:

1. **`WhateverXe.kext`** lives in the EFI (`EFI/OC/Kexts/`) and is injected by OpenCore.
2. **WhateverXe Graphics** is a `.pkg` installed inside macOS. It puts Apple's Intel Xe drivers into `/Library` and rebuilds the Auxiliary Kernel Collection.

Releases: <https://github.com/b00t0x/WhateverXe/releases> (kext) and <https://github.com/b00t0x/WhateverXe-Graphics/releases> (pkg). Use the **RELEASE** zip; DEBUG is only for troubleshooting.

Current versions in this repo: WhateverXe **0.7.0**, Lilu **1.7.3**, AMFIPass **1.4.1 (Mod)**.

## Before you start

- Keep a copy of the working `EFI` folder, e.g. as a zip on the USB stick.
- Have a way back in: this USB stick with the old EFI, or `-x` Safe Mode (Safe Mode skips the Graphics package).
- Read the release notes (CHANGELOG) for both repos. New macOS versions often need a newer Graphics package first.

## Steps

1. **Download** the latest WhateverXe RELEASE zip and the latest WhateverXe Graphics `.pkg`.
2. **Kext:** replace `EFI/OC/Kexts/WhateverXe.kext` with the new one. Keep the `Kernel → Add` order: **Lilu first**, WhateverXe after Lilu, AMFIPass after Lilu.
3. If the release needs it, also update **Lilu** (from acidanthera) and **AMFIPass**. Use the *Mod* AMFIPass linked from WhateverXe's README, not upstream AMFIPass, and never both.
4. Run `ocvalidate EFI/OC/config.plist` (from the OpenCore release matching `OpenCore.efi`).
5. Reboot into macOS with the new EFI, then **install the new WhateverXe Graphics pkg** and reboot again.
6. Check: System Information → Graphics/Displays shows UHD 770 with **Metal**, and `kmutil showloaded | grep -i whateverxe` shows the new version.

## Rules from WhateverXe's README (still apply)

- `csr-active-config` must include `0x803`. This EFI uses `0x0A03`, which is a superset.
- Boot args `-allow3d -disablegfxfirmware` are required.
- DVMT 60 MB: keep `-igfxdvmt` plus `framebuffer-patch-enable` / `framebuffer-stolenmem`. With 96 MB DVMT in the BIOS you could drop them.
- WhateverGreen and WhateverXe must never both be enabled.
- No `device-id` spoof is needed; selection is automatic.

## If an update breaks graphics

- **Boot loops / freezes at `IntelAccelerator`:** boot the previous EFI from the USB, or add `-x` and reinstall the previous Graphics pkg.
- **`-wexoff`** disables WhateverXe for one boot. On this machine that hangs on its own, so use `-x` for recovery.
- Get logs with `tools/Collect-Dell-Graphics.command` (see TROUBLESHOOTING.md).
- Do **not** change the SMBIOS away from `MacBookPro16,2` while debugging. CHANGES.md explains why.
