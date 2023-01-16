# Prototype of Packet Delay Using Tofino

This application can delay a packet for an arbitrary period of time (e.g, 100ms in our program). We achieve this by recirculating the packet repeatedly while comparing the current timestamp with the initial timestamp in every recirculation. 