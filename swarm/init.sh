#!/usr/bin/env bash

set -e

# create network
echo "----- Setup machine to deploy the key-value store -----"
docker-machine create -d vscale --vscale-made-from="debian_8.1_64_001_master" mh-keystore

echo "----- Start consul -----"
docker $(docker-machine config mh-keystore) run -d -p "8500:8500" --name="consul" -h "consul" progrium/consul -server -bootstrap

echo "----- create a machine with the swarm master -----"
docker-machine create -d vscale --vscale-made-from="debian_8.1_64_001_master" --swarm --swarm-master \
    --swarm-discovery="consul://$(docker-machine ip mh-keystore):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip mh-keystore):8500" \
    --engine-opt="cluster-advertise=eth0:2376" \
    swarm-master

echo "----- create a machine for swarm node 1 -----"
docker-machine create -d vscale --vscale-made-from="debian_8.1_64_001_master" --swarm \
    --swarm-discovery="consul://$(docker-machine ip mh-keystore):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip mh-keystore):8500" \
    --engine-opt="cluster-advertise=eth0:2376" \
    swarm-node-01

# Other DataCenter machine
echo "----- create a machine for swarm node 2 -----"
docker-machine create -d digitalocean \
    --swarm \
    --swarm-discovery="consul://$(docker-machine ip mh-keystore):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip mh-keystore):8500" \
    --engine-opt="cluster-advertise=eth0:2376" \
    swarm-node-02

echo "----- Set environment to point to swarm-master -----"
eval $(docker-machine env --swarm swarm-master)

echo "----- Create overlay network -----"
docker network create --driver overlay my-net

echo "---- -------------------- -----"
echo "---- Check network status -----"
echo "---- -------------------- -----"
docker network ls

echo " "
echo "---- ---------------- -----"
echo "---- Ready to deploy  -----"
echo "---- ---------------- -----"
