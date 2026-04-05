#!/usr/bin/env bash
set -euo pipefail

# Optional: load overrides from .env if present.
if [[ -f .env ]]; then
  set -a
  # shellcheck disable=SC1091
  source .env
  set +a
fi

HOST_VNC_DISPLAY="${HOST_VNC_DISPLAY:-:1}"
HOST_VNC_GEOMETRY="${HOST_VNC_GEOMETRY:-1920x1080}"
HOST_VNC_DEPTH="${HOST_VNC_DEPTH:-24}"
HOST_VNC_PORT="${HOST_VNC_PORT:-5901}"
HOST_VNC_PASSWORD="${HOST_VNC_PASSWORD:-}"
HOST_VNC_USER="${HOST_VNC_USER:-${USER}}"

normalize_display() {
  if [[ "${HOST_VNC_DISPLAY}" != :* ]]; then
    HOST_VNC_DISPLAY=":${HOST_VNC_DISPLAY}"
  fi
}

resolve_user_home() {
  local home_dir
  home_dir="$(getent passwd "${HOST_VNC_USER}" | cut -d: -f6)"
  if [[ -z "${home_dir}" ]]; then
    echo "User ${HOST_VNC_USER} does not exist." >&2
    exit 1
  fi
  VNC_DIR="${home_dir}/.vnc"
  XSTARTUP_PATH="${VNC_DIR}/xstartup"
}

run_as_vnc_user() {
  sudo -u "${HOST_VNC_USER}" "$@"
}

usage() {
  cat <<'EOF'
Usage: ./start-vnc-host.sh <command>

Commands:
  setup     Install packages and create ~/.vnc/xstartup (+ optional password)
  start     Start host VNC server on HOST_VNC_DISPLAY
  stop      Stop host VNC server on HOST_VNC_DISPLAY
  restart   Restart host VNC server
  status    Show VNC sessions and listening port
  help      Show this help

Environment variables (optional):
  HOST_VNC_USER      (default: current user)
  HOST_VNC_DISPLAY   (default: :1)
  HOST_VNC_GEOMETRY  (default: 1920x1080)
  HOST_VNC_DEPTH     (default: 24)
  HOST_VNC_PORT      (default: 5901)
  HOST_VNC_PASSWORD  (optional; if set, writes ~/.vnc/passwd)
EOF
}

write_xstartup() {
  sudo mkdir -p "${VNC_DIR}"
  cat <<'EOF' | sudo tee "${XSTARTUP_PATH}" >/dev/null
#!/bin/bash
exec >>"$HOME/.vnc/xstartup.log" 2>&1

unset SESSION_MANAGER
unset DBUS_SESSION_BUS_ADDRESS
unset WAYLAND_DISPLAY
export XKL_XMODMAP_DISABLE=1
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=XFCE

if [ -z "$XDG_RUNTIME_DIR" ]; then
  export XDG_RUNTIME_DIR="/tmp/runtime-$USER"
  mkdir -p "$XDG_RUNTIME_DIR"
  chmod 700 "$XDG_RUNTIME_DIR"
fi

xrdb "$HOME/.Xresources"

if command -v dbus-launch >/dev/null 2>&1; then
  if command -v xfce4-session >/dev/null 2>&1; then
    dbus-launch --exit-with-session xfce4-session
  fi
fi

if command -v xfce4-session >/dev/null 2>&1; then
  xfce4-session
fi

exec xterm
EOF
  sudo chmod +x "${XSTARTUP_PATH}"
  sudo chown -R "${HOST_VNC_USER}:${HOST_VNC_USER}" "${VNC_DIR}"
}

configure_password() {
  if [[ -n "${HOST_VNC_PASSWORD}" ]]; then
    local passwd_hash
    passwd_hash="$(echo "${HOST_VNC_PASSWORD}" | run_as_vnc_user vncpasswd -f)"
    echo "${passwd_hash}" | sudo tee "${VNC_DIR}/passwd" >/dev/null
    sudo chmod 600 "${VNC_DIR}/passwd"
    sudo chown "${HOST_VNC_USER}:${HOST_VNC_USER}" "${VNC_DIR}/passwd"
    echo "VNC password written from HOST_VNC_PASSWORD."
  else
    echo "HOST_VNC_PASSWORD is empty. Run 'vncpasswd' manually if needed."
  fi
}

setup_host() {
  echo "Installing host VNC dependencies..."
  # Avoid debconf prompts (notably display manager selection) on fresh hosts.
  if command -v debconf-set-selections >/dev/null 2>&1; then
    printf 'lightdm shared/default-x-display-manager select lightdm\n' | sudo debconf-set-selections || true
  fi
  sudo DEBIAN_FRONTEND=noninteractive apt update -y
  sudo DEBIAN_FRONTEND=noninteractive apt install -y \
    tightvncserver xfce4 xfce4-goodies dbus-x11 x11-xserver-utils
  if ! id "${HOST_VNC_USER}" >/dev/null 2>&1; then
    sudo useradd -m -s /bin/bash "${HOST_VNC_USER}"
  fi
  write_xstartup
  configure_password
  echo "Host VNC setup complete for user ${HOST_VNC_USER}."
}

stop_vnc() {
  run_as_vnc_user vncserver -kill "${HOST_VNC_DISPLAY}" >/dev/null 2>&1 || true
  sudo pkill -u "${HOST_VNC_USER}" -f 'xfce4-session|xfwm4|xfdesktop|xfsettingsd|xfce4-panel|Thunar|wrapper-2.0|light-locker|nm-applet|xiccd|gvfsd' >/dev/null 2>&1 || true
  echo "Stopped VNC display ${HOST_VNC_DISPLAY} (if it was running)."
}

start_vnc() {
  stop_vnc
  sudo -u "${HOST_VNC_USER}" rm -f "${VNC_DIR}"/*.pid "${VNC_DIR}"/*.log >/dev/null 2>&1 || true
  sudo -u "${HOST_VNC_USER}" rm -rf "$(dirname "${VNC_DIR}")/.cache/sessions" >/dev/null 2>&1 || true
  sudo -u "${HOST_VNC_USER}" touch "$(dirname "${VNC_DIR}")/.Xresources"
  # TightVNC on Ubuntu 20.04 does not support TigerVNC flags like
  # `-SecurityTypes` or `-localhost no`.
  run_as_vnc_user vncserver "${HOST_VNC_DISPLAY}" -geometry "${HOST_VNC_GEOMETRY}" -depth "${HOST_VNC_DEPTH}"
  echo "Started VNC on display ${HOST_VNC_DISPLAY} for user ${HOST_VNC_USER}."
}

status_vnc() {
  echo "VNC sessions:"
  if run_as_vnc_user vncserver -help 2>&1 | grep -q -- '-list'; then
    run_as_vnc_user vncserver -list || true
  else
    # TightVNC on some distros does not support `vncserver -list`.
    ps -u "${HOST_VNC_USER}" -f | grep -E 'Xtightvnc|Xvnc|vncserver' | grep -v grep || true
  fi
  echo "Expected listening port: ${HOST_VNC_PORT}"
  ss -tlnp | grep ":${HOST_VNC_PORT}" || true
}

main() {
  normalize_display
  resolve_user_home
  local cmd="${1:-help}"
  case "${cmd}" in
    setup) setup_host ;;
    start) start_vnc ;;
    stop) stop_vnc ;;
    restart) stop_vnc; start_vnc ;;
    status) status_vnc ;;
    help|-h|--help) usage ;;
    *)
      echo "Unknown command: ${cmd}" >&2
      usage
      exit 1
      ;;
  esac
}

main "$@"



