FROM registry.desku.be/deskube/gst-wayland-display:latest

RUN dnf install -y \
   weston-simple-egl \
   tmux procps-ng

ADD start.sh /local/bin/start.sh
RUN chmod +x /local/bin/start.sh

# Set entrypoint to run the Wayland display with weston-simple-egl demo
ENTRYPOINT ["/local/bin/start.sh"]
