# insaned

This project is a fork of https://gitlab.com/xeijin-dev/insaned

This fork intends to Dockerize insaned for usage with Scanservjs, as well as fix numerous bugs.

Original READMEs can be found in the root directory.

## Description

Insaned is a simple linux daemon for polling button presses on SANE-managed scanners. 

## Example Docker Compose with Scanservjs

This example assumes the CWD contains relevant git cloned projects in `./scanservjs` and `./insaned`

The env var `SANED_NET_HOSTS` is the host address of a USB connected scanner that is configured with `Sane over Network`:  (Debian wiki: https://wiki.debian.org/SaneOverNetwork)  (ArchLinux wiki: https://wiki.archlinux.org/title/SANE#Sharing_your_scanner_over_a_network).  Both `insaned` and `./scanservjs` need this to operate correctly.

Currently `insaned` only polls the first scanner found.

`Scanservjs` is locally built so that the user configuration is setup correctly, and Docker volumes are easily accessed from the host.  This makes it possible to streamline an NFS share to say a Paperless-ngx consume
folder as a docker volume and user permissions are set correctly.

```
services:
  scanservjs:
    build:
      context: ./scanservjs
      args:
        # ----- enter UID and GID here -----
        UID: 1000
        GID: 1000
        UNAME: user
      target: scanservjs-user2001
    container_name: scanservjs
    environment:
      # ----- specify network scanners here; see above for more possibilities -----
      - SANED_NET_HOSTS=192.168.0.101
    volumes:
      # ---- enter your target location for scans before the ':' character -----
      - ./.data/scans:/var/lib/scanservjs/output
      - ./.data/config:/etc/scanservjs
    user: 1000:1000
    restart: unless-stopped
  insaned:
    build:
      context: ./insaned
    container_name: scanservjs_insaned
    environment:
      # ----- specify network scanners here; see above for more possibilities -----
      - SANED_NET_HOSTS=192.168.0.101
    volumes:
      - ./insaned.env:/etc/insaned/events/.env
    restart: unless-stopped

```

## Example .env file

Strangely, this .env file acts as script for configuring `Insaned`.  In the above docker compose file, it is referenced as `./insaned.env`

This config uses a custom `ocrmypdf` pipeline defined in Scanservjs.

```
#!/bin/bash
# _example.env - update for your scanner & rename to '.env'

# this file is sourced by the 'scan' script
# its provided as an example, modify and rename for your needs

### general
# select the script to be executed when the scan button is pressed
## scanimage - the classic scanning image, use this for testing and keep it if it meets your needs
## scanservjs - execute a scan via a user friendly web front-end and easily access scans from a browser - see scanservjs file for more info
export SCAN_SCRIPT="scanservjs"

# add other buttons or sensors here as required - you'll need to use a similar template to the scan script

### scanservjs
# note - the parameters below are for a Fujitsu ScanSnap S1300i
# consult the scanservjs documentation for your own scanner

# scanservjs instance - usually only HOST needs to be changed
export SSJS_PROTOCOL="https" # https untested (unsupported?) currently
export SSJS_HOST="scanserv.yourhost.tld" # or IP address
export SSJS_PORT=443
export SSJS_PATH="api/v1/scan"

# below env vars are deprecated in 0.4.  insaned just grabs first avail scanner in events/common:ssjs_get_scanner_device
# device id as seen by scanservjs - visit the scanserv UI to get this value
#export DEVICE_ID="" # insert if you know it and are sure it will never change, otherwise dynamically populated
#export SANE_HOST="" # the address of the SANE-shared network scanne, IP also fine

# parameters
# see scanservjs docs/repo for an exhaustive list of enumerations
export SSJS_RESOLUTION=300 # 50-600 DPI
export SSJS_MODE="Color" # Color|Gray|Lineart etc
export SSJS_SOURCE="ADF Duplex" # ADF Front|Back|Duplex
export SSJS_BRIGHTNESS=0
export SSJS_CONTRAST=0
export SSJS_FILTERS=() # ("filter.auto-level" "filter.blur" "filter.threshold") - bash array will be converted to JSON, use spaces not commas!
export SSJS_PIPELINE="ocrmypdf (JPG | @:pipeline.high-quality)" # custom pipelines also possible - see scanservjs docs for details.
export SSJS_BATCH="auto" # none|manual|auto

```

## Notes on Sane over Network

### server side (where usb scanner connected)

#### sane service

first set maxconnections:

`sudo systemctl edit --full saned.socket`

set `MaxConnections=64`

then get sane.socket up and running:

`systemctl enable sane.socket`
`systemctl start sane.socket`

### permissions

`lsusb` to note vendor:device

edit `/usr/lib/udev/rules.d/65-sane.rules`

with

`ATTRS{idVendor}=="vendorID", ATTRS{idProduct}=="productID", MODE="0664", GROUP="lp", ENV{libsane_matched}="yes"`

where `vendorID` and `productID` are the vendor:device codes obtained by `lsusb`

replug in scanner to apply

### firewall

sane uses port 6566 by default

`firewall-cmd --add-service=sane --permanent`

### enable access list subnets

add subnet you would like to provide scanner access to in `/etc/sane.d/saned.conf`

### testing

always test using the `saned` user.

`su -s /bin/bash saned`
`scanimage -L`
