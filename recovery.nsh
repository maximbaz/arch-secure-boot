echo -off
FS0:

if %1 == "" then
    if exist snapshots.txt then
        echo "Find snapshot ID to boot and press Ctrl+Q (opening file in 5s)"
        stall 5000000
        edit snapshots.txt
        echo "To boot in a snapshot:     recovery.nsh <snapshot-id>"
        echo "To use LTS kernel:         recovery.nsh <snapshot-id> lts"
        echo "To see the list again:     recovery.nsh"
    else
        echo "No snapshot descriptions available"
    endif
else
    if %2 == "lts" then
        \EFI\arch\%%NAME%%-lts-recovery.efi cryptdevice=LABEL=luks:luks:allow-discards root=LABEL=btrfs rw rootflags=subvol=snapshots/%1/snapshot
    else
        \EFI\arch\%%NAME%%-recovery.efi cryptdevice=LABEL=luks:luks:allow-discards root=LABEL=btrfs rw rootflags=subvol=snapshots/%1/snapshot
    endif
endif
