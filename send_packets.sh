#!/bin/sh
for i in 1 2 3 4; do
  ./bin/trema send_packets -s host${i} -d host4
done
for i in 1 2 3 4; do
  sudo ovs-ofctl dump-flows brswitch${i}
done
exit
