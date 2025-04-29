FROM fedora:41

# Install NVIDIA container toolkit
RUN curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
    tee /etc/yum.repos.d/nvidia-container-toolkit.repo

RUN dnf install -y nvidia-container-toolkit nvidia-container-runtime

# Install required development dependencies for gst-wayland-display
RUN dnf install -y git cargo openssl openssl-devel \
    libwayland-server wayland-devel libudev-devel \
    pkg-config glib2-devel gstreamer1-devel gstreamer1-plugins-base-devel \
    gstreamer1-plugins-good gstreamer1-plugins-good-extras \
    libxkbcommon-devel libinput-devel


# Set up XDG runtime directory for Wayland
RUN mkdir -p /tmp/xdg-runtime-dir && \
    chmod 0700 /tmp/xdg-runtime-dir

# Set environment variables
ENV XDG_RUNTIME_DIR=/tmp/xdg-runtime-dir
ENV PATH=$PATH:/root/.cargo/bin

# GPU-related environment variables (commented out for now)
# ENV __GLX_VENDOR_LIBRARY_NAME=nvidia
# ENV LIBVA_DRIVER_NAME=nvidia
# ENV GBM_BACKEND=nvidia-drm
# ENV __GL_GSYNC_ALLOWED=0
# ENV __GL_VRR_ALLOWED=0
    
# Clone and build gst-wayland-display
RUN git clone https://github.com/games-on-whales/gst-wayland-display.git && \
    cd gst-wayland-display && \
    # Install cargo-c if you don't have it already
    cargo install cargo-c && \
    # Build and install the plugin with GPU acceleration
    cargo cinstall --prefix=/usr/local

# Make sure the GStreamer plugin is in the correct location
RUN mkdir -p /usr/local/lib64/gstreamer-1.0 && \
    mkdir -p /local/lib64/gstreamer-1.0 && \
    find /usr/local/lib64 -name "libgstwaylanddisplay*.so" -exec cp {} /usr/local/lib64/gstreamer-1.0/ \; || true && \
    find /usr/local/lib -name "libgstwaylanddisplay*.so" -exec cp {} /usr/local/lib64/gstreamer-1.0/ \; || true && \
    find /gst-wayland-display/target -name "libgstwaylanddisplaysrc.so" -exec cp {} /usr/local/lib64/gstreamer-1.0/ \; || true

# Copy the libgstwaylanddisplaysrc.so to /local/lib64/gstreamer-1.0 as well
RUN if [ -f "/usr/local/lib64/gstreamer-1.0/libgstwaylanddisplaysrc.so" ]; then \
    cp /usr/local/lib64/gstreamer-1.0/libgstwaylanddisplaysrc.so /local/lib64/gstreamer-1.0/; \
fi

# Set NVIDIA GPU information and create wrapper script for Wayland display
COPY run-wayland-display.sh /local/bin/
RUN chmod +x /local/bin/run-wayland-display.sh

RUN dnf install -y \
   mesa-dri-drivers mesa-libGL mesa-libEGL mesa-libGLES \
   libdrm libdrm-devel \
   weston weston-libs xorg-x11-server-Xwayland \
   tmux procps-ng \
   sway xdg-desktop-portal-wlr wayland-protocols-devel \
   cmake vulkan-headers vulkan-loader vulkan-tools vulkan-validation-layers \
   # Install wlroots and development packages
   wlroots wlroots-devel \
   # Install latest version available
   wlroots0.17 wlroots0.17-devel

# Install wlr-protocols for the export-dmabuf protocol
RUN git clone https://github.com/swaywm/wlr-protocols.git && \
    mkdir -p /usr/share/wayland-protocols/ && \
    cp -r wlr-protocols/* /usr/share/wayland-protocols/ && \
    cd / && \
    # Make sure we're using the latest wlroots library
    ln -sf /usr/lib64/libwlroots.so.* /usr/lib64/libwlroots.so

# Install Sunshine streaming server from COPR repository
RUN dnf copr enable -y lizardbyte/stable && \
    dnf install -y Sunshine udev fuse fuse-libs xdpyinfo && \
    # Create required directories
    mkdir -p /dev/input && \
    mkdir -p /sunshine && \
    mkdir -p /local/bin && \
    mkdir -p /local/lib64/gstreamer-1.0 && \
    # Copy udev rules but don't try to reload (containers don't use udev)
    mkdir -p /etc/udev/rules.d && \
    echo 'KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"' > /etc/udev/rules.d/85-sunshine.rules && \
    echo 'KERNEL=="uhid", TAG+="uaccess"' >> /etc/udev/rules.d/85-sunshine.rules && \
    # Create a default weston.ini config
    mkdir -p /root/.config/weston

# Add weston configuration
COPY weston.ini /root/.config/weston/weston.ini

# Add sunshine configuration script
COPY start-sunshine.sh /local/bin/
RUN chmod +x /local/bin/start-sunshine.sh

# Set entrypoint to show plugin info and provide usage instructions
# Create apps.json file for Sunshine
COPY apps.json /sunshine/apps.json

# Add volumes for configuration
VOLUME /sunshine

# Expose Sunshine ports
EXPOSE 47984/tcp 47989/tcp 48010/tcp 47998/udp 47999/udp 48000/udp 48002/udp 48010/udp 47990/tcp

# Set entrypoint to run Sunshine with the Wayland display source
ENTRYPOINT ["/bin/bash", "-c", "echo 'Wayland Display Streamer with Sunshine and NVIDIA GPU support'; echo 'Plugin location:' && find / -name 'libgstwaylanddisplaysrc.so' 2>/dev/null; echo 'Starting Sunshine streaming server...'; /local/bin/start-sunshine.sh"]
