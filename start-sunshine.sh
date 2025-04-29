#!/bin/bash
# Configure Sunshine for headless operation with weston-simple-egl
mkdir -p $HOME/.config/sunshine
cat > $HOME/.config/sunshine/sunshine.conf << EOF
# Allow fallback to software encoding if hardware isn't available
encoder = software
framerate = 60

# Use specific display settings for headless mode
output_name = Wayland-Simple-EGL
virtual_sink = true
cmd = true
virtual_input = true
origin_web_ui = 0.0.0.0

# Force specific video settings
audio_sink = virtual
channels = 2
min_bitrate = 5
max_bitrate = 50
fpm = 60

# Wayland/headless specific settings for weston-simple-egl
capture = wayland
wayland.frame_timestamps = true
wayland.draw_cursor = true
wayland.force_yuv = true

# Network settings
upnp = false
port = 47989
file_apps = /sunshine/apps.json
EOF

# Setup environment
export XDG_SESSION_TYPE=wayland
export WAYLAND_DISPLAY=wayland-1
export WAYLAND_DEBUG=1
export XDG_DATA_DIRS=/usr/local/share:/usr/share
export WLR_NO_HARDWARE_CURSORS=1

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
        # Check for weston-simple-egl process
        if pgrep -f "weston-simple-egl" > /dev/null; then
            echo "weston-simple-egl demo is running"
        else
            echo "WARNING: weston-simple-egl demo not found, it should be running in tmux window 2"
        fi
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
    # Create a new window for Sunshine if it doesn't exist
    tmux new-window -t wayland-streaming:4 2>/dev/null || true
    echo "Starting Sunshine in tmux window 4..."
    tmux send-keys -t wayland-streaming:4 "echo 'Starting Sunshine streaming server...'" C-m
    tmux send-keys -t wayland-streaming:4 "sunshine --sunshine log_level 6" C-m
    
    # Attach to the tmux session so the container keeps running
    echo "Attaching to tmux session wayland-streaming..."
    echo "Sunshine streaming server should be accessible at http://$(hostname -I | awk '{print $1}'):47989"
    echo "The weston-simple-egl demo should be visible in the stream"
    exec tmux attach-session -t wayland-streaming
else
    # Fallback to running Sunshine directly if tmux session failed
    echo "Starting Sunshine in foreground mode..."
    echo "Sunshine streaming server should be accessible at http://$(hostname -I | awk '{print $1}'):47989"
    sunshine --sunshine log_level 6
fi
