FROM registry.desku.be/deskube/streamer-base:latest

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
    pciutils-devel 

RUN cmake -Bbuild -DCMAKE_C_FLAGS="$CFLAGS" -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=17 -DCMAKE_CXX_EXTENSIONS=OFF -G Ninja
RUN ninja -C build

ADD runwolf.sh /local/bin/runwolf.sh

RUN chmod +x /local/bin/runwolf.sh
CMD ["/local/bin//runwolf.sh"]
