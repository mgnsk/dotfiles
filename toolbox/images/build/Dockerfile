FROM fedora:33

ARG uid
ARG gid
ARG user
ARG group

RUN dnf upgrade -y \
	&& dnf groupinstall -y "C Development Tools and Libraries" \
	&& dnf install --setopt=install_weak_deps=False -y \
	git \
	cmake \
	ninja-build \
	unzip \
	gettext \
	wget \
	&& dnf clean all \
	&& groupadd -g ${gid} ${group} \
	&& useradd \
	--home-dir /homedir \
	-g ${group} \
	--uid ${uid} \
	${user} \
	&& rm -rf /root \
	&& ln -s /homedir /root
