#!/bin/bash
set -e

# Set up environment variables for GStreamer and NVIDIA
export GST_PLUGIN_PATH=/usr/local/lib64/gstreamer-1.0:/local/lib64/gstreamer-1.0
export GST_DEBUG=3

export XDG_SESSION_TYPE=wayland
export WAYLAND_DISPLAY=wayland-1
export WAYLAND_DEBUG=1
export XDG_DATA_DIRS=/usr/local/share:/usr/share
export WLR_NO_HARDWARE_CURSORS=1

# Make sure XDG_RUNTIME_DIR is set and the directory exists
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/xdg-runtime-dir}
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

# Start a new tmux session if not already in one
if [ -z "$TMUX" ]; then
  # Kill any existing tmux sessions
  tmux kill-server 2>/dev/null || true
  # Create a new session named "wayland-streaming"
  tmux new-session -d -s wayland-streaming
fi

# Create a virtual video sink
echo "Setting up virtual Wayland display using waylanddisplaysrc..."

# Start GStreamer waylanddisplaysrc in tmux first window - this will create the Wayland display
echo "Starting GStreamer waylanddisplaysrc to create Wayland display in tmux window..."
tmux send-keys -t wayland-streaming:0 "echo 'Starting GStreamer waylanddisplaysrc...'" C-m
tmux send-keys -t wayland-streaming:0 "GST_PLUGIN_PATH=/usr/local/lib64/gstreamer-1.0 gst-launch-1.0 -v waylanddisplaysrc render-node=software ! 'video/x-raw,width=1920,height=1080,format=RGBx,framerate=60/1' ! videoconvert ! video/x-raw,format=RGB ! rtpvrawpay ! udpsink host=$RECEIVER_IP port=5000" C-m

# Give it time to create the socket
sleep 3

# Set the Wayland display variable
export WAYLAND_DISPLAY=wayland-1

# Verify that the Wayland socket exists
if [ ! -S "$XDG_RUNTIME_DIR/wayland-1" ]; then
  echo "ERROR: Wayland socket not found at $XDG_RUNTIME_DIR/wayland-1"
  ls -la $XDG_RUNTIME_DIR
  exit 1
fi

echo "Wayland socket is available at $XDG_RUNTIME_DIR/wayland-1"

# Now start Sway as a client to the existing Wayland display
echo "Starting Sway window manager..."

# Export protocol paths to ensure they're found
export XDG_DATA_DIRS=/usr/local/share:/usr/share
export WAYLAND_DEBUG=1

# Copy the Sway configuration file to the user's config directory
mkdir -p $HOME/.config/sway
cp /local/bin/sway-config $HOME/.config/sway/config

# Start Sway window manager in tmux window 1
echo "Starting Sway window manager..."
tmux new-window -t wayland-streaming:1
tmux send-keys -t wayland-streaming:1 "echo 'Starting Sway window manager...'" C-m
tmux send-keys -t wayland-streaming:1 "export WAYLAND_DISPLAY=wayland-1" C-m
tmux send-keys -t wayland-streaming:1 "export WLR_BACKENDS=headless" C-m  
tmux send-keys -t wayland-streaming:1 "export WLR_RENDERER=pixman" C-m
tmux send-keys -t wayland-streaming:1 "sway --config $HOME/.config/sway/config" C-m
sleep 4

echo "Wayland display environment setup successfully"

# Show tmux status and instructions
echo -e "\nTMUX sessions are running with the following windows:"
echo "  0: GStreamer waylanddisplaysrc"
echo "  1: Sway window manager"
echo -e "\nYou can attach to these sessions with: tmux attach-session -t wayland-streaming"
echo "Virtual Wayland display with Sway window manager is ready"

# Keep the script running until tmux session ends
tmux wait-for wayland-streaming
