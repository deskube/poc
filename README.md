# Desku.be - Virtual Desktop and Game Streaming in Kubernetes

This project provides a proof-of-concept implementation for running desktop environments inside Kubernetes containers.

## Components

- **run-wayland-display.sh**: Sets up a virtual Wayland display using GStreamer
- **Dockerfile**: Container definition with all necessary components
- **stream-base-*.yaml**: Kubernetes manifests for deployment

## Architecture

- **Virtual Display Layer**: Uses GStreamer's waylanddisplaysrc to create a virtual Wayland display
- **Application Layer**: Applications run inside the container and render to the virtual display
- **Streaming Layer**: Sunshine captures the display and streams it to remote clients
- **Kubernetes Layer**: MetalLB provides external access to the streaming services

## Deploy streamer

```bash
./deploy-stream-base.sh
```

## Receiver command

```bash
gst-launch-1.0 -v udpsrc port=5000 caps="application/x-rtp, media=(string)video, clock-rate=(int)90000, encoding-name=(string)RAW, sampling=(string)RGB, depth=(string)8, width=(string)1920, height=(string)1080" ! rtpvrawdepay ! videoconvert ! autovideosink
```

## Working with private registry

```bash
oc create secret generic registry-pull-secret --from-file=.dockerconfigjson=/tmp/new-pull-secret.json --type=kubernetes.io/dockerconfigjson
oc secrets link builder registry-pull-secret --for=pull,mount
```

## License

This project is licensed under the Apache License, Version 2.0. 
You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
