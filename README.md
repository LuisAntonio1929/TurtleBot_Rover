# EU4M TurtleBot3 – Autonomous Lunar Rover

## Project Overview

This repository contains the ROS 2 software stack, configuration files, simulation environment, and development tools for an autonomous rover based on the **TurtleBot3 Burger** platform.

The project is developed for the **VP774A Design and Development Project II** course at **Högskolan i Skövde (University of Skövde), Sweden**, during WiSe 2026.

The current system supports two development modes using the same ROS 2 workspace and Docker image:

- **Simulation mode** using Gazebo and ROS 2 locally.
- **Real robot mode** using a physical TurtleBot3 connected through Zenoh.

The objective is to develop and validate the autonomy software in simulation first and later deploy the same ROS interfaces and algorithms on the physical robot.

---

# Project Scenario

The rover will operate in a maze containing dynamic gates.

The project is divided into two main phases.

### Phase 1 – Mapping

The TurtleBot3 explores the maze while all gates are open.

The robot must generate a map of the environment using its LiDAR and odometry.

Planned components include:

- Gazebo simulation
- TurtleBot3 Burger
- LiDAR
- SLAM Toolbox
- ROS 2 TF
- Odometry
- Map generation and storage

### Phase 2 – Maze Navigation

The robot must use the previously generated map to reach the goal as quickly as possible.

During this phase, gates may close and block previously available corridors.

The navigation system will therefore need to:

- Localize the robot in the existing map.
- Plan a route toward the goal.
- Detect newly blocked corridors.
- Replan when gates close.
- Avoid static and dynamic obstacles.
- Prevent the robot from entering or remaining underneath a closing gate.
- Minimize the total time required to reach the goal.

Planned components include:

- Nav2
- Dynamic costmaps
- Obstacle detection
- Gate state management
- Route replanning
- Collision monitoring
- Mission management

---

# System Architecture

The physical TurtleBot3 runs ROS 2 Jazzy directly on its Raspberry Pi.

The Raspberry Pi also hosts the Zenoh router used by remote development computers.

```text
                    Local Wi-Fi Network
                           │
             ┌─────────────┴─────────────┐
             │                           │
             ▼                           ▼
      TurtleBot3 / Pi             Development PC
       ROS 2 Jazzy                 ROS 2 Jazzy
             │                           │
      rmw_zenoh_cpp                rmw_zenoh_cpp
             │                           │
      Zenoh Router :7447  ◄──────────────┘
             │
      OpenCR + LiDAR
```

The TurtleBot is advertised through mDNS as:

```text
turtlebot3.local
```

Therefore, the robot does **not** require a fixed IP address.

The Raspberry Pi may receive a different address after reboot and development computers can still discover it automatically.

---

# Hardware

Current hardware includes:

- **Base Platform:** TurtleBot3 Burger
- **Actuators:** 2 × DYNAMIXEL XL430 motors
- **Embedded Controller:** OpenCR 1.0
- **Compute Node:** Raspberry Pi
- **Perception:** 2D 360° LDS LiDAR
- **Camera:** Raspberry Pi Camera Module v2 with Sony IMX219 8 MP sensor

Camera integration is separate from the current LiDAR/navigation stack and may later use packages such as `camera_ros` or `v4l2_camera`.

---

# ROS 2 Topics

The physical TurtleBot currently provides the following main topics:

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

The same main interfaces will also be used during simulation whenever possible.

This allows higher-level software to remain independent of whether the data originates from Gazebo or the real robot.

```text
Simulation                    Real Robot
----------                    ----------
/scan          <----------->  /scan
/odom          <----------->  /odom
/tf            <----------->  /tf
/cmd_vel       <----------->  /cmd_vel
```

---

# Docker Environment

The Docker image provides the ROS 2 Jazzy development environment, including tools for:

- RViz2
- Gazebo
- TurtleBot3
- SLAM Toolbox
- Nav2
- Behavior Trees
- MoveIt 2
- ROS-Gazebo integration

The same Docker image is used for both simulation and real-robot development.

The runtime mode is selected through environment variables defined by `compose.yaml`.

---

# Repository Structure

The main project structure is:

```text
TurtleBot_Rover/
├── compose.yaml
├── docker/
│   └── Dockerfile
├── scripts/
│   └── start.sh
├── ros2_ws/
│   ├── config/
│   │   ├── rviz/
│   │   └── zenoh/
│   └── src/
└── README.md
```

The ROS 2 workspace is mounted inside Docker as:

```text
./ros2_ws -> /ros2_ws
```

Therefore, files inside `ros2_ws` remain stored in the repository even if the container is deleted or recreated.

---

# Windows + WSL2 + Docker

## Requirements

Install:

- Windows 11
- WSL2
- Ubuntu under WSL
- Docker Desktop
- Docker Desktop WSL integration enabled

Verify from WSL:

```bash
docker --version
docker compose version
```

---

# Clone the Repository

```bash
git clone https://github.com/LuisAntonio1929/TurtleBot_Rover.git
cd TurtleBot_Rover
```

If already cloned:

```bash
git pull
```

---

# Build the Docker Image

A build is required the first time:

```bash
docker compose build
```

A rebuild is normally required only when:

- `docker/Dockerfile` changes.
- New Ubuntu packages are added.
- New ROS 2 packages are added through APT.
- System-level dependencies change.

A clean rebuild can be performed with:

```bash
docker compose build --no-cache
```

Changes to source files, scripts, RViz configurations, or files mounted through `ros2_ws` normally do **not** require rebuilding the image.

---

# Simulation Mode

Simulation is the default Docker mode.

It uses:

```text
RMW_IMPLEMENTATION=rmw_fastrtps_cpp
TURTLEBOT3_MODEL=burger
ZENOH_SESSION_CONFIG_URI=
```

The TurtleBot3 model is configured automatically through `compose.yaml`.

There is no need to manually run:

```bash
export TURTLEBOT3_MODEL=burger
```

## Start Simulation Mode

From WSL, in the repository root:

```bash
docker compose up -d --force-recreate ros2
```

Enter the container:

```bash
docker compose exec ros2 bash
```

Verify the runtime mode:

```bash
echo $RMW_IMPLEMENTATION
echo $TURTLEBOT3_MODEL
echo $ZENOH_SESSION_CONFIG_URI
```

Expected result:

```text
rmw_fastrtps_cpp
burger

```

The Zenoh configuration should be empty in simulation mode.

---

# Start the Standard TurtleBot3 Simulation

Inside the container:

```bash
ros2 launch turtlebot3_gazebo turtlebot3_world.launch.py
```

In another container terminal, teleoperation can be started with:

```bash
ros2 run turtlebot3_teleop teleop_keyboard
```

Verify ROS 2 topics:

```bash
ros2 topic list
```

Typical simulated interfaces should include:

```text
/cmd_vel
/odom
/scan
/tf
/tf_static
/joint_states
```

---

# Real Robot Mode

The real TurtleBot uses **Zenoh** instead of relying on ROS 2 DDS multicast across WSL, Docker, and the local network.

The Zenoh router runs directly on the Raspberry Pi.

Real robot mode uses:

```text
RMW_IMPLEMENTATION=rmw_zenoh_cpp
ZENOH_SESSION_CONFIG_URI=/config/zenoh/client.json5
TURTLEBOT3_MODEL=burger
```

Do not start real-robot mode using a plain `docker compose up`.

Use:

```bash
./scripts/start.sh
```

The script automatically:

1. Searches for `turtlebot3.local`.
2. Determines the current TurtleBot IP address.
3. Verifies the Zenoh router on TCP port `7447`.
4. Updates the local `.env` file.
5. Configures `turtlebot3.local` inside Docker.
6. Starts the container using `rmw_zenoh_cpp`.
7. Verifies Docker-to-TurtleBot connectivity.

A successful startup should look similar to:

```text
========================================
 TurtleBot Rover - Real Robot Mode
========================================

Searching for turtlebot3.local...
TurtleBot3 found: 192.168.x.x
Zenoh router reachable on port 7447.

Starting Docker in REAL ROBOT mode...

Docker -> TurtleBot3 Zenoh connection OK.

========================================
 TurtleBot Rover ready
========================================
```

Enter the container:

```bash
docker compose exec ros2 bash
```

Verify:

```bash
echo $RMW_IMPLEMENTATION
```

Expected:

```text
rmw_zenoh_cpp
```

Then:

```bash
ros2 topic list --no-daemon
```

The physical TurtleBot topics should appear.

---

# Switching Between Simulation and Real Robot

No Docker rebuild is required when changing modes.

## Real Robot → Simulation

Run:

```bash
docker compose up -d --force-recreate ros2
```

The container is recreated using:

```text
rmw_fastrtps_cpp
```

## Simulation → Real Robot

Run:

```bash
./scripts/start.sh
```

The same container image is recreated using:

```text
rmw_zenoh_cpp
```

The architecture is therefore:

```text
                     SAME DOCKER IMAGE
                            │
                     SAME compose.yaml
                            │
                       SAME ros2_ws
                            │
              ┌─────────────┴─────────────┐
              │                           │
         SIMULATION                  REAL ROBOT
              │                           │
 docker compose up             ./scripts/start.sh
              │                           │
 rmw_fastrtps_cpp                 rmw_zenoh_cpp
              │                           │
           Gazebo                  turtlebot3.local
              │                           │
      simulated topics              real topics
              └─────────────┬─────────────┘
                            │
                    Project Software
```

---

# RViz2

A shared RViz configuration is stored at:

```text
ros2_ws/config/rviz/turtlebot3.rviz
```

## Docker

Inside the container:

```bash
rviz2 -d /ros2_ws/config/rviz/turtlebot3.rviz
```

The configuration includes visualization of:

- TurtleBot3 URDF
- `/robot_description`
- TF2
- LiDAR `/scan`
- Odometry-related frames

Because `ros2_ws` is bind-mounted into Docker, changes to the `.rviz` file do **not** require rebuilding the Docker image.

---

# Native Linux / Dual Boot

Users running Ubuntu natively do not need Docker to communicate with the real TurtleBot.

Recommended environment:

- Ubuntu 24.04
- ROS 2 Jazzy

Install:

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

## Discover the TurtleBot

The computer and TurtleBot must be connected to the same local network.

Run:

```bash
ping -c 1 turtlebot3.local
```

Verify Zenoh:

```bash
nc -vz turtlebot3.local 7447
```

Expected:

```text
Connection to turtlebot3.local (...) 7447 port [tcp/*] succeeded!
```

---

## Configure Zenoh

Create:

```bash
mkdir -p ~/.config/zenoh
```

Then:

```bash
cat > ~/.config/zenoh/client.json5 <<'EOF'
{
  mode: "client",
  connect: {
    endpoints: [
      "tcp/turtlebot3.local:7447"
    ]
  }
}
EOF
```

Configure the ROS 2 terminal:

```bash
source /opt/ros/jazzy/setup.bash

export ROS_DOMAIN_ID=30
export RMW_IMPLEMENTATION=rmw_zenoh_cpp
export ZENOH_SESSION_CONFIG_URI="$HOME/.config/zenoh/client.json5"
```

Verify:

```bash
ros2 topic list --no-daemon
```

---

# RViz2 on Native Linux

Clone or update the repository:

```bash
git clone https://github.com/LuisAntonio1929/TurtleBot_Rover.git
cd TurtleBot_Rover
```

or:

```bash
git pull
```

From the repository root:

```bash
rviz2 -d "$PWD/ros2_ws/config/rviz/turtlebot3.rviz"
```

The local system should also contain the TurtleBot3 description package:

```bash
ros2 pkg prefix turtlebot3_description
```

If missing:

```bash
sudo apt install ros-jazzy-turtlebot3-description
```

---

# Multiple Computers

Multiple development computers can connect to the same physical TurtleBot simultaneously.

```text
                       TurtleBot3
                    Raspberry Pi
                 Zenoh Router :7447
                    /      |      \
                   /       |       \
                  ▼        ▼        ▼
            Docker PC   Linux PC   Linux PC
```

Each computer communicates directly with the Zenoh router running on the Raspberry Pi.

This configuration has been successfully tested with multiple computers simultaneously accessing the TurtleBot ROS 2 topics.

---

# Network Requirements

The development computer and TurtleBot must be connected to a network that permits direct communication between clients.

Private Wi-Fi networks and personal hotspots normally work correctly.

Some university, guest, or public Wi-Fi networks may use **client isolation**, which can prevent peer-to-peer communication even if both devices have Internet access.

The robot is discovered using:

```text
turtlebot3.local
```

and Zenoh listens on:

```text
TCP 7447
```

---

# Raspberry Pi Startup

The Raspberry Pi automatically starts the required real-robot services.

The main systemd services are:

```text
zenoh-router.service
turtlebot3-ros2.service
```

The startup process is:

```text
Raspberry Pi boot
       ↓
Network available
       ↓
Zenoh Router starts
       ↓
TurtleBot3 ROS 2 bringup starts
       ↓
OpenCR + LiDAR + ROS 2 topics available
```

Under normal operation, users do not need to SSH into the Raspberry Pi to start ROS manually.

---

# SSH Access to the TurtleBot

When needed:

```bash
ssh ubuntu@turtlebot3.local
```

The robot IP does not need to be known manually.

---

# Updating the Repository

Always update the repository before starting development:

```bash
git pull
```

## Changes that normally do NOT require a Docker rebuild

Examples:

```text
README.md
scripts/*
ros2_ws/config/*
ros2_ws/src/*
```

Configuration changes and source files mounted through `/ros2_ws` are immediately available to the container.

ROS packages inside `ros2_ws/src` may still require:

```bash
cd /ros2_ws
colcon build --symlink-install
source install/setup.bash
```

but this is different from rebuilding the Docker image.

## Changes that DO require a Docker rebuild

Examples:

- `docker/Dockerfile`
- New system packages
- New ROS packages installed through APT
- New system-level dependencies

Run:

```bash
docker compose build
```

If a local Docker image behaves inconsistently after an update:

```bash
docker compose down
docker compose build --no-cache
```

Then start the desired runtime mode again.

---

# Common Troubleshooting

## `turtlebot3.local` cannot be resolved

Check:

```bash
ping turtlebot3.local
```

Verify:

- TurtleBot3 is powered on.
- Both devices are on the same network.
- The network allows peer-to-peer communication.
- mDNS is available.

---

## Zenoh cannot be reached

Check:

```bash
nc -vz turtlebot3.local 7447
```

If this fails, troubleshoot the network before ROS 2.

---

## Windows can reach the robot but Docker cannot

Run:

```bash
docker compose exec -T ros2 getent hosts turtlebot3.local
```

and:

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

If it is missing, rebuild the image:

```bash
docker compose down
docker compose build --no-cache
```

---

## ROS 2 topics do not appear in real robot mode

Check:

```bash
echo $RMW_IMPLEMENTATION
echo $ZENOH_SESSION_CONFIG_URI
echo $ROS_DOMAIN_ID
```

Expected:

```text
rmw_zenoh_cpp
/config/zenoh/client.json5
30
```

Then:

```bash
ros2 topic list --no-daemon
```

---

# Development Workflow Summary

## Simulation

```bash
git pull

docker compose up -d --force-recreate ros2
docker compose exec ros2 bash

ros2 launch turtlebot3_gazebo turtlebot3_world.launch.py
```

## Real Robot with Docker

```bash
git pull

./scripts/start.sh
docker compose exec ros2 bash

ros2 topic list --no-daemon
rviz2 -d /ros2_ws/config/rviz/turtlebot3.rviz
```

## Real Robot with Native Linux

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

# Current Development Focus

The communication infrastructure between the TurtleBot3 and development computers is operational.

The next development stage focuses on simulation and autonomy:

1. Create the custom maze simulation environment.
2. Validate TurtleBot3 sensors and motion inside the maze.
3. Implement Phase 1 mapping using SLAM Toolbox.
4. Save and reuse the generated map.
5. Implement Phase 2 localization and navigation using Nav2.
6. Add dynamic gates.
7. Detect and react to closing gates.
8. Replan routes dynamically.
9. Optimize the route to minimize completion time.
10. Transfer and tune the final solution on the physical TurtleBot3.

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