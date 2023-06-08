FROM ubuntu:20.04 AS builder

LABEL maintainer="AnatoleLucet"

ARG BUILD_APT_DEPS="ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip git binutils wget"
ARG DEBIAN_FRONTEND=noninteractive
ARG TARGET=stable

RUN apt update && apt upgrade -y && \
  apt install -y ${BUILD_APT_DEPS} && \
  git clone https://github.com/neovim/neovim.git /tmp/neovim && \
  cd /tmp/neovim && \
  git fetch --all --tags -f && \
  git checkout ${TARGET} && \
  make CMAKE_BUILD_TYPE=RelWithDebInfo CMAKE_INSTALL_PREFIX=/usr/local/ && \
  make install && \
  strip /usr/local/bin/nvim

FROM ubuntu:20.04
COPY --from=builder /usr/local /usr/local/
RUN mkdir -p /root/.config
RUN apt update && apt install -y git curl
COPY nvim /root/.config/nvim

CMD ["/usr/local/bin/nvim"]
