# Guacamole + VNC (full Docker)

This repo runs Apache Guacamole, guacd, Postgres, and an XFCE VNC desktop fully containerized. No GUI or VNC needs to be installed on the host.

## Prerequisites
- Docker + Docker Compose
- Bash and OpenSSL available to run `prepare.sh` (generates DB init + self-signed certs)

## Quick start
```bash
./prepare.sh           # generates initdb.sql + self-signed TLS certs
docker compose up -d   # or: make up
```
Then open: `http://<HOST_IP>:8081/guacamole` (default login: guacadmin / guacadmin).

## Services and ports
- guacamole (web UI): 8081 -> 8080 in container
- guacd: internal only
- postgres: internal only, data in ./data
- vnc-desktop (XFCE + TigerVNC + noVNC):
  - VNC: 5901
  - noVNC: 6901 (websockify serving /usr/share/novnc)

## VNC container config
Environment variables on service `vnc-desktop` (see docker-compose.yml):
- VNC_USER (default: guac)
- VNC_PASSWORD (change before use)
- GEOMETRY (e.g. 1920x1080)
- DEPTH (e.g. 24)

Data:
- VNC runtime files: ./data/vnc mounted to /home/<user>/.vnc

To rebuild the VNC image (uses Dockerfile + start-vnc.sh):
```bash
docker compose build vnc-desktop
```

## Make targets
- make up / down / restart / status
- make connect (shows URL/ports)
- make ssh (if you still use an SSH-accessible VM)
- make env (print loaded variables)
- make clean-docker (reset + prune)

Host-side VNC install targets were removed because VNC now runs in the container.

## Notes
- If you enable the optional nginx reverse-proxy, expose 8443 and point your browser to https://\<HOST_IP\>:8443/guacamole.
- Default credentials are for initial setup only—change them immediately inside Guacamole.
