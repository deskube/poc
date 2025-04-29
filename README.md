# Desku.be - Virtual Desktop and Game Streaming in Kubernetes

This proof-of-concept implements a virtual Wayland display inside a container that can capture and stream graphical content over the network using GStreamer's pipeline architecture. 

The demo showcases rendering weston-simple-egl (a spinning cube OpenGL demo) and streaming it to a remote client.

## Components

- **start.sh**: Sets up a virtual Wayland display using GStreamer and runs weston-simple-egl demo
- **Dockerfile**: Container definition with all necessary components (GStreamer, Wayland, Weston)
- **stream-base-*.yaml**: Kubernetes manifests for deployment

## Architecture

- **Virtual Display Layer**: Uses GStreamer's waylanddisplaysrc to create a virtual Wayland display without requiring real hardware
- **Application Layer**: The weston-simple-egl demo application runs inside the container and renders to the virtual Wayland display
- **Streaming Layer**: GStreamer captures the Wayland display content and streams it via RTP/UDP to remote clients

## Running the Demo

### Deploy streamer in Kubernetes

```bash
./deploy-stream-base.sh
```

The `start.sh` script:

1. Creates a virtual Wayland display using GStreamer's waylanddisplaysrc
2. Starts weston-simple-egl demo in a tmux window
3. Streams the rendered content via RTP/UDP

### Receiver command

To view the stream on a remote machine, run:

```bash
gst-launch-1.0 -v udpsrc port=5000 caps="application/x-rtp, media=(string)video, clock-rate=(int)90000, encoding-name=(string)RAW, sampling=(string)RGB, depth=(string)8, width=(string)1920, height=(string)1080" ! rtpvrawdepay ! videoconvert ! autovideosink
```

This will display the weston-simple-egl demo (spinning cube) that's being rendered inside the container.

## Building the Container(s)

The container build process use OpenShift BuildConfigs.
It can be triggered via the ```./build.sh``` scripts.

### Working with private registry

If you're deploying to OpenShift or another Kubernetes environment with a private registry:

```bash
oc create secret generic registry-pull-secret --from-file=.dockerconfigjson=/tmp/new-pull-secret.json --type=kubernetes.io/dockerconfigjson
oc secrets link builder registry-pull-secret --for=pull,mount
```

## License

This project is licensed under the Apache License, Version 2.0. 
You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
