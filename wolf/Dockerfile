FROM registry.desku.be/deskube/streamer-base:latest

# Install dependencies
RUN dnf install -y \
    curl \
    ca-certificates \
    ninja-build \
    cmake \
    pkgconf \
    ccache \
    git \
    clang \
    boost-devel boost-thread boost-locale boost-filesystem boost-log boost-stacktrace boost-container \
    wayland-devel libwayland-server libinput-devel libxkbcommon-devel mesa-libgbm-devel \
    libcurl-devel \
    openssl-devel \
    libevdev-devel \
    pulseaudio-libs-devel \
    libunwind-devel \
    systemd-devel \
    libdrm-devel \
    pciutils-devel \
    wayland-protocols-devel && \
    dnf clean all

# Clone Wolf source code
WORKDIR /usr/src
RUN git clone https://github.com/games-on-whales/wolf.git
WORKDIR /usr/src/wolf

# Apply fix for the get_port function that's missing a return value
# RUN sed -i 's/int get_port(STANDARD_PORTS_MAPPING port_type) {/int get_port(STANDARD_PORTS_MAPPING port_type) {\n    return 0; \/\/ Default return value/' src/moonlight-server/state/data-structures.hpp

# Build wolf
# RUN cmake -Bbuild -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=17 -DCMAKE_CXX_EXTENSIONS=OFF -G Ninja
# RUN ninja -C build

# Copy the run script
COPY runwolf.sh /usr/local/bin/runwolf.sh

# Set up permissions and default command
RUN chmod +x /usr/local/bin/runwolf.sh
CMD ["/usr/local/bin/runwolf.sh"]
