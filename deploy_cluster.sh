#!/usr/bin/env bash

NODE_NAME_PREFIX="ambari-node"
N=3

docker build -t centos-ambari .
docker network create ambarinet 2> /dev/null

# Launch containers
master_id=$(docker run --privileged -d --net ambarinet -v /sys/fs/cgroup:/sys/fs/cgroup:ro -p 8080:8080 -p 50070:50070 -p 19888:19888 -p 8088:8088 --name $NODE_NAME_PREFIX-0 centos-ambari)
docker exec $NODE_NAME_PREFIX-0 systemctl start sshd
docker exec $NODE_NAME_PREFIX-0 systemctl start ntpd
echo ${master_id:0:12} > hosts
for i in $(seq $((N-1)));
do
    container_id=$(docker run --privileged -d --net ambarinet -v /sys/fs/cgroup:/sys/fs/cgroup:ro --name $NODE_NAME_PREFIX-$i centos-ambari)
    docker exec $NODE_NAME_PREFIX-$i systemctl start sshd
    docker exec $NODE_NAME_PREFIX-$i systemctl start ntpd
    echo ${container_id:0:12} >> hosts
done

# Copy the workers file to the master container
docker cp hosts $master_id:/root

# Print the private key
echo "Copying back the private key..."
docker cp $master_id:/root/.ssh/id_rsa .

# Setup and start the ambari server
docker exec $NODE_NAME_PREFIX-0 ambari-server setup -s
docker exec $NODE_NAME_PREFIX-0 ambari-server start

# Print the hostnames
echo "Using the following hostnames:"
echo "------------------------------"
cat hosts
echo "------------------------------"