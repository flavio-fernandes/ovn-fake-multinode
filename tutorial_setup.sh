#!/usr/bin/env bash

[ $EUID -eq 0 ] || { echo 'must be root' >&2; exit 1; }

# http://docs.openvswitch.org/en/latest/tutorials/ovs-conntrack/

# ovs-appctl dpctl/dump-conntrack
# sendp(Ether()/IP(src="192.168.0.2", dst="10.0.0.2")/TCP(sport=1024, dport=2048, flags=0x11, seq=102, ack=201), iface="veth_l1")
# sendp(Ether()/IP(src="10.0.0.2", dst="192.168.0.2")/TCP(sport=2048, dport=1024, flags=0X11, seq=201, ack=103), iface="veth_r1")
# sendp(Ether()/IP(src="192.168.0.2", dst="10.0.0.2")/TCP(sport=1024, dport=2048, flags=0x10, seq=103, ack=202), iface="veth_l1")

# tcpdump -i veth_l0 -vvnel tcp
# tcpdump -i veth_r0 -vvnel tcp

source /home/vagrant/.env/bin/activate

set -o xtrace
set -o errexit

for ns in left right; do \
  ip netns add $ns
  ip netns exec $ns ip link set lo up
  # ip netns exec $ns $(which scapy)
done
ip link add veth_l0 type veth peer name veth_l1
ip link set veth_l1 netns left
ip link add veth_r0 type veth peer name veth_r1
ip link set veth_r1 netns right

ip netns exec left ip link set veth_l1 up
ip netns exec right ip link set veth_r1 up
ip link set veth_l0 up
ip link set veth_r0 up

OVS_BRIDGE=br0
ovs-vsctl add-br ${OVS_BRIDGE}
ovs-vsctl add-port br0 veth_l0
ovs-vsctl add-port br0 veth_r0

ovs-ofctl del-flows $OVS_BRIDGE

#ovs-ofctl add-flow $OVS_BRIDGE \
#         "table=0, priority=10, in_port=veth_l0, actions=veth_r0"
#ovs-ofctl add-flow $OVS_BRIDGE \
#         "table=0, priority=10, in_port=veth_r0, actions=veth_l0"
ovs-ofctl add-flow $OVS_BRIDGE "table=0, priority=10, in_port=veth_l0, actions=drop"
ovs-ofctl add-flow $OVS_BRIDGE "table=0, priority=10, in_port=veth_r0, actions=drop"

ovs-ofctl add-flow br0 \
   "table=0, priority=50, ct_state=-trk, tcp, in_port=veth_l0, actions=ct(table=0)"
ovs-ofctl add-flow br0 \
    "table=0, priority=50, ct_state=+trk+new, tcp, in_port=veth_l0, actions=ct(commit),veth_r0"

ovs-ofctl add-flow br0 \
    "table=0, priority=50, ct_state=-trk, tcp, in_port=veth_r0, actions=ct(table=0)"
ovs-ofctl add-flow br0 \
    "table=0, priority=50, ct_state=+trk+est, tcp, in_port=veth_r0, actions=veth_l0"

ovs-ofctl add-flow br0 \
    "table=0, priority=50, ct_state=+trk+est, tcp, in_port=veth_l0, actions=veth_r0"

ovs-ofctl --names dump-flows $OVS_BRIDGE
