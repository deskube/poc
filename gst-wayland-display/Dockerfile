FROM registry.fedoraproject.org/fedora:41

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
