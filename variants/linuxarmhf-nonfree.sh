#!/bin/bash
source "$(dirname "$BASH_SOURCE")"/linuxarmhf-gpl.sh
FF_CONFIGURE="--enable-nonfree $FF_CONFIGURE"
LICENSE_FILE=""
