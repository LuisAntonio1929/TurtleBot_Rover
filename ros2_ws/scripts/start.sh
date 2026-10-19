#!/usr/bin/env bash
set -euo pipefail

ROBOT_HOST="turtlebot3.local"
ZENOH_PORT="7447"

echo "Searching for TurtleBot3..."

if command -v powershell.exe >/dev/null 2>&1; then

    # WSL / Windows
    TURTLEBOT_IP="$(
        powershell.exe -NoProfile -Command \
        '$t = Test-NetConnection -ComputerName "turtlebot3.local" -Port 7447 -WarningAction SilentlyContinue; if ($t.TcpTestSucceeded) { $t.RemoteAddress.IPAddressToString } else { exit 1 }' \
        | tr -d '\r'
    )"

else

    # Native Linux/macOS
    if command -v getent >/dev/null 2>&1; then
        TURTLEBOT_IP="$(
            getent ahostsv4 "$ROBOT_HOST" |
            awk 'NR==1 {print $1}'
        )"
    elif command -v dscacheutil >/dev/null 2>&1; then
        TURTLEBOT_IP="$(
            dscacheutil -q host -a name "$ROBOT_HOST" |
            awk '/ip_address:/ {print $2; exit}'
        )"
    else
        echo "Unable to resolve ${ROBOT_HOST}."
        exit 1
    fi
fi

if [ -z "${TURTLEBOT_IP:-}" ]; then
    echo "TurtleBot3 was not found."
    exit 1
fi

echo "TurtleBot3 found at: ${TURTLEBOT_IP}"

if ! nc -z -w 3 "$TURTLEBOT_IP" "$ZENOH_PORT"; then
    echo "TurtleBot3 found, but Zenoh port ${ZENOH_PORT} is unreachable."
    exit 1
fi

echo "Zenoh router reachable."

export TURTLEBOT_IP

docker compose up -d

echo
echo "TurtleBot Rover is ready."
echo "Robot: ${TURTLEBOT_IP}:${ZENOH_PORT}"
echo
echo "Enter ROS 2 container with:"
echo "  docker compose exec ros2 bash"
