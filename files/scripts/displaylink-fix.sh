#!/usr/bin/env bash

# Tell this script to exit if there are any errors.
# You should have this in every custom script, to ensure that your completed
# builds actually ran successfully without any errors!
set -oue pipefail

# The DisplayLink RPM installs a systemd service, but it's often disabled by default.
# We enable it here so it's active the moment you first boot into your custom image.
systemctl enable displaylink.service

# Some versions of the DisplayLink driver require an explicit 'evdi' configuration 
# to ensure the kernel module loads with the correct parameters for the manager.
mkdir -p /etc/modprobe.d/
echo 'options evdi initial_device_count=4' > /etc/modprobe.d/evdi.conf

# We also create a udev trigger to ensure that when a USB dock is plugged in, 
# the system knows exactly which driver to associate with it.
mkdir -p /etc/udev/rules.d/
echo 'ACTION=="add", SUBSYSTEM=="usb", ATTR{idVendor}=="17e9", RUN+="/usr/bin/systemctl start displaylink.service"' > /etc/udev/rules.d/99-displaylink-custom.rules

echo "DisplayLink configuration applied successfully."
