#!/bin/bash
set -e

# setup ros environment
source "/opt/ros/$ROS_DISTRO/setup.bash"

source "/ros2_ws/install/setup.bash"

exec "$@"