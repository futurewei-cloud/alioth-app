# Prototype of packet drops in P4 w/ possibility
## Introduction
In some scenarios(fault injection eg.), we may want the switch to drop parts of the packets. Here is a simple example of packet drop. This P4 source code realizes the basic l2-forward,l3-routing(based IPV4) and ACL. In the end, we can set a packet drop rate, our switch will randomly drop some packets refer to the packet drop rate. Here are some implementation details.
## l2-forward
l2-forward is a basic function of switch. We have met basic_forward.P4 many times, so we dont introduce the details.<br>
One tips:
if the dstMacAddr of the packet doesn't match the macAddr of the switch port, It means this packet should be forwarded rather routed. 
## l3-route
we use three tables to implement l3-route.ipv4-host(exact match),ipv4-lpm(lpm match),next-hop. we will get a next-hop id after we use the dstIP to match the ipv4-host or the ipv4-lpm table, Then we match the nextHop id,we will get the new DstMacAddr,the EgressPort. that's all. 
## ACL
this is the simplest ACL.that's not our main goal in this exercise, so we ingore it,But we must know that some packet may be droped because of ACL rules.
## packet drop
this is our main goal in this exercise.First of all, we assume here are 1000 packets will go into our switch, we want to drop 30%, How can we achieve that? Here we use a P4 extern--**Random**.<br>
We are used to using the percentage to express the packet drop rate, but using Random to produce random value can only specify bit numbers. Such as 

```
Random<bit<5>> rnd;
bit<5> r=rnd.get();
```
the value of r is between 0 and 31 beacuse we specify 5 bits. Once we specify the drop rate 30%, which means the packet will be droped if the r is less than 32 * 30%. that's a float and it's hard to calculate. So we suggest to specify the length of bits 10; because 1024 is close to 1000. once we specify the drop rate 65.5%,which means the packet will be droped if the r is less than 1000 * 65.5%=655, that's a int number. Just as it happens, its precision is 0.1.  <br>
after we get the random value r. we use a packet_drop table, the key of the table is r, the match type is range. we set a start value(Fixed to 0),an end value(lie on drop rate). if the packet match a entry.it will do the drop action. if table miss, it would do nothing. the default action is NoAction().If we don't want to set a drop rate, the drop rate is 0; 

```
    Random<bit<10>>() rnd;
    action setRate()
    {
        bit<10> r=rnd.get();
    	my_ingr_md.drop_rate=r;
    }
    table packet_drop{
        key={
            my_ingr_md.drop_rate     : range;
        }

        actions ={
            drop;
            NoAction;
        }
        const default_action = NoAction();
    }

    apply{

        if(!mac_table.apply().hit)
        {
            l2_forward.apply();
        }

        if(hdr.ipv4.isValid()&&hdr.ipv4.ttl>1)
        {
            if(!ipv4_host.apply().hit)
            {
                ipv4_lpm.apply();
            }
            next_hop.apply();
            ipv4_acl.apply();
        }

        setRate();
        packet_drop.apply();
    }
```  

## hava a try
i will update the commands in the future!
