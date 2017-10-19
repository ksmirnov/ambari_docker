#!/usr/bin/env bash

NODE_NAME_PREFIX="ambari-node"
N=3
PORT=8080

function print_usage() {
    echo "Usage: ./deploy_cluster.sh [--nodes 3] [--port 8080] [--prefix ambari-node]"
    echo
    echo "-n, --nodes       Specify the number of total nodes"
    echo "-p, --port        Specify the port of your local machine to access Ambari Web UI (8080 - 8088)"
    echo "    --prefix      Specify the prefix to be used as a part of container name"
    echo "    --help        Print out this message"
    echo ""
    echo "Examples:"
    echo "./deploy_cluster.sh -n 5 -p 9090 --prefix cluster-node"
    echo "./deploy_cluster.sh --port 9090 --prefix cluster-node"
    echo "./deploy_cluster.sh --help"
}

function parse_args() {
    while [[ $# -gt 0 ]]
    do
    key="$1"

        case $key in
            -n|--nodes)
            N="$2"
            shift
            ;;
            -p|--port)
            PORT="$2"
            shift
            ;;
            --prefix)
            NODE_NAME_PREFIX="$2"
            shift
            ;;
            --help)
            print_usage
            exit 1
            ;;
            *)
            echo "Unknown operator '$1'"
            echo ""
            print_usage
            exit 1
            ;;
        esac
    shift
    done
}

parse_args $@

docker build -t centos-ambari .
docker network create ambarinet 2> /dev/null

# Launch containers
master_id=$(docker run --privileged -d --net ambarinet -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
    -p ${PORT}:8080 -p 50070:50070 -p 19888:19888 -p 8088:8088 --name ${NODE_NAME_PREFIX}-0 centos-ambari)

# Starting SSHD and NTPD services on a master node
docker exec $NODE_NAME_PREFIX-0 systemctl start sshd
docker exec $NODE_NAME_PREFIX-0 systemctl start ntpd

echo ${master_id:0:12} > hosts
for i in $(seq $((N-1)));
do
    container_id=$(docker run --privileged -d --net ambarinet -v /sys/fs/cgroup:/sys/fs/cgroup:ro \
        --name $NODE_NAME_PREFIX-$i centos-ambari)

    # Starting SSHD and NTPD services on a worker node
    docker exec $NODE_NAME_PREFIX-$i systemctl start sshd
    docker exec $NODE_NAME_PREFIX-$i systemctl start ntpd

    echo ${container_id:0:12} >> hosts
done

# Copy the workers file to the master container
docker cp hosts $master_id:/root

# Print the private key
echo "Copying back the private key..."
docker cp $master_id:/root/.ssh/id_rsa .

# Setup and start the Ambari server
docker exec $NODE_NAME_PREFIX-0 ambari-server setup -s
docker exec $NODE_NAME_PREFIX-0 ambari-server start

# Print the hostnames
echo "Using the following hostnames:"
echo "------------------------------"
cat hosts
echo "------------------------------"