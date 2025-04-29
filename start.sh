#!/bin/bash
# Setup script for the Wayland display configuration

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
    wayland-info
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

# Attach to the tmux session so the container keeps running
if tmux has-session -t wayland-streaming 2>/dev/null; then
    echo "Attaching to tmux session wayland-streaming..."
    echo "The weston-simple-egl demo should be visible in the stream"
    exec tmux attach-session -t wayland-streaming
else
    echo "No tmux session found, exiting..."
    exit 1
fi
