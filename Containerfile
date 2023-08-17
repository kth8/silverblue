ARG SOURCE_IMAGE="${SOURCE_IMAGE}"
ARG BASE_IMAGE="quay.io/fedora-ostree-desktops/${SOURCE_IMAGE}"
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"

FROM ${BASE_IMAGE}:${FEDORA_MAJOR_VERSION}
ARG FEDORA_MAJOR_VERSION="${FEDORA_MAJOR_VERSION}"
ARG KERNEL_VERSION="${KERNEL_VERSION}"

RUN rpm-ostree override remove \
	firefox \
	firefox-langpacks \
	gnome-software \
	gnome-software-rpm-ostree \
	fedora-repos-modular \
	fedora-repos-archive \
	fedora-workstation-repositories

RUN rpm-ostree install \
	https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-${FEDORA_MAJOR_VERSION}.noarch.rpm \
	https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-${FEDORA_MAJOR_VERSION}.noarch.rpm

RUN rpm-ostree install akmod-nvidia xorg-x11-drv-nvidia-cuda nvidia-vaapi-driver
RUN ln -s /usr/bin/ld.bfd /etc/alternatives/ld && ln -s /etc/alternatives/ld /usr/bin/ld
RUN akmods --force --kernels ${KERNEL_VERSION} --kmod nvidia
RUN rpm-ostree install /var/cache/akmods/nvidia/kmod-nvidia-${KERNEL_VERSION}*.rpm
RUN modinfo /usr/lib/modules/${KERNEL_VERSION}/extra/nvidia/nvidia.ko.xz

COPY --from=ghcr.io/kth8/kmod-zfs:${KERNEL_VERSION} /rpms /var/tmp
COPY --from=ghcr.io/ublue-os/akmods:${FEDORA_MAJOR_VERSION} /rpms/kmods/kmod-v4l2loopback*.rpm /var/tmp
RUN rpm-ostree install /var/tmp/*.rpm
RUN rpm-ostree install libvirt virt-manager

COPY cosign.pub /etc/pki/containers/kth8.pub
COPY policy.json /etc/containers/policy.json
COPY kth8.yaml /etc/containers/registries.d/kth8.yaml

RUN rm -rf /tmp/* /var/*
RUN ostree container commit
RUN install -d -m 1777 /var/tmp
