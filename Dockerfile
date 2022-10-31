FROM busybox:latest

ARG BUILD_DATE="NULL"
ARG VERSION="NULL"
ARG VCS_REF="NULL"
ARG CONFIG_NAME="carma-config:unspecified"

LABEL org.label-schema.schema-version="1.0"
LABEL org.label-schema.name=${CONFIG_NAME}
LABEL org.label-schema.description="System configuration data for the CARMA Platform"
LABEL org.label-schema.vendor="Leidos"
LABEL org.label-schema.version=${VERSION}
LABEL org.label-schema.url="https://highways.dot.gov/research/research-programs/operations/CARMA"
LABEL org.label-schema.vcs-url="https://github.com/usdot-fhwa-stol/carma-config"
LABEL org.label-schema.vcs-ref=${VCS_REF}
LABEL org.label-schema.build-date=${BUILD_DATE}

ADD . /root/vehicle/config
VOLUME /opt/carma/vehicle/config

CMD  cp /root/vehicle/config/* /opt/carma/vehicle/config

ARG ROS_DISTRO=galactic

FROM ros:$ROS_DISTRO-ros-base AS pkg-builder

# select bash as default shell
SHELL ["/bin/bash", "-c"]

WORKDIR /ros2_ws

# install everything needed
RUN git clone https://github.com/KBR-CARMA/sllidar_ros2.git /ros2_ws/src/sllidar_ros2 -b main && \
    rosdep update --rosdistro $ROS_DISTRO && \
    rosdep install --from-paths src --ignore-src -y && \
    source /opt/ros/$ROS_DISTRO/setup.bash && \
    colcon build --symlink-install --event-handlers console_direct+

FROM ros:$ROS_DISTRO-ros-core

# select bash as default shell
SHELL ["/bin/bash", "-c"]

RUN apt update && apt install -y \
        ros-$ROS_DISTRO-rmw-fastrtps-cpp \
        ros-$ROS_DISTRO-rmw-cyclonedds-cpp && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /ros2_ws

COPY --from=pkg-builder /ros2_ws /ros2_ws

RUN echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> ~/.bashrc
RUN echo "source /ros2_ws/install/setup.bash" >> ~/.bashrc

ENV RMW_IMPLEMENTATION=rmw_fastrtps_cpp

COPY ros_entrypoint.sh /

# Without this line LIDAR doesn't stop spinning on container shutdown. Default is SIGTERM. 
STOPSIGNAL SIGINT
