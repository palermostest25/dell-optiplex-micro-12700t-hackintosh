# Dell OptiPlex Micro (i7-12700T) — macOS Tahoe with UHD 770 acceleration

OpenCore EFI and notes for running macOS Tahoe 26.7.2 on a Dell OptiPlex Micro with an Intel Core i7-12700T, using the built-in **Intel UHD Graphics 770** (`0x4680`) through [WhateverXe](https://github.com/b00t0x/WhateverXe) + [WhateverXe Graphics](https://github.com/b00t0x/WhateverXe-Graphics).

> **Which OptiPlex?** The owner believed this was an *OptiPlex Micro Plus 7010*. The hardware points to an **OptiPlex 7000 Micro**: the i7-12700T is a 12th-gen part that Dell sold in the 7000 Micro, and that model has two rear DisplayPort outputs, which this machine has. The Micro Plus 7010 is a 13th-gen machine with three rear DisplayPorts, and the plain 7010 Micro has one DisplayPort plus HDMI. macOS cannot read the real model because OpenCore replaces it, so **confirm from the service-tag label or Dell's support site**.

## Status

| Feature | Status |
| --- | --- |
| Boot to desktop | Works |
| UHD 770 acceleration (Metal) via WhateverXe | Works. The Metal compiler loads; check *About This Mac* |
| Rear DisplayPort **1** | Works |
| Rear DisplayPort **2** | Untested since the audio fix. It crashed before (see Known issues) |
| Wake from **display sleep** | **Broken**: stays black. Workaround below |
| Built-in audio (AppleHDA via SimpleHDA) | **Disabled**: it crashes the kernel when a DP monitor connects |
| USB audio (e.g. Focusrite) | Should work (class compliant) |
| Ethernet (IntelMausi), Wi-Fi (AirportItlwm), Bluetooth | Enabled in the config; not re-checked in this session |

## Hardware

- CPU: Intel Core i7-12700T (Alder Lake-S, 35 W). The config spoofs CPUID to Comet Lake (`0x0A0655`).
- iGPU: Intel UHD Graphics 770, device ID `0x4680`, revision `0x0C`
- Chipset: Q670 (expected for this OptiPlex generation)
- Ethernet: Intel I219 (IntelMausiEthernet)
- Wi-Fi/BT: Intel (AirportItlwm / IntelBluetoothFirmware)

## What's in this repo

| Path | What |
| --- | --- |
| `EFI/` | Working OpenCore EFI. **Serial, MLB, SystemUUID and ROM are placeholders**; see [Before you boot](#before-you-boot) |
| `CHANGES.md` | Every change from the EFI as originally built (OpCore Simplify output plus WhateverXe additions) to this working one, and why |
| `UPDATING-WHATEVERXE.md` | How to update WhateverXe, WhateverXe Graphics, Lilu and AMFIPass safely |
| `TROUBLESHOOTING.md` | How each failure was diagnosed, with the exact log lines, and how to get logs when the screen is black |
| `AGENTS.md` | Instructions for AI agents working on this repo |
| `tools/Collect-Dell-Graphics.command` | Read-only diagnostics script. Run it from the USB; it writes a report next to itself |

## Before you boot

1. **Fill in PlatformInfo → Generic** in `EFI/OC/config.plist`. `SystemProductName` must stay **`MacBookPro16,2`** (see CHANGES.md for why).
   - Generate a serial and MLB for `MacBookPro16,2` with OpenCore's `Utilities/macserial/macserial -m MacBookPro16,2 -n 1` (or GenSMBIOS).
   - `SystemUUID`: any fresh UUID (`uuidgen`).
   - `ROM`: the Ethernet MAC address (6 bytes), without colons.
   - The machine's real values live only on its own EFI/USB. They are deliberately not committed.
2. Copy `EFI/` to the root of a FAT32 USB stick, or to the EFI partition of the Mac's drive.
3. On the first boot after any SMBIOS change, choose **Reset NVRAM** in the OpenCore picker once.

## Boot arguments (current)

```
-v debug=0x100 keepsyms=1 -allow3d -disablegfxfirmware -igfxdvmt ctrsmt=full
```

| Argument | Why |
| --- | --- |
| `-allow3d -disablegfxfirmware` | Required by WhateverXe |
| `-igfxdvmt` + `framebuffer-patch-enable` / `framebuffer-stolenmem` (DeviceProperties, `PciRoot(0x0)/Pci(0x2,0x0)`) | WhateverXe's fix for 60 MB DVMT (BIOS has no 96 MB option) |
| `-v debug=0x100 keepsyms=1` | Verbose boot; halt on panic with symbols. Remove `-v` once you are happy |
| `ctrsmt=full` | CpuTopologyRebuild |

Safe Mode: add `-x`. `PollAppleHotKeys` is on, but holding Shift in the picker did **not** work on this machine, so edit the boot args instead.

## Display sleep workaround

Until wake is fixed, stop the display from sleeping:

- System Settings → Lock Screen → *Turn display off … when inactive* → **Never** (a screen saver is fine), or
- `sudo pmset -a displaysleep 0`

WhateverXe's README lists DisplayPort reconnection causing black screens or freezes, and Alder Lake-S DP being slow, as known issues.

## Known issues

1. **Display sleep wake**: black screen after the display sleeps (open; see the workaround).
2. **AppleHDA DP-audio panic**: with SimpleHDA enabled, plugging or waking a DP monitor panics in `AppleHDAHDMI_DPDriver::handleValidEDIDAction`. SimpleHDA is disabled; fixing audio needs either HDMI/DP audio disabled or a different audio approach.
3. **DP port 2**: it went black when that panic hit. Re-test now that SimpleHDA is off.
4. **iCloud/iMessage**: the serial changed twice during setup (MacPro7,1 → iMac20,1 → MacBookPro16,2). Sign in again if Apple services act up.

## Credits

- [OpenCore](https://github.com/acidanthera/OpenCorePkg), [Lilu](https://github.com/acidanthera/Lilu), VirtualSMC, AppleALC, NVMeFix, RestrictEvents: acidanthera
- [WhateverXe / WhateverXe Graphics / AMFIPass Mod](https://github.com/b00t0x): b00t0x
- AirportItlwm / IntelBluetoothFirmware: OpenIntelWireless
- CpuTopologyRebuild: b00t0x. USBToolBox: dhinakg. IntelMausiEthernet: Mieze
- SimpleHDA: laobamac (shipped but disabled)
- Initial EFI generated with [OpCore Simplify](https://github.com/lzhoang2801/OpCore-Simplify)
