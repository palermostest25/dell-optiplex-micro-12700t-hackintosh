# Changes since the original EFI

## Baseline: what the EFI looked like before this work

The original EFI matches **OpCore Simplify** output for an Alder Lake desktop where the iGPU isn't supported, plus WhateverXe pieces that were added by hand afterwards. No OpCore Simplify output folder survived, so the split below is inferred from what is in the config.

**Typical OpCore Simplify output**
- SMBIOS **`MacPro7,1`**, OpCore Simplify's choice when it treats the iGPU as unsupported
- CPUID spoof to Comet Lake (`Cpuid1Data 55060A00…`, mask `FFFFFFFF…`), `ProvideCurrentCpuInfo`
- SSDTs: `SSDT-SBUS`, `SSDT-EC`, `SSDT-PLUG-ALT`, `SSDT-RTCAWAC`, `SSDT-USB-Reset`, `SSDT-USBX`
- Kexts: Lilu, VirtualSMC + SMCProcessor + SMCSuperIO, AppleALC (`layout-id 13`), NVMeFix, RestrictEvents, CpuTopologyRebuild (`ctrsmt=full`), USBToolBox + UTBDefault, XHCI-unsupported, IntelMausiEthernet, AirportItlwm, IntelBluetoothFirmware/IntelBTPatcher/BlueToolFixup
- Kernel patches "force HT enabled" (three OS ranges)
- Booter quirks: `DevirtualiseMmio`, `ProvideCustomSlide`, `RebuildAppleMemoryMap`, `SyncRuntimePermissions`, `ProtectUefiServices`, `SetupVirtualMap`, `FixupAppleEfiImages`, etc.
- UEFI drivers: `apfs_aligned.efi`, `HfsPlus.efi`, `OpenCanopy.efi`, `OpenRuntime.efi`, `ResetNvramEntry.efi`
- `SecureBootModel = Disabled`, `csr-active-config = 0x0A03`

**Added afterwards for iGPU acceleration (manual)**
- `WhateverXe.kext` 0.7.0 (after Lilu), `AMFIPass.kext` 1.4.1 (the WhateverXe *Mod* build)
- Boot args `-allow3d -disablegfxfirmware -igfxdvmt`, plus `-v debug=0x100 keepsyms=1`
- DeviceProperties on `PciRoot(0x0)/Pci(0x2,0x0)`: `framebuffer-patch-enable = 01000000`, `framebuffer-stolenmem = 0000C003`
- `SimpleHDA.kext` (laobamac): force-loads AppleHDA on Tahoe
- WhateverXe Graphics package installed in macOS (receipts `org.b00t0x.WhateverXe.Common` / `.Tahoe`)

**Symptom with that EFI:** the verbose boot froze right after `IntelAccelerator::probe … Found device with ID 0x46808086`.

## Changes made (in order), and why

| # | Change | Result | Kept? |
| --- | --- | --- | --- |
| 1 | SMBIOS `MacPro7,1` → `iMac20,1` (new serial/MLB) | Passed the accelerator freeze, but WindowServer crash-looped: `CGXMappedDisplayStart: IOServiceOpen failed(0xe00002c7)` / "0 of 3 framebuffers were successfully opened". Apple's display policy (AGDP) for iMac20,1's board ID is `Config3`, and WhateverXe, unlike WhateverGreen, doesn't patch AGDP | Replaced by #5 |
| 2 | `-wexoff` (one diagnostic boot) | Hung at SimpleHDA loading `IOGraphicsFamily`. Without WhateverXe this isn't a useful test | Removed |
| 3 | SimpleHDA disabled (test) | Same crash loop, so SimpleHDA wasn't the cause of #1 | Re-enabled, then disabled again in #6 |
| 4 | `-x` Safe Mode (diagnostic) | Reached the desktop and collected crash reports and logs | Removed |
| 5 | SMBIOS → **`MacBookPro16,2`** (new serial/MLB); `PollAppleHotKeys` → `true` | AGDP config for that board ID is `None` (the same SMBIOS a working WhateverXe Raptor Lake laptop uses). WindowServer started and Metal loaded. DP port 1 showed the console; port 2 went black | **Kept** |
| 6 | **SimpleHDA disabled** | Fixed the kernel panic in `AppleHDAHDMI_DPDriver::handleValidEDIDAction` that hit when the DP monitor's EDID arrived. Desktop works on DP port 1 | **Kept** |
| 7 | **Custom USB map**: `UTBMap.kext` added (enabled), `UTBDefault.kext` disabled | With the generic map, the DisplayLink dock only enumerated at 480 Mb/s (no `0x17e9` device) and DisplayLink Manager said it wasn't a DisplayLink device. A first 12-port map missed the USB-C's USB 2 half (HS02), so USB 2 devices on the dock failed. The 14-port map below fixes both | **Kept** |

## Net diff: original config → this repo

```
Kernel/Add[SimpleHDA.kext]/Enabled      true      -> false
Misc/Boot/PollAppleHotKeys              false     -> true
PlatformInfo/Generic/SystemProductName  MacPro7,1 -> MacBookPro16,2
PlatformInfo/Generic/SystemSerialNumber (regenerated for MacBookPro16,2; placeholder in repo)
PlatformInfo/Generic/MLB                (regenerated; placeholder in repo)
Kernel/Add[UTBDefault.kext]/Enabled     true      -> false
Kernel/Add[UTBMap.kext]                 (new, Enabled true, codeless)
```

Apart from `UTBMap.kext`, no kexts, ACPI tables, drivers or quirks were added or removed. `SystemUUID` and `ROM` were not changed on the machine; they are placeholders here only for privacy.

## Why not iMac20,1 or MacPro7,1?

| SMBIOS | Board ID | AGDP `ConfigMap` (macOS 26) | Outcome here |
| --- | --- | --- | --- |
| MacPro7,1 | Mac-27AD2F918AE68F61 | None | Hang at `IntelAccelerator::probe` |
| iMac20,1 | Mac-CFF7D910A743CAAF | **Config3** | Framebuffers refuse to open; WindowServer abort loop |
| iMac20,2 | Mac-AF89B6D9451A490B | Config3 | (not tried; same policy) |
| **MacBookPro16,2** | Mac-5F9802EFE386AA28 | None | **Works** |

Macmini8,1 would be the classic iGPU-only choice, but Tahoe dropped it.

## USB map (UTBMap.kext)

Built with USBToolBox in Windows (Windows To Go). XHCI `8086:7AE0`. Under the 15-port limit.

| Name | Port | Type | What |
| --- | --- | --- | --- |
| HS01, HS03–HS06 | 1, 3, 4, 5, 6 | 3 (USB-A) | USB 2 halves of the USB-A ports |
| HS02 | 2 | 9 (USB-C) | USB 2 half of the USB-C port (dock's USB 2 hubs) |
| HS07 | 14 (0x0E) | 255 (internal) | Bluetooth |
| SS01–SS05 | 17, 19, 20, 21, 24 | 3 (USB-A) | USB 3 halves (partners of HS 1, 5, 6, 3, 4) |
| SS06, SS07 | 25, 26 | 9 (USB-C) | USB 3 half of the USB-C port, one per plug orientation |

To re-map: run USBToolBox in Windows from the same folder (it saves `usb.json` next to itself and remembers the earlier ports), discover, select, Build, and replace `EFI/OC/Kexts/UTBMap.kext`. Every port needs **both** halves mapped: USB 2 devices use HS, USB 3 devices use SS. Don't commit `usb.json`; it contains device serial numbers.
