#!/bin/bash
source "$(dirname "$BASH_SOURCE")"/linuxarmhf-gpl-shared.sh
FF_CONFIGURE="--enable-nonfree $FF_CONFIGURE"
