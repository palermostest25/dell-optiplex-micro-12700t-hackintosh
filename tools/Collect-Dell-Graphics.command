#!/bin/zsh
# Read-only diagnostics for the Dell OptiPlex (12700T / UHD 770). Double-click on the Dell, from the USB.
set -u
export LC_ALL=C
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
usb_dir="${0:A:h}"
report="$usb_dir/Dell-Diagnostics-$(date +%Y%m%d-%H%M%S).txt"
if ! : > "$report"; then echo 'Cannot write beside this script. Run it from the USB.'; exit 1; fi
# Drop lines with common private identifiers.
redact() {
  /usr/bin/perl -ne 'print unless /serial|system-id|systemuuid|platformuuid|\bMLB\b|"ROM"|IOPlatformUUID|IOPlatformSerialNumber|password|token|bluetooth.*address|mac.address|local.host.name|computer.name|owner.name|\bSSID\b|\bBSSID\b|IODisplayEDID/i'
}
section() {
  local title="$1"; shift
  echo "Collecting: $title"
  { printf '\n\n========== %s ==========\n' "$title"; "$@" 2>&1 | redact; printf '\n[exit %s]\n' "${pipestatus[1]}"; } >> "$report"
}
{ echo 'DELL GRAPHICS DIAGNOSTICS — read-only'; date -u '+UTC: %Y-%m-%d %H:%M:%S'; } >> "$report"
section 'macOS version' sw_vers
section 'Boot args' sysctl kern.bootargs
section 'Model' sysctl hw.model
section 'Graphics and displays' system_profiler SPDisplaysDataType -detailLevel full
section 'Loaded kexts (graphics-related)' /bin/zsh -c 'kmutil showloaded 2>/dev/null | grep -Ei "Lilu|WhateverXe|Intel|Graphics|AGDP|AppleGraphics|IOGraphics|IOAccel"'
section 'Graphics package receipts' /bin/zsh -c 'pkgutil --pkgs | grep -Ei "WhateverXe|TGL|AMFIPass"'
section 'Crash reports, last 2 days (WindowServer, loginwindow, kernel)' /bin/zsh -c '
files=( /Library/Logs/DiagnosticReports/{WindowServer*,loginwindow*,*.panic,Kernel*}(N.mh-48) /Library/Logs/DiagnosticReports/Retired/{WindowServer*,loginwindow*}(N.mh-48) )
(( $#files )) || { echo "None found."; exit 0; }
for f in ${(f)"$(ls -t -- $files | head -4)"}; do echo "--- $f"; head -c 200000 "$f"; echo; done'
section 'WindowServer / loginwindow log, last 3 hours' /usr/bin/log show --last 3h --style compact --predicate 'process == "WindowServer" OR process == "loginwindow" OR (process == "kernel" AND (eventMessage CONTAINS[c] "WhateverXe" OR eventMessage CONTAINS[c] "AGDP" OR eventMessage CONTAINS[c] "IntelAccelerator" OR eventMessage CONTAINS[c] "TGL"))'
section 'WEX / TGL registry properties' /bin/zsh -c 'ioreg -l -w0 -p IOService | grep -Ei "N97|WEX|TGL|IntelAccelerator|AAPL,ig|device-id|framebuffer-" | cut -c1-600'
{ echo '\n========== COLLECTION COMPLETE =========='; } >> "$report"
sync
echo "DONE. Report saved to:"; echo "$report"
