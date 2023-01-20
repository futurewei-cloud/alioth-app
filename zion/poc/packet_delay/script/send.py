#!/usr/bin/env python

from ts_header import ts
from scapy.all import IP, Ether, sendp

def main():
    pkt = Ether() / ts() / IP(src="2.2.2.2", dst="3.3.3.3")

    sendp(pkt, iface="veth251", verbose=False)


if __name__ == '__main__':
    main()
