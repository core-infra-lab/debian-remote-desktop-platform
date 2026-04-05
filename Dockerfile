FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    xfce4 \
    xfce4-terminal \
    tigervnc-standalone-server \
    novnc \
    websockify \
    curl \
    sudo \
    zsh \
    dbus-x11 \
    build-essential \
    git \
    openssh-client \
    tar \
    nano \
    vim \
    ca-certificates \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
# ajouter création d'utilisateur, configuration VNC, scripts d'entrypoint...
COPY start-vnc.sh /usr/local/bin/start-vnc.sh
RUN chmod +x /usr/local/bin/start-vnc.sh
EXPOSE 5901 6901
CMD ["/usr/local/bin/start-vnc.sh"]

