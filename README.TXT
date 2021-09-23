Builds of Replicant

The code was created on-the-fly so is unlikely to work without modifications.

_________________________________________

Wolfgang's fork of replicant 4.2

Nexus S, boot, system and recovery images have been uploaded as a release.

Compiling Replicant/Android from source was the only way I could find of fixing SSL/TLS on the device.

SHA256SUMS:
b908a7507d84af3bb313c651e690b272b429566652d36839a6e6dcff56dbb099 system.img
a2e2de1460566fc0c28bff52ea96ec092f7e172ff366f80c622ca444506a5665 boot.img
084efda82371b2936cced4a94b5390a7ced342b71f61ed8e1312a792598f81ad recovery.img

_________________________________________

Scintill's fork of replicant 6.0 (incomplete ported to the i9305)

- Modem in images do not work, and images are for testing purposes only.
- SELinux rules need review.
- How to apply patches, is in getSource-6.0.sh
- mdm9k-boot service does not start on boot, most of it needs to be started manually.
- On the i9305, the device file /dev/cdc-wdm2 does not exist and needs to be changed in init.ofono-qmi.rc
- Use dbus to test ofono

SHA256SUMS:
14fd84fe003d0c53c396578d2351888ad9881ba19d03e1f58baeaaa2e67c8047 system.img
3772de141b9c7428ca6c7ab02affbd107aadba46fc8f77cdc9a25a7445ccf858 boot.img
58232f46f3272600e28584db0c392fadd3ac6313348f1643115522c3f9bfad19 recovery.img
