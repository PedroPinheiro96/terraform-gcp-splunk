#!/bin/bash

#Stop script on errors or undefined variables
set -euo pipefail

SPLUNK_FILE="splunk-enterprise.tgz"
SPLUNK_URL="https://download.splunk.com/products/splunk/releases/9.3.1/linux/splunk-9.3.1-0b8d769cb912-Linux-x86_64.tgz"
CM_URI="https://10.0.5.206:8089"
CLUSTER_KEY="gcpCluster"
CLUSTER_DISC="gcpSplunkIndexerDiscovery"
DS_URI="https://10.0.5.205:8089"
ADMIN_USER="gcpSplunk"
ADMIN_PASS="gcpSplunk"
SPLUNK_DB="/opt/splunk/var/lib/splunk"

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

#Configuring the server as a Deployment Client
sudo -u splunk bash -c "cat << EOF > /opt/splunk/etc/system/local/deploymentclient.conf
[deployment-client]

[target-broker:deploymentServer]
targetUri = $DS_URI
EOF"

#Configuring the node as the Cluster Manager
sudo -u splunk bash -c "cat << EOF >> /opt/splunk/etc/system/local/server.conf
[clustering]
mode = manager
pass4SymmKey = $CLUSTER_KEY
replication_factor = 3
search_factor = 2
cluster_label = indexerCluster
EOF"

#Enabling Indexer Discovery on the Cluster Manager
sudo -u splunk bash -c "cat << EOF >> /opt/splunk/etc/system/local/server.conf
[indexer_discovery]
pass4SymmKey = $CLUSTER_DISC
EOF"

#Forwarding internal logs to the indexers
sudo -u splunk bash -c "cat << EOF >> /opt/splunk/etc/system/local/outputs.conf
[indexer_discovery:indexerCluster]
manager_uri = $CM_URI
pass4SymmKey = $CLUSTER_DISC

[tcpout:indexerCluster]
indexerDiscovery = indexerCluster
useACK = true

[tcpout]
defaultGroup = indexerCluster
EOF"

#Indexers are managed by the Cluster Manager. The license app is not distributed by the Deployment Server
sudo -u splunk bash -c "mkdir -p /opt/splunk/etc/manager-apps/SplunkLicense/default"
sudo -u splunk bash -c "cat << EOF > /opt/splunk/etc/manager-apps/SplunkLicense/default/server.conf
[license]
manager_uri = $DS_URI
EOF"

#Enabling listening ports on peer nodes
sudo -u splunk bash -c "cat << EOF >> /opt/splunk/etc/manager-apps/_cluster/local/inputs.conf
[splunktcp:9997]
disabled = 0
EOF"

#Configuring the indexes on the Indexers
sudo -u splunk bash -c "cat << EOF >> /opt/splunk/etc/manager-apps/_cluster/local/indexes.conf
[prod_azure]
homePath   = $SPLUNK_DB/prod_azure/db
coldPath   = $SPLUNK_DB/prod_azure/colddb
thawedPath = $SPLUNK_DB/prod_azure/thaweddb
repFactor = auto

[prod_defender]
homePath   = $SPLUNK_DB/prod_defender/db
coldPath   = $SPLUNK_DB/prod_defender/colddb
thawedPath = $SPLUNK_DB/prod_defender/thaweddb
repFactor = auto

[prod_windows]
homePath   = $SPLUNK_DB/prod_windows/db
coldPath   = $SPLUNK_DB}/prod_windows/colddb
thawedPath = $SPLUNK_DB/prod_windows/thaweddb
repFactor = auto
EOF"

#Disabling Splunk Web on peer nodes
sudo -u splunk bash -c "cat << EOF >> /opt/splunk/etc/manager-apps/_cluster/local/server.conf
[general]
startwebserver = 0
EOF"

#Deleting the installer
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

#Enabling boot-start and accepting the license
sudo /opt/splunk/bin/splunk enable boot-start -user splunk --accept-license --answer-yes
sudo chown -R splunk:splunk /opt/splunk

#Starting Splunk
sudo -u splunk /opt/splunk/bin/splunk start