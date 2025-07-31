#!/bin/bash

# Stop script on errors or undefined variables
set -euo pipefail

SPLUNK_FILE="splunk-enterprise.tgz"
SPLUNK_URL="https://download.splunk.com/products/splunk/releases/9.3.1/linux/splunk-9.3.1-0b8d769cb912-Linux-x86_64.tgz"
SPLUNK_USER="splunk"
HOSTNAME="ds"
CM_URI="https://10.0.5.206:8089"
DS_URI="https://10.0.5.205:8089"
HF_PUBIP="10.0.5.207:9997" #UPDATE ON DEPLOYMENT APPS
ADMIN_USER="gcpSplunk"
ADMIN_PASS="gcpSplunk"
CLUSTER_KEY="gcpCluster"
CLUSTER_DISC="gcpSplunkIndexerDiscovery"

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

#Creating the license app and server class to be distributed to the deployment clients
sudo -u splunk bash -c "mkdir -p /opt/splunk/etc/deployment-apps/SplunkLicense/default"
sudo -u splunk bash -c "cat << EOF > /opt/splunk/etc/deployment-apps/SplunkLicense/default/server.conf
[license]
manager_uri = $DS_URI
EOF"

#Enabling the tcp port 9997 on the Universal Forwarder
sudo -u splunk bash -c "mkdir -p /opt/splunk/etc/deployment-apps/UFConfig/local"
sudo -u splunk bash -c "cat << EOF >> /opt/splunk/etc/deployment-apps/UFConfig/local/inputs.conf
[splunktcp://9997]
disabled = 0
EOF"

#Configuring the Universal Forwarder to forward logs to the Heavy Forwarder
sudo -u splunk bash -c "cat << EOF >> /opt/splunk/etc/deployment-apps/UFConfig/local/outputs.conf
[tcpout]
defaultGroup = heavyForwarder

[tcpout:heavyForwarder]
server = $HF_PUBIP
EOF"

#Enabling the tcp port 9997 on the Heavy Forwarder
sudo -u splunk bash -c "mkdir -p /opt/splunk/etc/deployment-apps/HFConfig/local"
sudo -u splunk bash -c "cat << EOF > /opt/splunk/etc/deployment-apps/HFConfig/local/inputs.conf
[splunktcp://9997]
disabled = 0
EOF"

#Enabling SSL on the Deployment Clients
sudo -u splunk bash -c "mkdir -p /opt/splunk/etc/deployment-apps/SplunkHTTPS/local"
sudo -u splunk bash -c "cat << EOF >> /opt/splunk/etc/deployment-apps/SplunkHTTPS/local/web.conf
[settings]
enableSplunkWebSSL = true
EOF"

#Enabling SSL on the Deployment Server
sudo -u splunk bash -c "cat << EOF >> /opt/splunk/etc/system/local/web.conf
[settings]
enableSplunkWebSSL = true
EOF"

#Setting the Windows Security input to be distributed to the Universal Forwarder
sudo -u splunk bash -c "cat << EOF >> /opt/splunk/etc/deployment-apps/UFConfig/local/inputs.conf
[WinEventLog://Security]
disabled = 0
index = prod_windows
EOF"

#Defining server classes
sudo -u splunk bash -c "cat << EOF > /opt/splunk/etc/system/local/serverclass.conf
[serverClass:all_servers:app:SplunkLicense]
restartSplunkWeb = 0
restartSplunkd = 1
stateOnClient = enabled

[serverClass:all_servers:app:SplunkHTTPS]
restartSplunkWeb = 0
restartSplunkd = 1
stateOnClient = enabled

[serverClass:HeavyForwarders:app:HFConfig]
restartSplunkWeb = 0
restartSplunkd = 1
stateOnClient = enabled

[serverClass:MSCloud:app:Splunk_TA_microsoft-cloudservices]
restartSplunkWeb = 0
restartSplunkd = 1
stateOnClient = enabled

[serverClass:UniversalForwarders]
whitelist.0 = DESKTOP*

[serverClass:HeavyForwarders]
whitelist.0 = hf

[serverClass:all_servers]
whitelist.0 = *
blacklist.0 = DESKTOP*

[serverClass:UniversalForwarders:app:UFConfig]
restartSplunkWeb = 0
restartSplunkd = 1
stateOnClient = enabled

[serverClass:HeavyForwarders:app:Splunk_TA_windows]
restartSplunkWeb = 0
restartSplunkd = 1
stateOnClient = enabled

[serverClass:MSCloud]
whitelist.0 = sh
whitelist.1 = hf

[serverClass:Windows:app:Splunk_TA_windows]
restartSplunkWeb = 0
restartSplunkd = 1
stateOnClient = enabled

[serverClass:Windows]
whitelist.0 = DESKTOP*
whitelist.1 = hf
whitelist.2 = sh
EOF"

#Configuring the Deployment Server to forward logs to the Indexer Cluster using Indexer Discovery
sudo -u splunk bash -c "cat << EOF >> /opt/splunk/etc/system/local/outputs.conf
[indexer_discovery:indexerCluster]
manager_uri = $CM_URI
pass4SymmKey = $CLUSTER_DISC

[tcpout:indexerCluster]
indexerDiscovery = indexerCluster
useACK = true

[tcpout]
defaultGroup = indexerCluster

#BUG FIX - Deployment Clients not showing up
[indexAndForward]
index = true
selectiveIndexing = true 
EOF"

#Deleting the installer
cd ~
rm /tmp/$SPLUNK_FILE

#Installing and configuring ufw
sudo apt install ufw -y
sudo ufw allow 8000 # Splunk webpage
sudo ufw allow 8089 # Used by Splunkd to communicate with other Splunk instances.
sudo ufw allow 8191 # KVStore
sudo ufw allow 22 # SSH
sudo ufw enable

#Enabling boot-start and accepting the license
sudo /opt/splunk/bin/splunk enable boot-start -user splunk --accept-license --answer-yes
sudo chown -R splunk:splunk /opt/splunk

#Creating the developer license file
sudo -u splunk bash -c "cat << EOF > /opt/splunk/etc/licenses/devLicense.lic



----------------------------- ADD YOUR SPLUNK LICENSE GOES HERE -----------------------------



EOF"

#To ensure the other VMs have enough time to be configured. The script fails if the add search-server command below does not succeed.
sleep 5m 

#Installing the license
sudo -u splunk /opt/splunk/bin/splunk add licenses /opt/splunk/etc/licenses/devLicense.lic

#Starting Splunk
sudo -u splunk /opt/splunk/bin/splunk start

#Adding the Splunk hosts as search peers
sudo -u splunk /opt/splunk/bin/splunk add search-server https://10.0.5.201:8089 -auth $ADMIN_USER:$ADMIN_PASS -remoteUsername $ADMIN_USER -remotePassword $ADMIN_PASS
sudo -u splunk /opt/splunk/bin/splunk add search-server https://10.0.5.202:8089 -auth $ADMIN_USER:$ADMIN_PASS -remoteUsername $ADMIN_USER -remotePassword $ADMIN_PASS
sudo -u splunk /opt/splunk/bin/splunk add search-server https://10.0.5.203:8089 -auth $ADMIN_USER:$ADMIN_PASS -remoteUsername $ADMIN_USER -remotePassword $ADMIN_PASS
sudo -u splunk /opt/splunk/bin/splunk add search-server https://10.0.5.204:8089 -auth $ADMIN_USER:$ADMIN_PASS -remoteUsername $ADMIN_USER -remotePassword $ADMIN_PASS
sudo -u splunk /opt/splunk/bin/splunk add search-server https://10.0.5.206:8089 -auth $ADMIN_USER:$ADMIN_PASS -remoteUsername $ADMIN_USER -remotePassword $ADMIN_PASS
sudo -u splunk /opt/splunk/bin/splunk add search-server https://10.0.5.207:8089 -auth $ADMIN_USER:$ADMIN_PASS -remoteUsername $ADMIN_USER -remotePassword $ADMIN_PASS

#Configuring the Monitoring Console
sudo -u splunk bash -c "cat << EOF >> /opt/splunk/etc/system/local/server.conf

[monitoring_console]
disabled = false
EOF"

#Configuring the Splunk server roles on the Monitoring Console
sudo -u splunk bash -c "cat << EOF > /opt/splunk/etc/system/local/distsearch.conf
[distributedSearch]
servers = https://10.0.5.201:8089,https://10.0.5.202:8089,https://10.0.5.203:8089,https://10.0.5.204:8089,https://10.0.5.206:8089,https://10.0.5.207:8089

[distributedSearch:dmc_group_cluster_master]
servers = 10.0.5.206:8089

[distributedSearch:dmc_group_license_master]
servers = localhost:localhost

[distributedSearch:dmc_group_shc_deployer]

[distributedSearch:dmc_group_deployment_server]
servers = localhost:localhost

[distributedSearch:dmc_group_indexer]
default = true
servers = localhost:localhost,10.0.5.202:8089,10.0.5.203:8089,10.0.5.204:8089,10.0.5.207:8089

[distributedSearch:dmc_group_search_head]
servers = localhost:localhost,10.0.5.201:8089

[distributedSearch:dmc_group_kv_store]
servers = 10.0.5.201:8089

[distributedSearch:dmc_indexerclustergroup_indexerCluster]
servers = 10.0.5.201:8089,10.0.5.202:8089,10.0.5.203:8089,10.0.5.204:8089,10.0.5.206:8089
EOF"

#Restarting Splunk
sudo -u splunk /opt/splunk/bin/splunk restart