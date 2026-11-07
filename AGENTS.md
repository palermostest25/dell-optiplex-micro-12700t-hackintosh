# AGENTS.md

Guidance for AI coding agents (Claude, Codex, etc.) working on this repo.

## What this repo is

An OpenCore EFI plus notes for one physical machine: a Dell OptiPlex Micro (most likely a **7000 Micro**; confirm by service tag) with an i7-12700T and UHD 770, running macOS Tahoe 26.7.2. The iGPU runs through WhateverXe + WhateverXe Graphics. Read `README.md`, `CHANGES.md` and `TROUBLESHOOTING.md` before changing anything.

## Hard rules

1. **Never commit private identifiers.** `PlatformInfo → Generic → SystemSerialNumber`, `MLB`, `SystemUUID` and `ROM` must stay as placeholders (`REPLACE_WITH_…`, zero UUID, zero ROM). Before every commit, check that no 12-character serial, 17-character MLB or real MAC address appears anywhere in the repo.
2. **Keep `SystemProductName = MacBookPro16,2`.** MacPro7,1 hangs at `IntelAccelerator::probe`; iMac20,x triggers AGDP `Config3` and WindowServer can't open any framebuffer. Changing it also changes the machine's Apple identity.
3. **Keep `SimpleHDA.kext` disabled** unless you also solve the `AppleHDAHDMI_DPDriver::handleValidEDIDAction` panic on DP hotplug.
4. **One variable per test boot.** Each test costs the owner a reboot and a USB swap. Record what changed and the result in `CHANGES.md` / `TROUBLESHOOTING.md`.
5. **Validate every config change** with `ocvalidate` from the OpenCore release that matches `EFI/OC/OpenCore.efi` (1.0.x; 1.0.8 validates it).
6. **Back up before editing** the owner's live EFI (USB root `EFI/` or the internal EFI partition). Keep the previous config next to it or zipped.
7. Don't add WhateverGreen. It conflicts with WhateverXe.
8. Don't ship Apple driver binaries in this repo. The WhateverXe Graphics pkg installs them inside macOS.

## Workflow that worked

- The owner edits nothing by hand. The agent edits `config.plist` on the USB from another Mac, then the owner boots and reports.
- For black-screen or loop failures, follow TROUBLESHOOTING.md: add `-x`, boot, run `tools/Collect-Dell-Graphics.command` from the USB, then read the crash reports and the `com.apple.CoreDisplay` errors in the report.
- Kernel panics appear as `Kernel-*.panic` in the report after the next good boot. `debug=0x100` keeps the panic on screen.
- Verbose-boot photos: the last 10–20 lines are what matter. `IOVersatile` / `AMFI non-fatal` / keybag lines are noise.

## Key facts

| Item | Value |
| --- | --- |
| iGPU | UHD 770, `0x4680`, rev `0x0C` |
| WhateverXe | 0.7.0 RELEASE; Graphics pkg receipts `org.b00t0x.WhateverXe.Common` / `.Tahoe` |
| Lilu / AMFIPass | 1.7.3 / 1.4.1 Mod |
| DVMT | 60 MB, using `-igfxdvmt` + `framebuffer-patch-enable` + `framebuffer-stolenmem 0x03C00000` |
| csr-active-config | `0x0A03` (WhateverXe needs ⊇ `0x803`) |
| Working output | Rear DisplayPort 1 |
| Acceleration | Metal 2, 1536 MB dynamic VRAM |
| Display sleep wake | Works (one early failure, not reproduced) |

## Open work (priority order)

1. Re-test DP port 2 with SimpleHDA off.
2. Audio: find a way to get built-in audio without loading AppleHDA's DP-audio path, or accept USB audio only.
3. If display-sleep wake fails again, follow TROUBLESHOOTING #4.
4. Confirm the exact OptiPlex model and update the docs.
