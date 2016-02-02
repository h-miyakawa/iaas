#!/bin/sh
# for i in 1 2 3 4; do
#   ./bin/trema send_packets -s host${i} -d host4
# done
./bin/slice add foo
./bin/slice add_host --mac 11:11:11:11:11:11 --port 0x2:2 --slice foo
./bin/slice add_host --mac 22:22:22:22:22:22 --port 0x3:2 --slice foo
./bin/slice add bar
./bin/slice add_host --mac 22:22:22:22:22:22 --port 0x3:2 --slice bar
./bin/slice add_host --mac 33:33:33:33:33:33 --port 0x2:1 --slice bar
./bin/trema send_packets -s host1 -d host2
./bin/trema send_packets -s host1 -d host3
# ./bin/trema send_packets -s host1 -d host2
# ./bin/trema send_packets -s host1 -d host2
# ./bin/trema send_packets -s host1 -d host2
# ./bin/trema send_packets -s host1 -d host2
# for i in 1 2 3 4; do
#   sudo ovs-ofctl dump-flows brswitch${i}
# done
exit
