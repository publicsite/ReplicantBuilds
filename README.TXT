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

This is a port of Scintill's version of Replicant 6.0 to the i9305.

Data and SMSs work. Calls connect but no audio, unfortunately.

SHA256SUMS:

c57262809a4707fa1fa69b85652b8bc886e801015f83e3193047d47e0bb76864  system.img
ed06198e6887e0abbd373eedfc2e6054b62c90b98f54a11297e5a3fd4bfaca08  boot.img
65e89fc367cbe318a69ed030746870ef5f767fd07165b5b87a71562f582cf634  recovery.img

_________________________________________

Hybrid cross between Scintill's fork of replicant 6.0 and (the kernel of) postmarketos - for i9305.
The script "processKernel.sh" and "getPostmarketConfigs.sh" are used as glue between the postmarket kernel and replicant 6 at the source level.
"processKernel.sh" patches a vanilla kernel using postmarket patch sets, adapts postmarket mainline kernel configs for use with android (hybridization),
and updates an android device tree as to use the new kernel, as well as injecting the resulting kernel sources into the replicant source tree; ready to be compiled.

Other updates include updating gcc from 4.9 to 6.5.0 in the toolchain and patching, so that it is able to compile a mainline kernel without error,
fixing rot due to dead PGP [server] links and outdated [SSL/TLS] certificates during the build, and other minor fixes.
_________________________________________

To donate to me:

https://www.paypal.com/donate/?hosted_button_id=SZABYRV48SAXW

To donate to the replicant project:

https://crm.fsf.org/civicrm/contribute/transact?reset=1&id=19
