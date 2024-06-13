# OpenWRT Belkin Netcam F7D7602V2
This repository contains scripts, file customization, and instructions for flashing the Belkin Netcam F7D7602V2 with OpenWRT. This has not yet been upstreamed to OpenWRT as some features are missing (audio and some GPIO). The OpenWRT image is also limited to 8MB as of right now.

## Features
After installing OpenWRT you will be able to get an MJPEG stream from the camera at 720p. You will also be able to reset the network settings of the device via it's Wi-Fi access point when setting the configuration switch on the back to the settings icon.

## Building and flashing

### Requirements
- SOIP8 chip flasher and clip
- USB to UART adapter
- Linux operating system

### Instructions

1. Backup your stock flash with your chip flasher (outside the scope of this tutorial) and pull the factory partition out.

```bash
dd if=backup.img of=factorypart.img bs=1 skip=$((0x40000)) count=$((0x50000-0x40000))
```
2. Build U-Boot with default settings using the mt7620_rfb target (outside scope of this tutorial).

3. Build the OpenWRT image using the image builder and the files provided.

```bash
git clone https://github.com/csev1755/openwrt-f7d7602v2.git
cd openwrt-f7d7602v2
wget https://archive.openwrt.org/releases/23.05.3/targets/ramips/mt7620/openwrt-imagebuilder-23.05.3-ramips-mt7620.Linux-x86_64.tar.xz
tar -xf openwrt-imagebuilder-23.05.3-ramips-mt7620.Linux-x86_64.tar.xz --strip=1
make image \
PROFILE="ralink_mt7620a-evb" \
PACKAGES="kmod-usb2 \
kmod-video-uvc \
kmod-usb-ohci \
mjpg-streamer \
mjpg-streamer-output-http \
mjpg-streamer-input-uvc \
luci \
FILES="files"
```

4. Put together the image with dd. I recommend you make copies of all of the files before doing this. 

```bash
# Pad U-Boot with SPL to 0x40000
dd if=/dev/zero bs=$((0x40000-$(stat -c %s u-boot-with-spl.bin))) count=1 >> u-boot-with-spl.bin

# Append factory partition, U-Boot, and OpenWRT
cat u-boot-with-spl.bin factorypart.img openwrt-23.05.3-ramips-mt7620-ralink_mt7620a-evb-squashfs-sysupgrade.bin >> full.img

# Pad image to 16MB
dd if=/dev/zero bs=1 count=$((16*1024*1024-$(stat -c %s full.img))) >> full.img
```

5. Flash the full padded image to your chip.

6. Connect to UART (clearly marked on the inside of the device, 115200 8N1), configure some settings, and boot.

```
setenv baudrate 57600
setenv bootcmd gpio set 0\; sf probe 0\; sf read 0x80a00000 0x50000 0x540329\; bootm 0x80a00000
saveenv
boot
```

7. Run the following commands in OpenWRT to extract the Wi-Fi EEPROM from the factory partition. 

```bash
cd /lib/firmware
dd if=/dev/mtd2 of=soc_wmac.eeprom count=1
```

After restarting, you should see its SSID of "NetCam" you can join to configure settings via Luci at 192.168.1.1