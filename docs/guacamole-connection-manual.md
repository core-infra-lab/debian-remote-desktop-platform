# Guacamole Connection Manual

This project can create Guacamole VNC connections directly in the database so you do not have to use the web UI every time.

## What the Make target does

`make -f Makefile.full-docker add-connection` creates or updates the bundled Docker VNC connection.

`make -f Makefile.host add-connection` creates or updates a host/VM VNC connection.

Both grant `guacadmin` access to the connection.

Defaults:
- `CONNECTION_NAME=New VNC Connection`
- `CONNECTION_HOST=vnc-desktop`
- `CONNECTION_PORT=5901`
- full Docker: `CONNECTION_PASSWORD=$(VNC_PASSWORD)`
- host/VM: `CONNECTION_PASSWORD=$(HOST_VNC_PASSWORD)` if set, otherwise `$(VNC_PASSWORD)`
- `CONNECTION_PROTOCOL=vnc`

## Create a local VNC connection

Use this for the bundled desktop container:

```bash
make -f Makefile.full-docker add-connection \
  CONNECTION_NAME="Desktop Docker Local" \
  CONNECTION_HOST="vnc-desktop" \
  CONNECTION_PORT="5901" \
  CONNECTION_PASSWORD="$VNC_PASSWORD"
```

Then refresh Guacamole and open the new connection.

## Create a connection to a remote VM

Use this when the VNC server runs on another host or VM:

```bash
make -f Makefile.host add-connection \
  CONNECTION_NAME="VM Debian VNC" \
  CONNECTION_HOST="10.0.0.25" \
  CONNECTION_PORT="5901" \
  CONNECTION_PASSWORD="your_vnc_password"
```

If the remote VM is behind a firewall or security group, make sure the VNC port is reachable from the Guacamole container host.

## Change the target password

If you want the target to store a password different from the one in `.env`, pass a different value:

```bash
make -f Makefile.host add-connection \
  CONNECTION_NAME="EC2 VNC" \
  CONNECTION_HOST="ec2-xx-xx-xx-xx.compute.amazonaws.com" \
  CONNECTION_PORT="5901" \
  CONNECTION_PASSWORD="another_password"
```

## Parameters you can override

- `CONNECTION_NAME`
- `CONNECTION_HOST`
- `CONNECTION_PORT`
- `CONNECTION_PASSWORD`
- `CONNECTION_PROTOCOL`
- `CONNECTION_CLIPBOARD_ENCODING`
- `CONNECTION_COLOR_DEPTH`
- `GUAC_ADMIN_ENTITY_ID`

## Notes

- The target updates an existing connection with the same name instead of creating duplicates.
- The connection is automatically granted to `guacadmin`.
- If Guacamole does not show the new connection immediately, hard refresh the page.
