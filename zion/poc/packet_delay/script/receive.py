#!/usr/bin/env python
import sys

from ts_header import ts
from scapy.all import sniff

def handle_pkt(pkt):
    if ts in pkt:
        print("got a packet")
        pkt.show2()
        sys.stdout.flush()


def main():
    iface = "veth2"
    print("sniffing on %s" % iface)
    sys.stdout.flush()
    sniff(iface = iface,
          prn = lambda x: handle_pkt(x))

if __name__ == '__main__':
    main()
