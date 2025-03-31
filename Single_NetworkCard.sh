#!/bin/bash

# variable
server_addr="192.168.1.1"

wlan_addr="192.168.1.108"

port_num="5201"

iperf3 -c "$server_addr" -B "$wlan_addr" -t 100 -u -b 300M -p "$port_num"
