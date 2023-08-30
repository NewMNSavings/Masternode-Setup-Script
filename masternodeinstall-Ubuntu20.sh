#!/bin/bash

PORT=14258
RPCPORT=14259
CONF_DIR=~/.nmnsc
COINZIP='https://github.com/NewMNSavings/NewMNSCoin/releases/download/v1.0.0/nMNSC-Ubuntu20.zip'

cd ~
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}$0 must be run as root.${NC}"
   exit 1
fi

function configure_systemd {
  cat << EOF > /etc/systemd/system/nmnsc.service
[Unit]
Description=nMNSC Service
After=network.target
[Service]
User=root
Group=root
Type=forking
ExecStart=/usr/local/bin/nmnscd
ExecStop=-/usr/local/bin/nmnsc-cli stop
Restart=always
PrivateTmp=true
TimeoutStopSec=60s
TimeoutStartSec=10s
StartLimitInterval=120s
StartLimitBurst=5
[Install]
WantedBy=multi-user.target
EOF
  systemctl daemon-reload
  sleep 2
  systemctl enable nmnsc.service
  systemctl start nmnsc.service
}

echo ""
echo ""
DOSETUP="y"

if [ $DOSETUP = "y" ]  
then
  apt-get update
  apt install zip unzip git curl wget -y
  cd /usr/local/bin/
  wget $COINZIP
  unzip *.zip
  chmod +x nmnsc*
  rm nmnsc-qt nmnsc-tx nMNSC-Ubuntu20.zip
  
  mkdir -p $CONF_DIR
  cd $CONF_DIR
  wget https://github.com/NewMNSavings/NewMNSCoin/releases/download/v1.0.0/bootstrap.zip
  unzip bootstrap.zip
  rm bootstrap.zip

fi

 IP=$(curl -s4 api.ipify.org)
 echo ""
 echo "Configure your masternodes now!"
 echo "Detecting IP address:$IP"
 echo ""
 echo "Enter masternode private key"
 read PRIVKEY
 
  echo "rpcuser=user"`shuf -i 100000-10000000 -n 1` >> nmnsc.conf_TEMP
  echo "rpcpassword=pass"`shuf -i 100000-10000000 -n 1` >> nmnsc.conf_TEMP
  echo "rpcallowip=127.0.0.1" >> nmnsc.conf_TEMP
  echo "rpcport=$RPCPORT" >> nmnsc.conf_TEMP
  echo "listen=1" >> nmnsc.conf_TEMP
  echo "server=1" >> nmnsc.conf_TEMP
  echo "daemon=1" >> nmnsc.conf_TEMP
  echo "maxconnections=250" >> nmnsc.conf_TEMP
  echo "masternode=1" >> nmnsc.conf_TEMP
  echo "" >> nmnsc.conf_TEMP
  echo "port=$PORT" >> nmnsc.conf_TEMP
  echo "externalip=$IP:$PORT" >> nmnsc.conf_TEMP
  echo "masternodeaddr=$IP:$PORT" >> nmnsc.conf_TEMP
  echo "masternodeprivkey=$PRIVKEY" >> nmnsc.conf_TEMP
  mv nmnsc.conf_TEMP nmnsc.conf
  cd
  echo ""
  echo -e "Your ip is ${GREEN}$IP:$PORT${NC}"

	## Config Systemctl
	configure_systemd
  
echo ""
echo "Commands:"
echo -e "Start nmnsc Service: ${GREEN}systemctl start nmnsc${NC}"
echo -e "Check nmnsc Status Service: ${GREEN}systemctl status nmnsc${NC}"
echo -e "Stop nmnsc Service: ${GREEN}systemctl stop nmnsc${NC}"
echo -e "Check Masternode Status: ${GREEN}nmnsc-cli getmasternodestatus${NC}"

echo ""
echo -e "${GREEN}nMNSC Masternode Installation Done${NC}"
exec bash
exit
