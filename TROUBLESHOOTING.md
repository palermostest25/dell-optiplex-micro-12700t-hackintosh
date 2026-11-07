# Troubleshooting log

How each problem was diagnosed on this machine. Use the same steps when something new breaks.

## Getting evidence when the screen is black

1. If it is stuck, hold power for 15 s.
2. Add **`-x`** to the boot args (edit `config.plist` from another Mac. Shift-to-Safe-Mode in the picker did not work here).
3. Boot, log in, and run `tools/Collect-Dell-Graphics.command` **from the USB stick** (Finder → stick → double-click). It writes `Dell-Diagnostics-<date>.txt` next to itself and includes:
   - macOS version, boot args, model, Graphics/Displays
   - graphics-related loaded kexts and WhateverXe package receipts
   - **crash reports from the last 2 days** (WindowServer, loginwindow, kernel panics)
   - WindowServer / loginwindow / WhateverXe kernel log for the last 3 hours
4. Remove `-x` again.

`debug=0x100` makes the machine halt on a panic instead of rebooting. The panic report is saved and appears in `/Library/Logs/DiagnosticReports/*.panic` on the next successful boot.

## Symptom → cause → fix (in order)

### 1. Freeze after `IntelAccelerator::probe: Found device with ID 0x46808086`
- WhateverXe logged `TGL accel stage=1 done=0`, so Apple's accelerator probe never returned.
- Only clear difference from a working WhateverXe machine: SMBIOS **MacPro7,1** (a Mac with no Intel iGPU).
- Fix: change the SMBIOS to a model with an Intel iGPU (ended up as MacBookPro16,2, see #2).

### 2. Endless loop of `IOVersatile … Couldn't alloc class` + `IOConsoleUsers … gIOScreenLockState 3`
- The `IOVersatile` lines are harmless noise. The repeat itself is WindowServer restarting.
- Crash report: `WindowServer` SIGABRT in `CoreDisplay::Assert ← CGXMappedDisplayStart`.
- Log: `CGXMappedDisplayStart: IOServiceOpen failed(0xe00002c7)` ×3, then `Driver Error: 0 of 3 framebuffers were successfully opened`.
- Cause: SMBIOS **iMac20,1**. AppleGraphicsDevicePolicy for that board ID is `Config3`, and WhateverXe has no AGDP patch (WhateverGreen's `agdpmod` isn't available).
- Fix: SMBIOS **MacBookPro16,2** (AGDP `None`).

### 3. Black screen on DP port 2, console frozen on DP port 1
- Panic: page fault in `AppleHDAHDMI_DPDriver::handleValidEDIDAction` (AppleHDA), triggered when the monitor's EDID arrived.
- AppleHDA only loads on Tahoe because **SimpleHDA** force-loads it.
- Fix: disable SimpleHDA. Use DP port 1.

### 4. Display doesn't wake after display sleep (seen once; now works)
- Matches WhateverXe's known issue: DP reconnection on Alder Lake-S is slow, or goes black/freezes.
- Workaround: disable display sleep.
- To diagnose: let it fail, wait 60 s, note whether Caps Lock still toggles, hard reset, then collect (step 3 above) and look at WindowServer and kernel lines around the wake time.

## Harmless noise you will see in verbose boot

- `Kext com.apple.driver.IOVersatile - can't resolve dependencies` / `Couldn't alloc class "IOVersatileHWA"`
- `AMFI: [non-fatal] unable to accelerate context`
- `apfs_keybag_init … failed to initialize volume keybag, err = 2`
- `disallowing unsupported code signature page shift: 14`
