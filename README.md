# Desku.be - Virtual Desktop and Game Streaming in Kubernetes

This project provides a proof-of-concept implementation for running desktop environments inside Kubernetes containers.

## Components

- **run-wayland-display.sh**: Sets up a virtual Wayland display using GStreamer
- **start-sunshine.sh**: Configures and starts the Sunshine streaming server
- **apps.json**: Defines applications that can be launched in the virtual desktop
- **Dockerfile**: Container definition with all necessary components
- **stream-base-*.yaml**: Kubernetes manifests for deployment
- **weston.ini**: Configuration for the Weston Wayland compositor

## Sunshine Configuration

The Sunshine server is configured in `start-sunshine.sh` with settings for:

- Video encoding (NVENC by default)
- Frame rate and bitrate
- Audio configuration
- Network settings

## Architecture

- **Virtual Display Layer**: Uses GStreamer's waylanddisplaysrc to create a virtual Wayland display
- **Application Layer**: Applications run inside the container and render to the virtual display
- **Streaming Layer**: Sunshine captures the display and streams it to remote clients
- **Kubernetes Layer**: MetalLB provides external access to the streaming services

## MetalLB Configuration

MetalLB is used to provide external access to the streaming services running in Kubernetes. The configuration consists of:

**IP Address Pool**:

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ip-addresspool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.0.1-192.168.0.100 # Replace by your IP range
```

**L2 Advertisement**:

```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: l2-advertisement
  namespace: metallb-system
spec:
  ipAddressPools:
  - ip-addresspool
```

## License

This project is licensed under the Apache License, Version 2.0. 
You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0

## Credits

- [Sunshine](https://github.com/LizardByte/Sunshine)
