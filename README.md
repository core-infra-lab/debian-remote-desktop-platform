# Guacamole + VNC (full Docker or host/VM VNC)

This repo supports two modes:
- Full Docker: Apache Guacamole, guacd, Postgres, and XFCE VNC desktop all in containers.
- Host/VM VNC: Guacamole in Docker, while GUI + VNC run on the host (or another VM).

Default behavior remains Full Docker.

## Prerequisites
- Docker + Docker Compose
- Bash and OpenSSL available to run `prepare.sh` (generates DB init + self-signed certs)

## Quick start
```bash
cp .env.example .env
# edit .env and set strong values for POSTGRES_PASSWORD and VNC_PASSWORD
./prepare.sh           # generates initdb.sql + self-signed TLS certs
docker compose up -d   # or: make up
```
Then open: `http://<HOST_IP>:8081/guacamole` (default login: guacadmin / guacadmin).

## Choose your mode

### 1) Full Docker (default)
```bash
make up
make add-connection-docker
```
This starts `vnc-desktop` in Docker and points Guacamole to `vnc-desktop:5901`.

### 2) Host/VM VNC (legacy option)
```bash
make up-host
make setup-vnc-host
make restart-vnc-host
make add-connection-host
```
This starts only `guacamole`, `guacd`, and `postgres` in Docker, then points Guacamole to `host.docker.internal:5901`.

If your VNC server is not on the Docker host, override variables:
```bash
make add-connection-host HOST_VNC_HOST=<IP_OR_DNS> HOST_VNC_PORT=5901
```

Required secrets now come from environment variables (`.env`):
- `POSTGRES_PASSWORD`
- `VNC_PASSWORD`

`./prepare.sh` also creates the shared folders and fixes their permissions:
- `./drive`
- `./record`
- `./data/vnc`

## Services and ports
- guacamole (web UI): 8081 -> 8080 in container
- guacd: internal only
- postgres: internal only, data in ./data
- vnc-desktop (XFCE + TigerVNC + noVNC):
  - VNC: 5901
  - noVNC: 6901 (websockify serving /usr/share/novnc)

## Ports to open
Open only what is needed for the target you want to reach.

| Use case | Ports to open | Notes |
| --- | --- | --- |
| Guacamole web UI on the Docker host | `8081/tcp` | Use `443/tcp` instead if you put Guacamole behind an HTTPS reverse proxy. |
| Local VNC desktop in this repo | `5901/tcp` on the `vnc-desktop` container | Already exposed by Docker Compose; nothing extra to open on the host if you access Guacamole locally. |
| Remote VM with VNC | `5901/tcp` on the VM | Restrict source access to the Guacamole host or private network when possible. |
| Remote VM with SSH | `22/tcp` on the VM | Only if you also use SSH. |
| Remote VM with RDP | `3389/tcp` on the VM | Use this instead of VNC when the target is Windows or an RDP server. |
| EC2 VNC instance | `5901/tcp` on the security group | Prefer allowing only the Guacamole host IP, not `0.0.0.0/0`. |
| EC2 SSH access | `22/tcp` on the security group | Same rule: limit to your admin IP or VPN. |

Rule of thumb:
- Guacamole needs access to the target service port from the Guacamole host or Docker network.
- The VNC or RDP port should not be public unless you really need it.
- Docker internal services like `guacd` and PostgreSQL stay private; you do not open extra ports for them.

## VNC container config
Environment variables on service `vnc-desktop` (see docker-compose.yml):
- VNC_USER (default: guac)
- VNC_PASSWORD (required)
- GEOMETRY (e.g. 1920x1080)
- DEPTH (e.g. 24)

Data:
- VNC runtime files: ./data/vnc mounted to /home/<user>/.vnc

To rebuild the VNC image (uses Dockerfile + start-vnc.sh):
```bash
docker compose build vnc-desktop
```

## Make targets
- make up / up-host / up-full-docker / down / restart / status
- make connect (shows URL/ports)
- make ssh (if you still use an SSH-accessible VM)
- make setup-vnc-host / restart-vnc-host / status-vnc-host
- make add-connection-docker / add-connection-host
- make add-connection (creates or updates a Guacamole VNC connection)
- make env (print loaded variables)
- make clean-docker (reset + prune)

Connection guide: see [docs/guacamole-connection-manual.md](docs/guacamole-connection-manual.md).
File sharing guide: see [docs/files-host-container.md](docs/files-host-container.md).

### Host vs Container
```text
Host (radandri)                 Container (guac)
./drive   -------------------->  /drive
./record  <--------------------  /record
./data/vnc --------------------> /home/guac/.vnc
```

Host-side VNC install targets are available as an optional legacy mode (`*-host` targets).

## Notes
- If you enable the optional nginx reverse-proxy, expose 8443 and point your browser to https://\<HOST_IP\>:8443/guacamole.
- Default credentials are for initial setup only—change them immediately inside Guacamole.
