#!/bin/bash

# variable
server_addr="192.168.1.1"

wlan_1_addr="192.168.1.154"
wlan_2_addr="192.168.1.180"
wlan_3_addr="192.168.1.102"
wlan_4_addr="192.168.1.101"
wlan_5_addr="192.168.1.156"
wlan_6_addr="192.168.1.108"

port_1_addr="1001"
port_2_addr="1002"
port_3_addr="1003"
port_4_addr="1004"
port_5_addr="1005"
port_6_addr="1006"

iperf3 -c "$server_addr" -B "$wlan_1_addr" -t 100 -u -b 300M -p "1001"
iperf3 -c "$server_addr" -B "$wlan_2_addr" -t 100 -u -b 300M -p "1002"
iperf3 -c "$server_addr" -B "$wlan_3_addr" -t 100 -u -b 300M -p "1003"
iperf3 -c "$server_addr" -B "$wlan_4_addr" -t 100 -u -b 300M -p "1004"
iperf3 -c "$server_addr" -B "$wlan_5_addr" -t 100 -u -b 300M -p "1005"
iperf3 -c "$server_addr" -B "$wlan_6_addr" -t 100 -u -b 300M -p "1006"

