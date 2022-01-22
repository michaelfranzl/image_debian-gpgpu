# image_debian-gpgpu

Dockerfile for a Debian 11 base image with AMD and Nvidia GPGPU (OpenCL, CUDA) support.

## Host preparation for GPU hardware acceleration on Debian 11

### AMD GPU

It is very easy to set up AMD computing using just the official Debian repos:

```sh
apt install ocl-icd-libopencl1 mesa-opencl-icd
```

Then use `clinfo` (from the package `clinfo`) to display information about your hardware platform.

You can monitor the GPU load using `radeontop` (from the package `radeontop`).

The devices in the directory `/dev/dri` provide hardware access and must be exposed to the container
using the `--device` argument of `docker run`. The device nodes in this directory
(`/dev/dri/renderD128` or similar) have permissions `crw-rw----+ root render`. Because mounting this
directory as a Docker volume doesn't change the permissions or ownership, the container's
`fahclient` user needs to be placed in the same `render` group (with the same GID) so that there
will be access to this device. Sadly, GIDs are not uniform across systems, and even may depend on the
installation order of applications; this means that the container image needs to be re-built
for every host using a custom `docker build` argument (see below).

### Nvidia GPU

It is also very easy to set up NVidia computing using just the official Debian repos. Simply install
the `nvidia-opencl-icd` package (from the Debian `non-free` component). This will pull in a large
swathe of recommended packages like the non-free, proprietary Nvidia graphics driver, `libcuda1`,
`nvidia-smi`, etc.

```
apt install nvidia-opencl-icd

The following additional packages will be installed:
  glx-alternative-mesa glx-alternative-nvidia glx-diversions libcuda1 libnvidia-cfg1 libnvidia-compiler libnvidia-ml1 libnvidia-ptxjitcompiler1 libpci3 nvidia-alternative
  nvidia-installer-cleanup nvidia-kernel-common nvidia-kernel-dkms nvidia-kernel-support nvidia-legacy-check nvidia-modprobe nvidia-opencl-common nvidia-persistenced nvidia-smi
  nvidia-support ocl-icd-libopencl1 pci.ids pciutils update-glx
Suggested packages:
  libgl1-mesa-glx | libgl1 nvidia-driver | nvidia-driver-any nvidia-cuda-mps wget | curl | lynx-cur
Recommended packages:
  libcuda1:i386
The following NEW packages will be installed:
  glx-alternative-mesa glx-alternative-nvidia glx-diversions libcuda1 libnvidia-cfg1 libnvidia-compiler libnvidia-ml1 libnvidia-ptxjitcompiler1 libpci3 nvidia-alternative
  nvidia-installer-cleanup nvidia-kernel-common nvidia-kernel-dkms nvidia-kernel-support nvidia-legacy-check nvidia-modprobe nvidia-opencl-common nvidia-opencl-icd
  nvidia-persistenced nvidia-smi nvidia-support ocl-icd-libopencl1 pci.ids pciutils update-glx
0 upgraded, 25 newly installed, 0 to remove and 0 not upgraded.
Need to get 50.1 MB of archives.
After this operation, 157 MB of additional disk space will be used.
```

Now you need to reboot so that the proprietary Nvidia driver will be loaded. After, you can list
general information about your card by running `nvidia-smi` from the `nvidia-smi` package, or OpenCL
capabilities by running `clinfo` from the `clinfo` package. This also works on headless machines.

If you don't know if or how your Nvidia GPU is supported by Debian, try running `nvidia-detect` from
the `nvidia-detect` package.

#### Exposing Nvidia GPUs to containers

While AMD GPUs can be exposed to containers using plain Docker without any additional steps,
Nvidia GPUs need additional software (https://github.com/NVIDIA/nvidia-docker) which is not in the
official Debian repositories. This adds support for the `--gpus` command line switch of the `docker`
command line interface. The installation boils down to the following:

```sh
apt install curl
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
echo 'deb https://nvidia.github.io/libnvidia-container/experimental/debian10/$(ARCH) /' >> /etc/apt/sources.list.d/nvidia-container-runtime.list
echo 'deb https://nvidia.github.io/nvidia-container-runtime/experimental/debian10/$(ARCH) /' >> /etc/apt/sources.list.d/nvidia-container-runtime.list
apt update
apt install nvidia-docker2
systemctl restart docker
```

This [Github issue
comment](https://github.com/NVIDIA/nvidia-docker/issues/1268#issuecomment-632692949) explains the
involved software. Debian 11 shipped with a new `cgroups` system for which Nvidia has recently
[shipped support](https://github.com/NVIDIA/nvidia-docker/issues/1268#issuecomment-632692949) (this
is why the packages are in the `experimental/debian10` repo).

## Building the image

```sh
docker build -t debian-gpgpu --build-arg RENDER_GID=$(getent group render | awk -F: '{print $3}') .
```

## Running the image

```sh
docker run debian-gpgpu
```

* To expose AMD GPU(s) to the container, add the Docker argument `--device /dev/dri:/dev/dri`.
* To expose Nvidia GPU(s) to the container, add the Docker argument `--gpus all`.
