#include <core.p4>
#if __TARGET_TOFINO__ == 3
#include <t3na.p4>
#elif __TARGET_TOFINO__ == 2
#include <t2na.p4>
#else
#include <tna.p4>
#endif

const bit<16> TYPE_TS = 0x1212;
const bit<16> TYPE_IPV4 = 0x800;
const PortId_t rec_port = 68;       // recirculation port
const bit<32> latency = 100000000;   // 100000000 nanoseconds - 100ms

#include "common/headers.p4"
#include "common/util.p4"

header ts_h {
    bit<16> proto_id;
    bit<16> rec_num; // switch needs to recirculate the packet rec_num times
    bit<32> ts; // record the initial timestamp
    bit<8>  flag; // when the total recirculation time exceeds latency, flag=1
}

struct headers {
    ethernet_h   ethernet;
    ts_h         timestamp;
    ipv4_h       ipv4;
}

struct metadata_t {
    bit<32>  ts_diff;
}

// ---------------------------------------------------------------------------
// Ingress parser
// ---------------------------------------------------------------------------
parser SwitchIngressParser(
        packet_in pkt,
        out headers hdr,
        out metadata_t ig_md,
        out ingress_intrinsic_metadata_t ig_intr_md) {

    TofinoIngressParser() tofino_parser;

    state start {
        tofino_parser.apply(pkt, ig_intr_md);
        transition parse_ethernet;
    }

    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select (hdr.ethernet.ether_type) {
            TYPE_TS : parse_ts;
            TYPE_IPV4 : parse_ipv4;
            default : reject;
        }
    }

    state parse_ts {
        pkt.extract(hdr.timestamp);
        transition select (hdr.timestamp.proto_id) {
            TYPE_IPV4 : parse_ipv4;
            default : reject;
        }
    }

    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }
}

// ---------------------------------------------------------------------------
// Ingress Deparser
// ---------------------------------------------------------------------------
control SwitchIngressDeparser(
        packet_out pkt,
        inout headers hdr,
        in metadata_t ig_md,
        in ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md) {

    apply {
        pkt.emit(hdr);
    }
}

control SwitchIngress(
        inout headers hdr,
        inout metadata_t ig_md,
        in ingress_intrinsic_metadata_t ig_intr_md,
        in ingress_intrinsic_metadata_from_parser_t ig_intr_prsr_md,
        inout ingress_intrinsic_metadata_for_deparser_t ig_intr_dprsr_md,
        inout ingress_intrinsic_metadata_for_tm_t ig_intr_tm_md) {

    // Register to validate the latency value 
    Register <bit<32>, _> (32w1)  tscal;

    RegisterAction<bit<32>, bit<1>, bit<8>>(tscal) tscal_action = {
        void apply(inout bit<32> value, out bit<8> readvalue) {
            value = 0;
            if (ig_md.ts_diff > latency){
                readvalue = 1;
            }
            else {
                readvalue = 0;
            }
        }
    };

    // Calculate the difference between the initial timestamp and the current timestamp
    action comp_diff() {
        ig_md.ts_diff = ig_intr_md.ingress_mac_tstamp[31:0] - hdr.timestamp.ts;
    }

    action send(PortId_t port) {
        ig_intr_tm_md.ucast_egress_port = port;
    }

    // Recirculate the packet to the recirculation port
    // Decrease the recirculation number
    action recirculate(){
        ig_intr_tm_md.ucast_egress_port = rec_port;
        hdr.timestamp.rec_num = hdr.timestamp.rec_num + 1;      
    }

    table flag_table {
        key = {
            hdr.timestamp.flag : exact;
        }
        actions = {
            send;
            recirculate;
        }
        default_action = recirculate();
        size = 1;
    }

    apply {
        if (hdr.timestamp.rec_num == 0) {
            hdr.timestamp.ts = ig_intr_md.ingress_mac_tstamp[31:0];
        }
        ig_md.ts_diff = 0;
        comp_diff();
        hdr.timestamp.flag = tscal_action.execute(1);

        flag_table.apply();        

        // No need for egress processing, skip it and use empty controls for egress.
        ig_intr_tm_md.bypass_egress = 1w1;
    }

}

Pipeline(SwitchIngressParser(),
         SwitchIngress(),
         SwitchIngressDeparser(),
         EmptyEgressParser(),
         EmptyEgress(),
         EmptyEgressDeparser()) pipe;

Switch(pipe) main;