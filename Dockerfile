FROM registry.desku.be/deskube/gst-wayland-display:latest

# Set NVIDIA GPU information and create wrapper script for Wayland display
COPY run-wayland-display.sh /local/bin/
RUN chmod +x /local/bin/run-wayland-display.sh

RUN dnf install -y \
   weston-simple-egl \
   tmux procps-ng \
   wayland-protocols-devel wayland-utils

ADD run-wayland-display.sh /local/bin/run-wayland-display.sh
ADD start.sh /local/bin/start.sh

RUN chmod +x /local/bin/run-wayland-display.sh &&\
    chmod +x /local/bin/start.sh

# Set entrypoint to run the Wayland display with weston-simple-egl demo
ENTRYPOINT ["/local/bin/start.sh"]
