#!/bin/bash

echo "Remapping the device serial port (ttyUSBX) to /dev/rplidar"
echo "Check rplidar device: ls -l /dev | grep ttyUSB"

# Get the installed package prefix path (usually .../install/sllidar_ros2)
INST_PATH=$(ros2 pkg prefix sllidar_ros2)

if [ -z "$INST_PATH" ]; then
  echo "Error: sllidar_ros2 package not found. Have you built and sourced your workspace?"
  return 1
fi

# Replace /install/ with /src/ to get source directory path
SRC_PATH=$(echo "$INST_PATH" | sed 's#/install/#/src/#')

# Check if directory exists
if [ ! -d "$SRC_PATH" ]; then
  echo "Error: source directory not found at $SRC_PATH"
  return 1
fi

echo "Using source directory: $SRC_PATH"
cd "$SRC_PATH" || { echo "Failed to change directory"; exit 1; }

if [ ! -f scripts/rplidar.rules ]; then
  echo "Error: scripts/rplidar.rules not found in source directory!"
  return 1
fi

echo "Copying rplidar.rules to /etc/udev/rules.d/"
sudo cp scripts/rplidar.rules /etc/udev/rules.d/

echo ""
echo "Reloading udev rules"
sudo service udev reload
sudo service udev restart

echo "Finished setting up udev rule for RPLIDAR"
