#!/usr/bin/env python3

import socket
import struct
import json
import threading

import rclpy
from rclpy.node import Node
from sensor_msgs.msg import LaserScan


HOST = '0.0.0.0'
PORT = 8765


def recv_exact(sock, n):
    data = b''

    while len(data) < n:
        chunk = sock.recv(n - len(data))

        if not chunk:
            return None

        data += chunk

    return data


class ScanReceiver(Node):

    def __init__(self):
        super().__init__('turtlebot_scan_receiver')

        self.publisher = self.create_publisher(
            LaserScan,
            '/scan',
            10
        )

        self.server_thread = threading.Thread(
            target=self.tcp_server,
            daemon=True
        )

        self.server_thread.start()

    def tcp_server(self):

        server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)

        server.bind((HOST, PORT))
        server.listen(1)

        self.get_logger().info(
            'Esperando TurtleBot en puerto 8765...'
        )

        while rclpy.ok():

            conn, addr = server.accept()

            self.get_logger().info(
                f'TurtleBot conectado desde {addr}'
            )

            try:

                while rclpy.ok():

                    header = recv_exact(conn, 4)

                    if header is None:
                        break

                    message_size = struct.unpack('!I', header)[0]

                    payload = recv_exact(conn, message_size)

                    if payload is None:
                        break

                    data = json.loads(payload.decode('utf-8'))

                    if data.get('topic') != '/scan':
                        continue

                    msg = LaserScan()

                    msg.header.stamp.sec = data['stamp_sec']
                    msg.header.stamp.nanosec = data['stamp_nsec']
                    msg.header.frame_id = data['frame_id']

                    msg.angle_min = data['angle_min']
                    msg.angle_max = data['angle_max']
                    msg.angle_increment = data['angle_increment']

                    msg.time_increment = data['time_increment']
                    msg.scan_time = data['scan_time']

                    msg.range_min = data['range_min']
                    msg.range_max = data['range_max']

                    msg.ranges = data['ranges']
                    msg.intensities = data['intensities']

                    self.publisher.publish(msg)

            except Exception as e:

                self.get_logger().error(
                    f'Error de conexión: {e}'
                )

            finally:

                conn.close()

                self.get_logger().info(
                    'TurtleBot desconectado. Esperando reconexión...'
                )


def main():

    rclpy.init()

    node = ScanReceiver()

    try:
        rclpy.spin(node)

    except KeyboardInterrupt:
        pass

    node.destroy_node()
    rclpy.shutdown()


if __name__ == '__main__':
    main()
