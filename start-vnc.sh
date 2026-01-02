#!/usr/bin/env bash
set -euo pipefail

# Basic configuration with sensible defaults
VNC_USER="${VNC_USER:-vncuser}"
VNC_PASSWORD="${VNC_PASSWORD:-changeme}"
GEOMETRY="${GEOMETRY:-1920x1080}"
DEPTH="${DEPTH:-24}"
VNC_DISPLAY=":1"
VNC_PORT="${VNC_PORT:-5901}"
NOVNC_PORT="${NOVNC_PORT:-6901}"

create_user() {
  if ! id "${VNC_USER}" >/dev/null 2>&1; then
    useradd -m -s /bin/bash "${VNC_USER}"
  fi
}

configure_vnc_password() {
  sudo -u "${VNC_USER}" mkdir -p "/home/${VNC_USER}/.vnc"
  echo "${VNC_PASSWORD}" | vncpasswd -f | sudo -u "${VNC_USER}" tee "/home/${VNC_USER}/.vnc/passwd" >/dev/null
  chmod 600 "/home/${VNC_USER}/.vnc/passwd"
}

configure_xstartup() {
  local xstartup="/home/${VNC_USER}/.vnc/xstartup"
  if [ ! -f "${xstartup}" ]; then
    cat >"${xstartup}" <<'EOF'
#!/bin/sh
unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
startxfce4 &
EOF
    chmod +x "${xstartup}"
  fi
}

start_vnc() {
  sudo -u "${VNC_USER}" vncserver -kill "${VNC_DISPLAY}" >/dev/null 2>&1 || true
  sudo -u "${VNC_USER}" VNC_PORT="${VNC_PORT}" vncserver "${VNC_DISPLAY}" -geometry "${GEOMETRY}" -depth "${DEPTH}"
}

start_novnc() {
  websockify --web=/usr/share/novnc/ "0.0.0.0:${NOVNC_PORT}" "localhost:${VNC_PORT}" &
  NOVNC_PID=$!
}

stop_vnc() {
  sudo -u "${VNC_USER}" vncserver -kill "${VNC_DISPLAY}" >/dev/null 2>&1 || true
  if [ "${NOVNC_PID:-0}" -ne 0 ]; then
    kill "${NOVNC_PID}" >/dev/null 2>&1 || true
  fi
}

main() {
  trap stop_vnc EXIT
  create_user
  configure_vnc_password
  configure_xstartup
  start_vnc
  start_novnc

  local logfile="/home/${VNC_USER}/.vnc/${HOSTNAME}${VNC_DISPLAY}.log"
  echo "VNC ready on port ${VNC_PORT}, display ${VNC_DISPLAY}, user ${VNC_USER}"
  echo "noVNC ready on port ${NOVNC_PORT}"
  # Follow VNC server log for visibility
  sudo -u "${VNC_USER}" tail -F "${logfile}"
}

main "$@"
