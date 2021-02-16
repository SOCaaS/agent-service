#!/bin/bash
tshark -i eth0 -T ek > /tshark/packets.json
