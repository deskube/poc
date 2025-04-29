FROM registry.desku.be/deskube/gst-wayland-display:latest

RUN dnf install -y \
   sway i3status foot dmenu \
   tmux procps-ng

ADD start.sh /local/bin/start.sh
ADD sway-config /local/bin/sway-config
RUN chmod +x /local/bin/start.sh

# Set entrypoint to run the Wayland display with weston-simple-egl demo
ENTRYPOINT ["/local/bin/start.sh"]
