# Guacamole + VNC full Docker

Ce mode lance tout dans Docker:

- Guacamole
- guacd
- Postgres
- bureau XFCE + serveur VNC

Le mode host/VM est documente dans [README.md](README.md).

## Prerequis

- Docker + Docker Compose
- `git`, `make`, `bash`, `openssl`, `curl`

Exemple Debian:

```bash
sudo apt update
sudo apt install -y git make bash openssl ca-certificates curl
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
```

Reconnecte-toi ensuite pour appliquer le groupe Docker.

## Configuration

```bash
cp .env.full-docker.example .env
nano .env
```

Valeurs importantes:

```env
POSTGRES_PASSWORD=replace_with_a_strong_password
VNC_PASSWORD=replace_with_a_strong_vnc_password
VNC_USER=guac
GEOMETRY=1920x1080
DEPTH=24
GUAC_PORT=8081
VNC_PORT=5901
```

## Installation rapide

```bash
make -f Makefile.full-docker install
```

Cette commande lance:

- `prepare`
- `up`
- `add-connection`

## Installation manuelle

```bash
make -f Makefile.full-docker prepare
make -f Makefile.full-docker up
make -f Makefile.full-docker add-connection
```

Puis ouvre:

```text
http://<IP_VM>:8081/guacamole
```

Login initial:

```text
guacadmin / guacadmin
```

Change ce mot de passe apres la premiere connexion.

## Services et ports

| Service | Port | Notes |
| --- | --- | --- |
| Guacamole web | `8081/tcp` | Web UI sur `/guacamole`. |
| VNC Docker | `5901/tcp` | Bureau VNC du conteneur `vnc-desktop`. |
| noVNC Docker | `6901/tcp` | Client web noVNC du conteneur. |
| guacd | interne | Pas besoin d'exposer. |
| Postgres | interne | Pas besoin d'exposer. |

## Commandes utiles

```bash
make -f Makefile.full-docker help
make -f Makefile.full-docker env
make -f Makefile.full-docker connect
make -f Makefile.full-docker status
make -f Makefile.full-docker restart
make -f Makefile.full-docker re
make -f Makefile.full-docker down
```

## Donnees

```text
./drive   -> /drive
./record  -> /record
./data/vnc -> /home/<VNC_USER>/.vnc
```

`./prepare.sh` cree les dossiers partages et corrige leurs permissions.

## Notes

- Si la VM est en NAT VirtualBox, redirige au minimum le port `8081`.
- Si tu actives le reverse proxy nginx optionnel, expose `8443` et ouvre `https://<IP_VM>:8443/guacamole`.
