#!/bin/bash

#
# References: https://docs.khadas.com/vim3/UpgradeViaUSBCable.html
#

export SOURCE_PATH=$(pwd)

burn-tool -v aml -b VIM3 -i out/target/product/kvim3/update.img
