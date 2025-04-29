FROM registry.desku.be/deskube/gst-wayland-display:latest

# Set NVIDIA GPU information and create wrapper script for Wayland display
COPY run-wayland-display.sh /local/bin/
RUN chmod +x /local/bin/run-wayland-display.sh

RUN dnf install -y \
   weston-simple-egl \
   tmux procps-ng \
   wayland-protocols-devel

RUN dnf copr enable -y lizardbyte/stable && \
     dnf install -y Sunshine udev fuse fuse-libs xdpyinfo && \
     # Create required directories
     mkdir -p /dev/input && \
     mkdir -p /sunshine && \
     # Copy udev rules but don't try to reload (containers don't use udev)
     mkdir -p /etc/udev/rules.d && \
     echo 'KERNEL=="uinput", SUBSYSTEM=="misc", OPTIONS+="static_node=uinput", TAG+="uaccess"' > /etc/udev/rules.d/85-sunshine.rules && \
     echo 'KERNEL=="uhid", TAG+="uaccess"' >> /etc/udev/rules.d/85-sunshine.rules

# Set entrypoint to run the Wayland display with weston-simple-egl demo
ENTRYPOINT ["/bin/bash", "-c", "echo 'Wayland Display with weston-simple-egl demo'; echo 'Plugin location:' && find / -name 'libgstwaylanddisplaysrc.so' 2>/dev/null; echo 'Starting Wayland environment...'; /local/bin/run-wayland-display.sh"]
