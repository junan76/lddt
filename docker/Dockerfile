FROM ubuntu:22.04
MAINTAINER junan <junan76@163.com>

ARG gdb_port=1234
ARG lddt_root=/root/lddt

RUN apt update
RUN apt install -y make crossbuild-essential-armhf flex bison libncurses-dev bc qemu-system-arm

RUN chsh -s /bin/bash root
RUN ln -sf /root/lddt/deps/.vscode-server /root/.vscode-server

ENV LDDT_ROOT=$lddt_root
EXPOSE $gdb_port

WORKDIR /root

CMD /bin/bash