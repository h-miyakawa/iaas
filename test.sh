#!/bin/sh
sudo rm /tmp/*
for i in 1 2 3 4; do
  sudo ovs-vsctl del-br brswitch${i}
done
sudo service network-manager stop
./bin/trema run lib/routing_switch.rb -c trema.conf -- -s graphviz
sudo service network-manager start
exit
