#!/bin/bash
# Configure Sunshine for headless operation
mkdir -p $HOME/.config/sunshine
cat > $HOME/.config/sunshine/sunshine.conf << EOF
encoder = nvenc
adapter_name = NVIDIA
framerate = 60

# Use specific display settings for headless mode
output_name = Wayland Display
virtual_sink = true
cmd = true
virtual_input = true
origin_web_ui = 0.0.0.0

# Force specific video settings
audio_sink = virtual
channels = 2
hevc_mode = 0
min_bitrate = 5
max_bitrate = 50
fpm = 60
remote_touch = true

# Wayland/headless specific settings
capture = wayland
wayland.frame_timestamps = true
wayland.draw_cursor = true
wayland.force_yuv = true

# Configure to use wlr-export-dmabuf-unstable protocol
wlr_export_dmabuf = true
wlr_overlay_cursor = true

# If hardware encoding fails, fall back to software
encoder.fallback = software

# Network settings
upnp = false
port = 47989
file_apps = /sunshine/apps.json
EOF

# Setup environment
export XDG_SESSION_TYPE=wayland
export WAYLAND_DISPLAY=wayland-1
export LIBVA_DRIVER_NAME=nvidia
export LIBVA_DRIVERS_PATH=/usr/lib64/dri
export WAYLAND_DEBUG=1
export XDG_DATA_DIRS=/usr/local/share:/usr/share
export WLR_NO_HARDWARE_CURSORS=1
export XDG_CURRENT_DESKTOP=sway

# Run the wayland display setup script first
echo "Starting Wayland display setup in tmux session..."
/local/bin/run-wayland-display.sh &
sleep 5

# Check if the Wayland socket exists after running the setup
if [ -e "$XDG_RUNTIME_DIR/wayland-1" ]; then
    echo "Wayland socket found at $XDG_RUNTIME_DIR/wayland-1"
else
    echo "ERROR: No Wayland socket found in $XDG_RUNTIME_DIR"
    ls -la $XDG_RUNTIME_DIR
    exit 1
fi

# Check for running tmux session and Wayland processes
if tmux has-session -t wayland-streaming 2>/dev/null; then
    echo "Tmux session 'wayland-streaming' is running"
    # Check if there's a waylanddisplaysrc or weston process running
    if pgrep -f "waylanddisplaysrc" > /dev/null || pgrep -f "weston" > /dev/null; then
        echo "Found running Wayland-related processes, continuing..."
    else
        echo "WARNING: Tmux is running but no Wayland processes found"
        echo "Attaching to tmux session to check status..."
        tmux capture-pane -t wayland-streaming:0 -p
    fi
else
    echo "WARNING: Tmux session 'wayland-streaming' not found"
    # Check if there's a waylanddisplaysrc or weston process running
    if pgrep -f "waylanddisplaysrc" > /dev/null || pgrep -f "weston" > /dev/null; then
        echo "Found running Wayland-related processes, continuing despite missing tmux session..."
    else
        echo "ERROR: No Wayland-related processes found running"
        exit 1
    fi
fi

# Start sunshine in the tmux session
if tmux has-session -t wayland-streaming 2>/dev/null; then
    echo "Starting Sunshine in tmux window 4..."
    tmux send-keys -t wayland-streaming:4 "sunshine --sunshine log_level 6" C-m
    
    # Attach to the tmux session so the container keeps running
    echo "Attaching to tmux session wayland-streaming..."
    exec tmux attach-session -t wayland-streaming
else
    # Fallback to running Sunshine directly if tmux session failed
    echo "Starting Sunshine in foreground mode..."
    sunshine --sunshine log_level 6
fi
