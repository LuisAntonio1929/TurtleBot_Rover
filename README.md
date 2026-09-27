# EU4MTurtleBoT3 - Autonomous Lunar Rover

## Project Overview
This repository contains the ROS 2 software stack and configuration files for a physical autonomous lunar rover based on the TurtleBot3 Burger platform. This work is developed for the **VP774A Design and Development Project II** course at the Högskolan i Skövde (HIS)-University of Skövde, Sweden, in WiSe 2026.

## Hardware Specifications
* **Base Platform:** TurtleBot3 Burger (Waffle-Plates)
* **Actuators:** 2x DYNAMIXEL XL430 motors
* **Embedded Controller:** OpenCR1.0
* **Compute Node:** Raspberry Pi
* **Perception:** Laser Distance Sensor LDS-02 Version, a 2D laser scanner capable of sensing 360 degrees that collects a set of data around the robot to use for SLAM (Simultaneous Localization and Mapping) and Navigation. (Effective October 2025, this LDS Sensor has been changed to the LDS-03 Version)
* **Raspberry Pi Camera Module v2:** Sony IMX219 8-megapixel sensor, connected via its 15cm ribbon cable directly into the CSI port on the Raspberry Pi. Either the camera_ros or v4l2_camera package can be used.

## Docker Setup

This project uses Docker to provide the complete ROS 2 Jazzy environment with RViz2, Gazebo, TurtleBot3, SLAM Toolbox, Nav2, Behavior Trees, and MoveIt 2.

### Requirements

- Docker Desktop
- WSL2 with Ubuntu
- Docker Desktop WSL integration enabled for Ubuntu

### Build the environment

From the repository root:

```bash
docker compose build ros2
```

### Start the container

```bash
docker compose up -d ros2
```

Check that it is running:

```bash
docker compose ps
```

### Enter the ROS 2 container

```bash
docker compose exec ros2 bash
```

or:

```bash
docker exec -it turtlebot_rover_ros2 bash
```

The ROS 2 workspace is mounted as:

```text
./ros2_ws → /ros2_ws
```

Therefore, the source code remains stored in the repository even if the container is rebuilt or removed.

### Stop and restart

Stop the container:

```bash
docker compose stop ros2
```

Start it again:

```bash
docker compose start ros2
```

To remove and recreate the container:

```bash
docker compose down
docker compose up -d ros2
```

## Contributors
* **Contributors:** Agahan Yuldashev, Al Faiz, Luis Antonio, Ulrich Jordan, Ikram

## License
This project is released under the BSD License.
