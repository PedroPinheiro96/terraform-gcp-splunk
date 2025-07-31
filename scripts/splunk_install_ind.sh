#!/bin/bash

#Stop script on errors or undefined variables
set -euo pipefail

SPLUNK_FILE="splunk-enterprise.tgz"
SPLUNK_URL="https://download.splunk.com/products/splunk/releases/9.3.1/linux/splunk-9.3.1-0b8d769cb912-Linux-x86_64.tgz"
CLUSTER_KEY="gcpCluster"
CM_URI="https://10.0.5.206:8089"
ADMIN_USER="gcpSplunk"
ADMIN_PASS="gcpSplunk"

#Updating the server
sudo apt update && sudo apt upgrade -y

#Creating the Splunk User
sudo useradd -m -s /bin/bash splunk

#Downloading Splunk
cd /tmp
wget -O $SPLUNK_FILE $SPLUNK_URL

#Extracting Splunk
sudo tar -xf $SPLUNK_FILE -C /opt/

#Adding the Splunk paths to .bashrc
echo 'export SPLUNK_HOME=/opt/splunk' | sudo -u splunk tee -a /home/splunk/.bashrc > /dev/null
echo 'export SPLUNK_DB=/opt/splunk/var/lib/splunk/' | sudo -u splunk tee -a /home/splunk/.bashrc > /dev/null

#Changing ownership of /opt/splunk and its directories and files
sudo chown -R splunk:splunk /opt/splunk

#Setting Splunk admin credentials
sudo -u splunk bash -c "cat << EOF > /opt/splunk/etc/system/local/user-seed.conf
[user_info]
USERNAME = $ADMIN_USER
PASSWORD = $ADMIN_PASS
EOF"

#Disabling the Splunk web server
sudo -u splunk bash -c "cat << EOF >> /opt/splunk/etc/system/local/web.conf
[settings]
startwebserver = 0
EOF"

#Configuring the indexers as peers of the cluster
sudo -u splunk bash -c "cat << EOF >> /opt/splunk/etc/system/local/server.conf
[replication_port://9887]

[clustering]
manager_uri = $CM_URI
mode = peer
pass4SymmKey = $CLUSTER_KEY
EOF"

#Deleting the Installer
cd ~
rm /tmp/$SPLUNK_FILE

#Installing and configuring ufw
sudo apt install ufw -y
sudo ufw allow 8000 # Splunk webpage
sudo ufw allow 9997 # Listening port
sudo ufw allow 8089 # Used by Splunkd to communicate with other Splunk instances.
sudo ufw allow 8191 # KVStore
sudo ufw allow 8080 # Indexer Replication
sudo ufw allow 9887 # Indexer Replication
sudo ufw allow 22 # SSH
sudo ufw enable

#Enabling boot-start and accepting license
sudo /opt/splunk/bin/splunk enable boot-start -user splunk --accept-license --answer-yes
sudo chown -R splunk:splunk /opt/splunk

#Starting Splunk
sudo -u splunk /opt/splunk/bin/splunk start