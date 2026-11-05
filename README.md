# EU4M TurtleBot3 – Autonomous Lunar Rover

## Project Overview

This repository contains the ROS 2 software stack, configuration files, and development environment for a physical autonomous lunar rover based on the **TurtleBot3 Burger** platform.

The project is developed for the **VP774A Design and Development Project II** course at **Högskolan i Skövde (University of Skövde), Sweden**, during WiSe 2026.

The current architecture allows multiple development computers to communicate with the physical TurtleBot3 through ROS 2 using **Zenoh**, without requiring a fixed IP address for the robot.

The development environment supports two workflows:

- **Windows + WSL2 + Docker**
- **Native Linux / Dual Boot with ROS 2 Jazzy**

---

# System Architecture

The Raspberry Pi onboard the TurtleBot3 runs:

- ROS 2 Jazzy
- TurtleBot3 bringup
- OpenCR interface
- LiDAR driver
- `robot_state_publisher`
- Zenoh router
- mDNS/Avahi discovery as `turtlebot3.local`

The main communication architecture is:

```text
                   Local Wi-Fi Network
                         │
                         │
              ┌──────────┴──────────┐
              │                     │
              ▼                     ▼
       TurtleBot3 / Pi        Development PC
       ROS 2 Jazzy            ROS 2 Jazzy
              │                     │
       rmw_zenoh_cpp          rmw_zenoh_cpp
              │                     │
       Zenoh Router :7447 ◄─────────┘
              │
       OpenCR + LiDAR
```

The Zenoh router runs directly on the Raspberry Pi.

Development computers connect directly to:

```text
turtlebot3.local:7447
```

The Raspberry Pi receives its IP address dynamically through DHCP. A fixed robot IP is **not required**.

For example, the robot may change from:

```text
192.168.137.195
```

to:

```text
192.168.137.207
```

after a reboot without affecting the ROS 2 architecture.

---

# Hardware Specifications

- **Base Platform:** TurtleBot3 Burger
- **Actuators:** 2 × DYNAMIXEL XL430 motors
- **Embedded Controller:** OpenCR 1.0
- **Compute Node:** Raspberry Pi
- **LiDAR:** LDS series 2D 360° laser scanner
- **Camera Hardware:** Raspberry Pi Camera Module v2, Sony IMX219 8 MP sensor connected through CSI

The camera software integration is separate from the core ROS 2 communication stack and may use packages such as `camera_ros` or `v4l2_camera`.

---

# ROS 2 Topics

The physical TurtleBot currently provides the following main ROS 2 topics:

```text
/battery_state
/cmd_vel
/imu
/joint_states
/magnetic_field
/odom
/parameter_events
/robot_description
/rosout
/scan
/sensor_state
/tf
/tf_static
```

These topics can be accessed simultaneously by multiple development computers connected to the same network.

---

# Network Requirements

The TurtleBot3 and the development computer must be connected to the **same local network**.

The network must allow direct communication between connected devices.

Normal private Wi-Fi networks and personal hotspots normally work correctly.

Some university, guest, or public Wi-Fi networks may use **client isolation**, which prevents devices on the same network from communicating directly. In that case, Zenoh communication may not work even if both devices have Internet access.

The robot can be discovered through:

```text
turtlebot3.local
```

The Zenoh router listens on:

```text
TCP 7447
```

---

# Option A – Windows + WSL2 + Docker

## Requirements

Install:

- Windows 11
- WSL2
- Ubuntu under WSL
- Docker Desktop
- Docker Desktop WSL integration enabled

Verify Docker from WSL:

```bash
docker --version
docker compose version
```

---

## Clone the Repository

```bash
git clone https://github.com/LuisAntonio1929/TurtleBot_Rover.git
cd TurtleBot_Rover
```

If the repository is already installed:

```bash
git pull
```

---

## Build the Docker Image

A Docker build is required the first time:

```bash
docker compose build
```

A rebuild is normally required only when dependencies or the Dockerfile change.

For example, rebuild after changes to:

```text
docker/Dockerfile
```

or when new ROS/system packages are added.

To force a completely clean rebuild:

```bash
docker compose build --no-cache
```

Changes to scripts, RViz configuration, documentation, or files mounted through `ros2_ws` do **not** normally require rebuilding the Docker image.

---

## Start the TurtleBot Development Environment

Do **not** normally start the project using only:

```bash
docker compose up
```

Instead, use the project startup script:

```bash
./scripts/start.sh
```

The script automatically:

1. Searches for `turtlebot3.local`
2. Determines the robot's current IP address
3. Verifies that the Zenoh router is reachable on TCP port `7447`
4. Updates the local `.env` file
5. Maps `turtlebot3.local` inside Docker
6. Starts the ROS 2 container
7. Verifies Docker-to-TurtleBot communication

A successful startup should look similar to:

```text
========================================
 TurtleBot Rover
========================================

Searching for turtlebot3.local...
TurtleBot3 found: 192.168.x.x
Zenoh router reachable on port 7447.

Starting Docker...

Docker -> TurtleBot3 Zenoh connection OK.

========================================
 TurtleBot Rover ready
========================================
```

---

## Enter the ROS 2 Container

After `start.sh` completes successfully:

```bash
docker compose exec ros2 bash
```

The prompt should change to something similar to:

```text
[ROS2-Jazzy] /ros2_ws #
```

---

## Verify ROS 2 Communication

Inside Docker:

```bash
ros2 topic list --no-daemon
```

You should see topics such as:

```text
/scan
/odom
/imu
/tf
/tf_static
/robot_description
/cmd_vel
```

Test LiDAR data:

```bash
ros2 topic echo /scan --once
```

Test odometry:

```bash
ros2 topic echo /odom --once
```

---

## Run RViz2

Inside the container:

```bash
rviz2 -d /ros2_ws/config/rviz/turtlebot3.rviz
```

The shared RViz configuration includes visualization of:

- TurtleBot3 URDF
- RobotModel
- TF2 frames
- LiDAR `/scan`
- Odometry-related frames

Because `ros2_ws` is bind-mounted into Docker:

```text
./ros2_ws → /ros2_ws
```

changes to the RViz configuration do **not** require rebuilding the Docker image.

After a `git pull`, the updated `.rviz` file is immediately available inside the container.

---

## Stop Docker

To stop and remove the container:

```bash
docker compose down
```

To start the project again later:

```bash
./scripts/start.sh
```

---

# Option B – Native Linux / Dual Boot

Users running Ubuntu natively do **not** need Docker.

Recommended configuration:

- Ubuntu 24.04
- ROS 2 Jazzy

Using the same ROS 2 distribution as the TurtleBot is strongly recommended.

---

## Install Required Packages

```bash
sudo apt update

sudo apt install -y \
  ros-jazzy-desktop \
  ros-jazzy-rmw-zenoh-cpp \
  avahi-utils \
  libnss-mdns \
  netcat-openbsd
```

---

## Verify Robot Discovery

Make sure the Linux computer and TurtleBot3 are connected to the same Wi-Fi network.

Then run:

```bash
ping -c 1 turtlebot3.local
```

The current robot IP should be resolved automatically.

Verify the Zenoh router:

```bash
nc -vz turtlebot3.local 7447
```

Expected result:

```text
Connection to turtlebot3.local (...) 7447 port [tcp/*] succeeded!
```

---

## Configure Zenoh

Create the configuration directory:

```bash
mkdir -p ~/.config/zenoh
```

Create:

```bash
~/.config/zenoh/client.json5
```

with:

```json5
{
  mode: "client",
  connect: {
    endpoints: [
      "tcp/turtlebot3.local:7447"
    ]
  }
}
```

---

## Configure ROS 2

In the terminal:

```bash
source /opt/ros/jazzy/setup.bash

export ROS_DOMAIN_ID=30
export RMW_IMPLEMENTATION=rmw_zenoh_cpp
export ZENOH_SESSION_CONFIG_URI="$HOME/.config/zenoh/client.json5"
```

Verify communication:

```bash
ros2 topic list --no-daemon
```

The TurtleBot ROS 2 topics should now appear.

---

## Optional Permanent ROS 2 Configuration

The following lines can be added to:

```text
~/.bashrc
```

```bash
source /opt/ros/jazzy/setup.bash

export ROS_DOMAIN_ID=30
export RMW_IMPLEMENTATION=rmw_zenoh_cpp
export ZENOH_SESSION_CONFIG_URI="$HOME/.config/zenoh/client.json5"
```

Reload the terminal:

```bash
source ~/.bashrc
```

---

# RViz2 on Native Linux

Clone the repository:

```bash
git clone https://github.com/LuisAntonio1929/TurtleBot_Rover.git
cd TurtleBot_Rover
```

If already cloned:

```bash
git pull
```

From the repository root, run:

```bash
rviz2 -d "$PWD/ros2_ws/config/rviz/turtlebot3.rviz"
```

Do not use:

```bash
/ros2_ws/config/rviz/turtlebot3.rviz
```

on native Linux unless your repository is actually located at `/ros2_ws`.

That absolute path is primarily used inside the Docker container.

---

## TurtleBot3 Description Package

RViz uses `/robot_description`, `/tf`, and `/tf_static` from the physical robot.

The local computer should also have the TurtleBot3 description resources required to render the model.

Check:

```bash
ros2 pkg prefix turtlebot3_description
```

If the package is missing:

```bash
sudo apt update
sudo apt install ros-jazzy-turtlebot3-description
```

Then run RViz again.

---

# Multiple Computers

Multiple computers can connect to the same TurtleBot3 simultaneously.

For example:

```text
                     TurtleBot3
                  Raspberry Pi
               Zenoh Router :7447
                  /      |      \
                 /       |       \
                ▼        ▼        ▼
          Docker PC   Linux PC   Linux PC
```

Each development computer communicates directly with the Zenoh router on the Raspberry Pi.

The computers do not need to communicate through each other.

This configuration has been tested successfully with multiple computers accessing the same TurtleBot ROS 2 topics.

---

# Raspberry Pi Services

The Raspberry Pi automatically starts the required infrastructure.

Two systemd services are used:

```text
zenoh-router.service
turtlebot3-ros2.service
```

The startup sequence is:

```text
Raspberry Pi boot
       ↓
Network becomes available
       ↓
Zenoh Router starts
       ↓
TurtleBot3 ROS 2 bringup starts
       ↓
OpenCR + LiDAR + ROS 2 topics available
```

Therefore, normal users should **not need to SSH into the Raspberry Pi to start ROS 2 manually**.

---

# Updating the Repository

## Changes that normally do NOT require a Docker rebuild

Examples:

```text
README.md
scripts/*
ros2_ws/config/rviz/*
ros2_ws/config/zenoh/*
```

Usually:

```bash
git pull
./scripts/start.sh
```

is sufficient.

---

## Changes that DO require rebuilding Docker

Examples:

- Dockerfile changes
- New Ubuntu packages
- New ROS 2 packages installed through APT
- New system dependencies

Run:

```bash
docker compose build
```

or:

```bash
docker compose build --no-cache
```

when a clean rebuild is required.

---

# Common Troubleshooting

## `turtlebot3.local` cannot be found

Check:

```bash
ping turtlebot3.local
```

Make sure:

- TurtleBot3 is powered on
- Both devices are on the same network
- The network allows peer-to-peer communication
- mDNS is available

---

## Zenoh cannot be reached

Check:

```bash
nc -vz turtlebot3.local 7447
```

If this fails, verify network connectivity before troubleshooting ROS 2.

---

## Windows can reach the robot but Docker cannot

From the container:

```bash
docker compose exec -T ros2 getent hosts turtlebot3.local
```

Then:

```bash
docker compose exec -T ros2 nc -vz turtlebot3.local 7447
```

The hostname should resolve to the same IP discovered by `start.sh`.

---

## `nc` is missing inside Docker

Check:

```bash
docker compose exec -T ros2 which nc
```

If nothing is returned, the local Docker image may be outdated.

Rebuild it:

```bash
docker compose down
docker compose build --no-cache
./scripts/start.sh
```

---

## ROS 2 topics do not appear

Check the environment:

```bash
echo $RMW_IMPLEMENTATION
echo $ZENOH_SESSION_CONFIG_URI
echo $ROS_DOMAIN_ID
```

Expected values:

```text
rmw_zenoh_cpp
.../client.json5
30
```

Then:

```bash
ros2 topic list --no-daemon
```

---

# Project Workflow Summary

## Windows + WSL2 + Docker

```bash
git pull
./scripts/start.sh
docker compose exec ros2 bash
ros2 topic list
rviz2 -d /ros2_ws/config/rviz/turtlebot3.rviz
```

---

## Native Linux / Dual Boot

```bash
git pull

source /opt/ros/jazzy/setup.bash
export ROS_DOMAIN_ID=30
export RMW_IMPLEMENTATION=rmw_zenoh_cpp
export ZENOH_SESSION_CONFIG_URI="$HOME/.config/zenoh/client.json5"

ros2 topic list --no-daemon

rviz2 -d "$PWD/ros2_ws/config/rviz/turtlebot3.rviz"
```

---

# Contributors

- Agahan Yuldashev
- Al Faiz
- Luis Antonio
- Ulrich Jordan
- Ikram

---

# License

This project is released under the BSD License.
