from scapy.all import *

TYPE_TS = 0x1212
TYPE_IPV4 = 0x0800

class ts(Packet):
    name = "ts"
    fields_desc = [
        ShortField("pid", 0),
        ShortField("rec_num", 0),
        IntField("ts", 0),
        ByteField("flag", 0)
    ]


bind_layers(Ether, ts, type=TYPE_TS)
bind_layers(ts, IP, pid=TYPE_IPV4)

