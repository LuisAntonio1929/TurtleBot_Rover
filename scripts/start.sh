#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

ROBOT_HOST="turtlebot3.local"
ZENOH_PORT="7447"

echo "========================================"
echo " TurtleBot Rover - Real Robot Mode"
echo "========================================"
echo
echo "Searching for ${ROBOT_HOST}..."

TURTLEBOT_IP=""
CONNECTION_VERIFIED="false"


# ---------------------------------------------------------
# WSL / Windows
# ---------------------------------------------------------

if command -v powershell.exe >/dev/null 2>&1; then

    RESULT="$(
        powershell.exe -NoProfile -Command '
            $t = Test-NetConnection `
                -ComputerName "turtlebot3.local" `
                -Port 7447 `
                -WarningAction SilentlyContinue

            if ($t.TcpTestSucceeded) {
                Write-Output $t.RemoteAddress.IPAddressToString
                exit 0
            } else {
                exit 1
            }
        ' 2>/dev/null | tr -d '\r' | tail -n 1
    )" || true

    if [ -n "$RESULT" ]; then
        TURTLEBOT_IP="$RESULT"
        CONNECTION_VERIFIED="true"
    fi


# ---------------------------------------------------------
# Native Linux
# ---------------------------------------------------------

elif command -v avahi-resolve-host-name >/dev/null 2>&1; then

    TURTLEBOT_IP="$(
        avahi-resolve-host-name -4 "$ROBOT_HOST" 2>/dev/null |
        awk '{print $2; exit}'
    )" || true

elif command -v getent >/dev/null 2>&1; then

    TURTLEBOT_IP="$(
        getent ahostsv4 "$ROBOT_HOST" 2>/dev/null |
        awk 'NR == 1 {print $1}'
    )" || true


# ---------------------------------------------------------
# macOS
# ---------------------------------------------------------

elif command -v dscacheutil >/dev/null 2>&1; then

    TURTLEBOT_IP="$(
        dscacheutil -q host -a name "$ROBOT_HOST" |
        awk '/ip_address:/ {print $2; exit}'
    )" || true

fi


# ---------------------------------------------------------
# Verify robot discovery
# ---------------------------------------------------------

if [ -z "$TURTLEBOT_IP" ]; then

    echo
    echo "ERROR: TurtleBot3 could not be found."
    echo
    echo "Check that:"
    echo "  - TurtleBot3 is powered on"
    echo "  - Laptop and TurtleBot3 are on the same LAN"
    echo "  - turtlebot3.local resolves from the host"
    echo "  - The network does not use client isolation"

    exit 1
fi


echo "TurtleBot3 found: ${TURTLEBOT_IP}"


# ---------------------------------------------------------
# Verify Zenoh connectivity
# ---------------------------------------------------------

# On WSL, PowerShell already verified TCP connectivity.
# On native Linux/macOS, verify using netcat when available.

if [ "$CONNECTION_VERIFIED" = "false" ] && command -v nc >/dev/null 2>&1; then

    if ! nc -z -w 3 "$TURTLEBOT_IP" "$ZENOH_PORT"; then

        echo
        echo "ERROR: ${TURTLEBOT_IP}:${ZENOH_PORT} is not reachable."

        exit 1
    fi

    CONNECTION_VERIFIED="true"
fi


if [ "$CONNECTION_VERIFIED" = "true" ]; then
    echo "Zenoh router reachable on port ${ZENOH_PORT}."
else
    echo "TurtleBot3 resolved. TCP connectivity will be verified by Docker."
fi


# ---------------------------------------------------------
# Save current TurtleBot IP
# ---------------------------------------------------------

if [ -f .env ]; then

    if grep -q '^TURTLEBOT_IP=' .env; then

        sed -i \
            "s/^TURTLEBOT_IP=.*/TURTLEBOT_IP=${TURTLEBOT_IP}/" \
            .env

    else

        printf '\nTURTLEBOT_IP=%s\n' "$TURTLEBOT_IP" >> .env

    fi

else

    printf 'TURTLEBOT_IP=%s\n' "$TURTLEBOT_IP" > .env

fi


echo "Docker endpoint: turtlebot3.local -> ${TURTLEBOT_IP}"
echo
echo "Starting Docker in REAL ROBOT mode..."


# ---------------------------------------------------------
# Start Docker in real-robot mode
# ---------------------------------------------------------

TB_RMW_IMPLEMENTATION="rmw_zenoh_cpp" \
TB_ZENOH_SESSION_CONFIG_URI="/config/zenoh/client.json5" \
docker compose up \
    -d \
    --force-recreate \
    --remove-orphans \
    ros2


echo
echo "Verifying Zenoh from ROS 2 container..."


# ---------------------------------------------------------
# Verify Docker -> TurtleBot
# ---------------------------------------------------------

if docker compose exec -T ros2 \
    nc -z -w 5 turtlebot3.local "$ZENOH_PORT"; then

    echo "Docker -> TurtleBot3 Zenoh connection OK."

else

    echo
    echo "ERROR: Docker cannot reach turtlebot3.local:${ZENOH_PORT}."

    exit 1
fi


echo
echo "========================================"
echo " TurtleBot Rover ready"
echo "========================================"
echo
echo "Mode  : REAL ROBOT"
echo "Robot : ${TURTLEBOT_IP}"
echo "Zenoh : turtlebot3.local:${ZENOH_PORT}"
echo
echo "Enter ROS 2 container with:"
echo
echo "  docker compose exec ros2 bash"
echo