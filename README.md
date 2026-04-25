# Guacamole + VNC sur l'hote/VM

Ce README decrit le mode principal du projet:

- Guacamole, guacd et Postgres tournent dans Docker.
- Le bureau Linux et le serveur VNC tournent directement sur la VM/hote.

Pour le mode ou tout tourne dans Docker, voir [README.fulldocker.md](README.fulldocker.md).

## Prerequis

Sur la VM Debian:

- Docker + Docker Compose
- `git`, `make`, `bash`, `openssl`, `curl`
- un acces SSH fonctionnel

Exemple:

```bash
sudo apt update
sudo apt install -y git make bash openssl ca-certificates curl
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
```

Reconnecte-toi ensuite a la VM pour appliquer le groupe Docker.

## Configuration

Copie le fichier d'exemple host/VM:

```bash
cp .env.host.example .env
nano .env
```

Valeurs importantes:

```env
POSTGRES_PASSWORD=replace_with_a_strong_password
VM_USER=radandri
VM_IP=10.0.2.15
SSH_PORT=4242
GUAC_PORT=8081
HOST_VNC_USER=radandri
HOST_VNC_HOST=host.docker.internal
HOST_VNC_PORT=5901
HOST_VNC_PASSWORD=replace_with_a_strong_vnc_password
VNC_PASSWORD=replace_with_a_strong_vnc_password
```

Garde `HOST_VNC_PASSWORD` et `VNC_PASSWORD` identiques, sauf si tu configures le mot de passe VNC manuellement.

## Installation

Depuis le dossier du projet sur la VM:

```bash
make -f Makefile.host prepare
make -f Makefile.host up
make -f Makefile.host setup-vnc-host
make -f Makefile.host restart-vnc-host
make -f Makefile.host status-vnc-host
make -f Makefile.host add-connection
```

Ce que font ces commandes:

- `prepare`: genere l'initialisation Postgres et les certificats locaux.
- `up`: demarre Guacamole, guacd et Postgres en Docker.
- `setup-vnc-host`: installe/configure XFCE + VNC sur la VM.
- `restart-vnc-host`: demarre le serveur VNC sur la VM.
- `add-connection`: ajoute dans Guacamole une connexion vers `host.docker.internal:5901`.

## Acces depuis Windows/WSL avec VirtualBox NAT

Si la VM est en NAT VirtualBox, ajoute des redirections de ports:

```text
Name        Protocol  Host IP     Host Port  Guest IP    Guest Port
ssh         TCP       127.0.0.1   4242       10.0.2.15   4242
guacamole   TCP       127.0.0.1   8081       10.0.2.15   8081
```

Depuis WSL:

```bash
ssh radandri@127.0.0.1 -p 4242
```

### Subtilite WSL2

Avec WSL2, `127.0.0.1` peut pointer vers WSL lui-meme au lieu de Windows. Dans ce cas, la redirection VirtualBox existe cote Windows, mais WSL ne la voit pas sur `127.0.0.1`.

Symptomes typiques:

```text
ssh: connect to host 127.0.0.1 port 4242: Connection refused
ssh: connect to host 10.0.2.15 port 4242: No route to host
```

Recupere l'adresse IP Windows vue depuis WSL:

```bash
ip route | awk '/default/ {print $3}'
```

Puis connecte-toi avec cette IP:

```bash
ssh -p 4242 radandri@172.28.160.1
```

Remplace `172.28.160.1` par la valeur retournee par la commande `ip route`. Si ca marche, mets cette adresse dans `.env`:

```env
VM_IP=172.28.160.1
SSH_PORT=4242
VM_USER=radandri
```

Depuis le navigateur Windows:

```text
http://127.0.0.1:8081/guacamole
```

Login initial Guacamole:

```text
guacadmin / guacadmin
```

Change ce mot de passe apres la premiere connexion.

## Commandes utiles

```bash
make -f Makefile.host help
make -f Makefile.host env
make -f Makefile.host connect
make -f Makefile.host status
make -f Makefile.host status-vnc-host
make -f Makefile.host restart
make -f Makefile.host restart-vnc-host
make -f Makefile.host down
```

## Ports

| Service | Port | Notes |
| --- | --- | --- |
| SSH VM | `4242/tcp` | D'apres ta config actuelle. |
| Guacamole web | `8081/tcp` | A ouvrir ou rediriger depuis VirtualBox. |
| VNC host/VM | `5901/tcp` | Utilise par Guacamole; pas besoin de l'exposer a Windows si Guacamole tourne sur la meme VM. |