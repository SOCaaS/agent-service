#!/bin/bash
tshark -i {{ TSHARK_INTERFACE }} -T ek > /tshark/packets.json
