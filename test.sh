#!/bin/sh
sudo rm /tmp/*
for i in 1 2 3 4; do
  sudo ovs-vsctl del-br brswitch${i}
done
net_stop
./bin/trema run lib/routing_switch.rb -c trema.conf -- -s graphviz
net_start
exit
