FROM debian:11-slim

# Add the `render` group with the same GID as in the host:
ARG RENDER_GID

RUN addgroup --gid ${RENDER_GID} render

RUN perl -i -pe 's/main/main contrib non-free/' /etc/apt/sources.list && apt update

# Install AMD OpenCL support
RUN apt install -y --no-install-recommends ocl-icd-libopencl1 mesa-opencl-icd

# Install Nvidia OpenCL and CUDA support
RUN apt install -y --no-install-recommends nvidia-opencl-icd nvidia-libopencl1; \
    apt install -y --no-install-recommends ocl-icd-opencl-dev

LABEL license="MIT"
LABEL author="Copyright 2022 Michael K. Franzl <michael@franzl.name>"
LABEL description="Debian with AMD GPU OpenCL and Nvidia GPU OpenCL/CUDA support"
