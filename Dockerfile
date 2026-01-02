FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y \
    xfce4 xfce4-terminal tigervnc-standalone-server novnc websockify curl sudo dbus-x11 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
# ajouter création d'utilisateur, configuration VNC, scripts d'entrypoint...
COPY start-vnc.sh /usr/local/bin/start-vnc.sh
RUN chmod +x /usr/local/bin/start-vnc.sh
EXPOSE 5901 6901
CMD ["/usr/local/bin/start-vnc.sh"]
