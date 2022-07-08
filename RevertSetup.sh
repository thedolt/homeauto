#!/bin/bash

NC='\033[0m' # No Color
CYAN='\033[0;96m'
GREEN='\033[1;92m'

echo -en "${CYAN}Removing xorg config: $NC"
rm -rf $HOME/.config &> /dev/null
echo -e "${GREEN}Complete!$NC"

echo -en "${CYAN}Removing docker images: $NC"
sudo docker rmi zigbee2mqtt/zigbee2mqtt:latest \
  openhab/openhab:latest \
  deconzcommunity/deconz:latest \
  portainer/portainer-ce:latest \
  sepia/home:latest \
  eclipse-mosquitto sepia/stt-server:latest &> /dev/null
echo -e "${GREEN}Complete!$NC"

echo -en "${CYAN}Removing container shares: $NC"
sudo rm -rf /opt/portainer /opt/deconz /opt/openhab /opt/sepia /opt/mosquitto /opt/zigbee2mqtt &> /dev/null
echo -e "${GREEN}Complete!$NC"

echo -en "${CYAN}Removing container services: $NC"
sudo rm /lib/systemd/system/openhab.service \
  /lib/systemd/system/deconz.service \
  /lib/systemd/system/portainer.service \
  /lib/systemd/system/sepia.service \
  /lib/systemd/system/sepia-stt.service \
  /lib/systemd/system/mosquitto.service \
  /lib/systemd/system/zigbee2mqtt.service \
  /etc/udev/rules.d/99-usb-serial.rules
sudo systemctl daemon-reload &> /dev/null
echo -e "${GREEN}Complete!$NC"

echo -en "${CYAN}Removing installed base components: $NC"
sudo apt -y remove vim chromium-browser docker.io &> /dev/null
echo -e "${GREEN}Complete!$NC"

echo -en "${CYAN}Removing service users: $NC"
sudo userdel portainer  &> /dev/null
sudo userdel deconz &> /dev/null
sudo userdel openhab &> /dev/null
sudo userdel sepia &> /dev/null
sudo userdel mqtt &> /dev/null
echo -e "${GREEN}Complete!$NC"
