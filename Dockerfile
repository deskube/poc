FROM registry.desku.be/deskube/gst-wayland-display:latest

# Set NVIDIA GPU information and create wrapper script for Wayland display
COPY run-wayland-display.sh /local/bin/
RUN chmod +x /local/bin/run-wayland-display.sh

RUN dnf install -y \
   mesa-dri-drivers mesa-libGL mesa-libEGL mesa-libGLES \
   libdrm libdrm-devel \
   weston weston-libs weston-simple-egl \
   tmux procps-ng \
   wayland-protocols-devel

# Create required directories
RUN mkdir -p /local/bin && \
    mkdir -p /local/lib64/gstreamer-1.0 && \
    # Create a default weston.ini config
    mkdir -p /root/.config/weston

# Add weston configuration
COPY weston.ini /root/.config/weston/weston.ini

# Set entrypoint to run the Wayland display with weston-simple-egl demo
ENTRYPOINT ["/bin/bash", "-c", "echo 'Wayland Display with weston-simple-egl demo'; echo 'Plugin location:' && find / -name 'libgstwaylanddisplaysrc.so' 2>/dev/null; echo 'Starting Wayland environment...'; /local/bin/run-wayland-display.sh"]
