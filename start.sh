#!/bin/bash
set -e
mkdir -p ~/.vnc
echo "${VNC_PASSWORD:?Set VNC_PASSWORD}" | tigervncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

cat > ~/.vnc/xstartup <<'EOF'
#!/bin/sh
unset SESSION_MANAGER DBUS_SESSION_BUS_ADDRESS
exec startxfce4
EOF
chmod +x ~/.vnc/xstartup

# clean stale locks from previous runs
tigervncserver -kill :1 >/dev/null 2>&1 || true
rm -f /tmp/.X1-lock /tmp/.X11-unix/X1

tigervncserver :1 -geometry "${RESOLUTION:-1600x900}" -depth 24 \
  -localhost yes -SecurityTypes VncAuth

exec websockify --web=/usr/share/novnc 6080 localhost:5901
