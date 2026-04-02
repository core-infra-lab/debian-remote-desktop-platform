# Host and Container Files

This project uses Docker bind mounts to share files between the host and the containers. A bind mount means a real folder from the host appears inside the container at a specific path.

## Current mounts in this repo

From [docker-compose.yml](../docker-compose.yml):

- Host `./drive` -> container `/drive`
- Host `./record` -> container `/record`
- Host `./data` -> Postgres data directory
- Host `./data/vnc` -> container `/home/<user>/.vnc`

## What this means

If you create or edit a file on the host inside one of those folders, the same file will be visible in the container.

Examples:

- A file saved in `./drive` on the host is visible as `/drive` in the container.
- A recording written to `/record` in the container appears in `./record` on the host.
- VNC session files saved under `/home/guac/.vnc` in the container are stored in `./data/vnc` on the host.

## Where to put things

Use these folders for shared data:

- `drive/` for files you want to exchange with the container
- `record/` for Guacamole recordings
- `data/vnc/` for VNC session state
- `data/` for database persistence

Do not use random paths inside `/home/radandri` if you want the container to see the files. Only mounted folders are shared.

## Practical workflow

### Put a file in the container from the host

Create or copy the file inside the mounted folder on the host:

```bash
cp my-script.sh drive/
```

Then inside the container, it will be available as:

```bash
/drive/my-script.sh
```

### Get a file back to the host

If the container writes a file into `/record`, `/drive`, or `/home/guac/.vnc`, you can read it on the host in the matching folder.

## Permissions

If you get `Permission denied` while writing to a mounted folder, it is usually a host ownership problem.

Useful checks:

```bash
ls -ld drive record data data/vnc
```

If needed, fix ownership on the host:

```bash
sudo chown -R "$USER":"$USER" drive record data
```

Be careful with `data/` because it also contains the Postgres volume.

## For scripts

If you want the container to run a script automatically at startup:

- put the script in the repository
- copy it into the image in the Dockerfile, or
- mount it through a shared folder and call it from the container

For this project, `start-vnc.sh` is copied into the VNC image, so changes to that file require rebuilding the image.

## Summary

- Host folder -> container path via bind mount
- Only mounted folders are shared
- Use `drive/`, `record/`, and `data/vnc/` for exchange and persistence
- Rebuild the VNC image when changing `start-vnc.sh`
