#!/bin/bash
set -e

# Set up environment variables for GStreamer and NVIDIA
export GST_PLUGIN_PATH=/usr/local/lib64/gstreamer-1.0:/local/lib64/gstreamer-1.0
export GST_DEBUG=3

# Make sure XDG_RUNTIME_DIR is set and the directory exists
export XDG_RUNTIME_DIR=${XDG_RUNTIME_DIR:-/tmp/xdg-runtime-dir}
mkdir -p $XDG_RUNTIME_DIR
chmod 700 $XDG_RUNTIME_DIR

export RECEIVER_IP=172.16.87.100

# Install tmux if not already installed
if ! command -v tmux &> /dev/null; then
  echo "Installing tmux..."
  dnf install -y tmux
fi

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

# Now start Weston as a client to the existing Wayland display
echo "Starting Weston as a Wayland client..."

# Export protocol paths to ensure they're found
export XDG_DATA_DIRS=/usr/local/share:/usr/share
export WAYLAND_DEBUG=1

# Start the weston-simple-egl demo in tmux window 1
echo "Starting weston-simple-egl demo..."
tmux new-window -t wayland-streaming:1
tmux send-keys -t wayland-streaming:1 "echo 'Starting weston-simple-egl demo...'" C-m
tmux send-keys -t wayland-streaming:1 "export WAYLAND_DISPLAY=wayland-1" C-m
tmux send-keys -t wayland-streaming:1 "weston-simple-egl" C-m
sleep 2

echo "Wayland display environment setup successfully"

# Show tmux status and instructions
echo -e "\nTMUX sessions are running with the following windows:"
echo "  0: GStreamer waylanddisplaysrc"
echo "  1: Weston-simple-egl demo"
echo -e "\nYou can attach to these sessions with: tmux attach-session -t wayland-streaming"
echo "Virtual Wayland display is ready"

# Keep the script running until tmux session ends
tmux wait-for wayland-streaming
