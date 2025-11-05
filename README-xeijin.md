insaned
=======

Insaned is a simple linux daemon for polling button presses on SANE-managed scanners. 

It's simpler to setup than alternatives such as **scanbd**, but you will need a scanner which **exposes buttons as sensors**.

> :small_blue_diamond: **this project is a fork**
>
> please see the original project https://github.com/abusenius/insaned
>
> or README-orig.md for more information.

## updates in this version

this version incorporates a few changes including:

- [fix for a segmentation](https://github.com/abusenius/insaned/issues/15) fault by [bsdice](https://github.com/bsdice)
- [various fixes including re-attaching a device](https://github.com/hannesrauhe/insaned) by [hannesrauhe](https://github.com/hannesrauhe)
- support for **[scanservjs](https://github.com/sbs20/scanservjs)** (requires `curl` also)
- support for loading configuration via a `.env` file, see **[_example.env](./events/_example.env)**
- `make debian` for creating a debian package 

## installation
a package compiled for `armv6` (compatible with a Raspberry Pi Zero W) is included in each **[release](https://gitlab.com/xeijin-dev/insaned/-/releases)**, ssh into your raspberry pi and use `wget` or `curl` to download the package, then `sudo dpkg -i insaned_0.0.x_armhf.deb` to install.

for other operating systems/architectures see the build section below.

## usage

First check which compatible sensors/buttons your scanner has by running `insaned -L` - this should provide a list with names.

Assuming you only want to use the 'scan' button -- rename `_example.env` to `.env` and edit for your scanner

for **[scanservjs](https://github.com/sbs20/scanservjs)**  support you will need an instance hosted either locally or remotely, change the `SCAN_SCRIPT` variable in your .env file to `scanservjs`.

once the above is complete, simply hit the 'Scan' button on your compatible scanner and the script should kick-in.

To get other buttons on your scanner working, you'll need to create a new script in `/etc/insaned/events` with the same name as listed in `insaned -L`. Use the `scanimage` and `scanservjs` scripts as examples.

## build

You will need `libsane-dev` installed on your machine.

### debian

first do an `apt install` of `debhelper`, then clone the source and execute `make debian` in the root. The `.deb` file will be placed in the parent directory.

### other systemd distro

run `make` in the root directory, you will need to ensure you copy over the event and systemd scripts to the appropriate locations for your distro see below for an example

```
# copy binary and scripts
sudo cp insaned /usr/bin
sudo cp systemd/insaned.service /etc/systemd/system
sudo touch /etc/default/insaned
sudo systemctl start insaned
sudo systemctl enable insaned

# copy over event scripts and make them executable
sudo cp insaned/events /etc
sudo chmod +x /etc/insaned/events/*
```


