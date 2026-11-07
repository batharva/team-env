# syntax=docker/dockerfile:1.4
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    DISPLAY=:1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LIBGL_ALWAYS_SOFTWARE=1

# Keep downloaded .debs in a BuildKit cache so rebuilds don't re-download GBs
RUN rm -f /etc/apt/apt.conf.d/docker-clean \
    && echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# 1. Base: desktop, VNC, noVNC, dev tools, terminator
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
    xfce4 xfce4-terminal dbus-x11 xfonts-base xauth \
    tigervnc-standalone-server tigervnc-common tigervnc-tools \
    novnc websockify terminator \
    build-essential git curl wget vim nano sudo ca-certificates gnupg \
    python3 python3-pip python3-venv cmake gdb unzip \
    mesa-utils libgl1-mesa-dri

# 2. VS Code (the "code" command is wrapped so it always runs with --no-sandbox)
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
      | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/code stable main" \
      > /etc/apt/sources.list.d/vscode.list \
    && apt-get update && apt-get install -y --no-install-recommends code \
    && rm -f /usr/bin/code \
    && printf '#!/bin/sh\nexec /usr/share/code/bin/code --no-sandbox "$@"\n' > /usr/bin/code \
    && chmod 755 /usr/bin/code \
    && (grep -rl '^Exec=.*code' /usr/share/applications 2>/dev/null \
        | xargs -r sed -i 's|^\(Exec=[^ ]*code\)|\1 --no-sandbox|' || true)

# 3. ROS 2 Humble
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    curl -fsSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key \
      -o /usr/share/keyrings/ros-archive-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu jammy main" \
      > /etc/apt/sources.list.d/ros2.list \
    && apt-get update && apt-get install -y --no-install-recommends \
      ros-humble-desktop ros-dev-tools \
      python3-colcon-common-extensions python3-rosdep \
    && rosdep init

# 4. Gazebo Harmonic + ROS 2 bridge
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    curl -fsSL https://packages.osrfoundation.org/gazebo.gpg \
      -o /usr/share/keyrings/pkgs-osrf-archive-keyring.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/pkgs-osrf-archive-keyring.gpg] http://packages.osrfoundation.org/gazebo/ubuntu-stable jammy main" \
      > /etc/apt/sources.list.d/gazebo-stable.list \
    && apt-get update && apt-get install -y --no-install-recommends \
      gz-harmonic ros-humble-ros-gzharmonic

# 5. Non-root user (kept last so the tool layers above stay cached)
ARG USERNAME=dev
ARG UID=1000
RUN useradd -m -u ${UID} -s /bin/bash ${USERNAME} \
    && echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME}

COPY --chmod=755 start.sh /start.sh

USER ${USERNAME}
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc

WORKDIR /home/${USERNAME}/workspace
EXPOSE 6080
CMD ["/start.sh"]
