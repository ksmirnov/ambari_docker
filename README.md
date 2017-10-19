# Ambari on Docker

Ambari cluster deployment tool for Docker.

## Usage
1.  Run **deploy_cluster.sh** (see **deploy_cluster.sh -- help** for a list of parameters)
2.  When script execution is finished, you'll see a message like:
    ```
    Using the following hostnames:
    ------------------------------
    410fb41cc857
    ed5ff538cd2c
    255d4301cd5d
    ------------------------------
    ```
3.  Open **http://localhost:8080** (or use the port specified by *-n --nodes*)
4.  Use *admin:admin* credentials to log in Ambari
5.  Follow Ambari instructions to install desired components
    1. Use hostnames from step **2**
    2. Use **id_rsa** from working directory
