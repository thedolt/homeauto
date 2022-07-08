#!/bin/bash

# portainer config
PORTAINER_IMAGE="portainer/portainer-ce:linux-arm64"
PORTAINER_SERVICE_NAME=portainer
PORTAINER_SERVICE_DESCRIPTION="Portainer Container Manager"
PORTAINER_SERVICE_USER=portainer
PORTAINER_PORTS=(9000)
PORTAINER_VOLUME_NAMES=("/opt/portainer" "portainer-data:/data" "/var/run/docker.sock:/var/run/docker.sock" "/etc/timezone:/etc/timezone:ro" "/etc/localtime:/etc/localtime:ro")
PORTAINER_VOLUME_PATHS=("/opt/portainer" "/opt/portainer/data")
PORTAINER_ENVIRONMENT_VARIABLES=()
PORTAINER_DEVICES=()

# deCONZ config
DECONZ_IMAGE="deconzcommunity/deconz:latest"
DECONZ_SERVICE_NAME=deconz
DECONZ_SERVICE_DESCRIPTION="deCONZ Zigbee Utility"
DECONZ_SERVICE_USER=deconz
DECONZ_PORTS=(8000 4430 5900)
DECONZ_VOLUME_NAMES=("deconz-data:/opt/deconz" "/etc/timezone:/etc/timezone:ro" "/etc/localtime:/etc/localtime:ro")
DECONZ_VOLUME_PATHS=("/opt/deconz")
DECONZ_VNC_PASSWORD=$(< /dev/urandom tr -dc \!\@\#\$\%\^\&\*\(\)\{\}\;\:\'\~\|\\_A-Z-a-z-0-9 | head -c8)
DECONZ_ENVIRONMENT_VARIABLES=("DECONZ_VNC_MODE=1" "DECONZ_VNC_PORT=${DECONZ_PORTS[2]}" "DECONZ_VNC_PASSWORD=$DECONZ_VNC_PASSWORD" "DECONZ_WEB_PORT=${DECONZ_PORTS[0]}" "DECONZ_WS_PORT=${DECONZ_PORTS[1]}")
DECONZ_DEVICES=("/dev/zigbee:/dev/ttyACM0")

# OpenHAB config
OPENHAB_IMAGE="openhab/openhab:3.4.0-snapshot-alpine"
OPENHAB_SERVICE_NAME=openhab
OPENHAB_SERVICE_DESCRIPTION="OpenHAB Home Automation"
OPENHAB_SERVICE_USER=openhab
OPENHAB_PORTS=(8080)
OPENHAB_VOLUME_NAMES=("/opt/openhab" "openhab-conf:/opt/openhab/conf" "openhab-userdata:/opt/openhab/userdata" "openhab-addons:/opt/openhab/addons" "openhab-java:/opt/openhab/.java" "/etc/timezone:/etc/timezone:ro" "/etc/localtime:/etc/localtime:ro")
OPENHAB_VOLUME_PATHS=("/opt/openhab" "/opt/openhab/conf" "/opt/openhab/userdata" "/opt/openhab/addons" "/opt/openhab/.java")
OPENHAB_ENVIRONMENT_VARIABLES=("CRYPTO_POLICY=unlimited")
OPENHAB_DEVICES=(/dev/zwave)

# SEPIA config
SEPIA_IMAGE="sepia/home:latest"
SEPIA_SERVICE_NAME=sepia
SEPIA_SERVICE_DESCRIPTION="SEPIA Home"
SEPIA_SERVICE_USER=sepia
SEPIA_PORTS=(20741)
SEPIA_VOLUME_NAMES=("sepia-home-data:/home/admin/sepia-home-data" "/etc/timezone:/etc/timezone:ro" "/etc/localtime:/etc/localtime:ro")
SEPIA_VOLUME_PATHS=("/opt/sepia")
SEPIA_ENVIRONMENT_VARIABLES=()
SEPIA_DEVICES=()

# SEPIA-STT config
SEPIA_STT_IMAGE="sepia/stt-server:vosk_aarch64"
SEPIA_STT_SERVICE_NAME=sepia-stt
SEPIA_STT_SERVICE_DESCRIPTION="SEPIA Speech-To-Text"
SEPIA_STT_SERVICE_USER=sepia
SEPIA_STT_PORTS=(20741)
SEPIA_STT_VOLUME_NAMES=("/etc/timezone:/etc/timezone:ro" "/etc/localtime:/etc/localtime:ro")
SEPIA_STT_VOLUME_PATHS=()
SEPIA_STT_ENVIRONMENT_VARIABLES=()
SEPIA_STT_DEVICES=("/dev/zwave")

# Mosquitto config
MOSQUITTO_IMAGE="eclipse-mosquitto:latest"
MOSQUITTO_SERVICE_NAME=mosquitto
MOSQUITTO_SERVICE_DESCRIPTION="Eclipse Mosquitto"
MOSQUITTO_SERVICE_USER=mqtt
MOSQUITTO_PORTS=(1883 9001)
MOSQUITTO_VOLUME_NAMES=("/opt/mosquitto" "mosquitto-config:/mosquitto/config" "mosquitto-data:/mosquitto/data" "mosquitto-log:/mosquitto/log" "/etc/timezone:/etc/timezone:ro" "/etc/localtime:/etc/localtime:ro")
MOSQUITTO_VOLUME_PATHS=("/opt/mosquitto" "/opt/mosquitto/config" "/opt/mosquitto/data" "/opt/mosquitto/log")
SEPIA_STT_ENVIRONMENT_VARIABLES=()
MOSQUITTO_DEVICES=()

# Zigbee2MQTT config
ZIGBEE2MQTT_IMAGE="zigbee2mqtt/zigbee2mqtt-edge-aarch64:latest"
ZIGBEE2MQTT_SERVICE_NAME=zigbee2mqtt
ZIGBEE2MQTT_SERVICE_DESCRIPTION="Zigbee2MQTT Broker"
ZIGBEE2MQTT_SERVICE_USER=mqtt
ZIGBEE2MQTT_PORTS=(8008)
ZIGBEE2MQTT_VOLUME_NAMES=("/opt/zigbee2mqtt" "zigbee2mqtt-app-data:/app/data" "/run/udev:/run/udev:ro")
ZIGBEE2MQTT_VOLUME_PATHS=("/opt/zigbee2mqtt" "/opt/zigbee2mqtt/data")
ZIGBEE2MQTT_ENVIRONMENT_VARIABLES=()
ZIGBEE2MQTT_DEVICES=("/dev/zigbee:/dev/ttyACM0")

# Other variables
NC='\033[0m' # No Color

# Function that creates the services
function create_service () {
PORTS=""
for i in ${SERVICE_PORTS[@]}; do PORTS+="  -p ${i}:${i} \\\\\n";done
PORTS=${PORTS%\n}

VOLUMES=""
for i in ${VOLUME_NAMES[@]}
do 
  if [[ ${i} == *":"* ]]
  then
    VOLUMES+="  -v ${i} \\\\\n"
  fi
done
VOLUMES=${VOLUMES%\n}

ENV_VARS=""
for i in ${ENVIRONMENT_VARIABLES[@]}; do ENV_VARS+="  -e ${i} \\\\\n";done
ENV_VARS=${ENV_VARS%\n}

DEVICES=""
for i in ${SERVICE_DEVICES[@]}; do DEVICES+="  --device=${i} \\\\\n";done
DEVICES=${DEVICES%\n}

echo -en "\033[0;96mCreating shared folders: $NC"
COUNTER=0
for i in ${VOLUME_PATHS[@]}
do
  sudo mkdir -p ${i} 1> /dev/null
  sudo chown -R $SERVICE_USER:$SERVICE_USER ${i} 1> /dev/null
  if [[ $i == *"/opt/"* ]] && [[ ${VOLUME_NAMES[COUNTER]} == *":"* ]]
  then
    VOL=(${VOLUME_NAMES[$COUNTER]//:/ })
    if [[ ${VOL[0]} != *"/"* ]]
    then
      sudo docker volume create --opt type=none --opt device=$i --opt o=bind ${VOL[0]} 1> /dev/null
    fi
  fi
  let COUNTER++
done
echo -e "\033[1;92mComplete!$NC"

echo -en "\033[0;96mCreating $SERVICE_DESCRIPTION service container: $NC"
sudo docker pull $IMAGE 1> /dev/null
sudo rm -rf /lib/systemd/system/$SERVICE_NAME.service 1> /dev/null
sudo tee -a /lib/systemd/system/$SERVICE_NAME.service > /dev/null <<EOT
[Unit]
Description=$SERVICE_DESCRIPTION
Requires=docker.service
After=docker.service

[Service]
Restart=always
ExecStart=/usr/bin/docker run --rm --name=%n \\
EOT
rm ./temp.service
if [[ ! -z "$PORTS" ]]
then 
  echo -e "$PORTS" >> ./temp.service
fi
if [[ ! -z "$VOLUMES" ]]
then 
  echo -e "$VOLUMES" >> ./temp.service
fi
if [[ ! -z "$ENV_VARS" ]]
then
  echo -e "$ENV_VARS" >> ./temp.service
fi
if [[ ! -z "$DEVICES" ]]
then
  echo -e "$DEVICES" >> ./temp.service
fi
sudo bash -c "cat ./temp.service >> /lib/systemd/system/$SERVICE_NAME.service"
sudo tee -a /lib/systemd/system/$SERVICE_NAME.service > /dev/null <<EOT
  $IMAGE
ExecStop=/usr/bin/docker stop -t 2 %n ; /usr/bin/docker rm -f %n

[Install]
WantedBy=multi-user.target
EOT
echo -e "\033[1;92mComplete!$NC"
}

# install basics
echo -en "\033[0;96mInstalling base software and configuring calendar: $NC"
sudo apt -y install vim chromium-browser docker.io &> /dev/null
sudo usermod -a -G docker $USER 1> /dev/null
echo -e "\033[1;92mComplete!$NC"

# unpack IOTstack tools (Placed here for convenience and curiosity)
# tar -xzf IOTstack.tgz

# Create permanent links to usb serial devices for z-wave and zigbee communications.
# THESE DEVICE IDS ARE FOR DECONZ CONBEE2 USB ZIGBEE DEVICE 
# https://www.amazon.com/Controller-SmartStart-Raspberry-Compatible-SmartThings/dp/B089GSFKYW/ref=sr_1_3?crid=2CW0BPKW4M11Y&keywords=z-stick&qid=1657250929&sprefix=z-stick%2Caps%2C105&sr=8-3&ufe=app_do%3Aamzn1.fos.fa474cd8-6dfc-4bad-a280-890f5a4e2f90
# AND AEOTEC Z-STICK USB Z-WAVE DEVICES
# https://www.amazon.com/dresden-elektronik-ConBee-Universal-Gateway/dp/B07PZ7ZHG5/ref=sr_1_3?crid=VMC4ZP3TQEXW&keywords=conbee+2&qid=1657250972&sprefix=conbee+2%2Caps%2C93&sr=8-3
# YOU WILL NEED TO DETERMINE THE APPROPRIATE UDEVADM COMMANDS TO REVEAL YOUR USB DEVICE IDS

echo -en "\033[0;96mAdding static device names for z-wave and zigbee adapters: $NC"
sudo bash -c 'echo "SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"1cf1\", ATTRS{idProduct}==\"0030\", ATTRS{serial}==\"DE2469919\", SYMLINK+=\"zigbee\"" > /etc/udev/rules.d/99-usb-serial.rules' 1> /dev/null
sudo bash -c 'echo "SUBSYSTEM==\"tty\", ATTRS{idVendor}==\"0658\", ATTRS{idProduct}==\"0200\", SYMLINK+=\"zwave\"" >> /etc/udev/rules.d/99-usb-serial.rules' 1> /dev/null
echo -e "\033[1;92mComplete!$NC"

echo -e "\033[0;96mSetting up container services.  THIS WILL TAKE A FEW MINUTES. $NC"

# install docker and portainer
SERVICE_NAME=$PORTAINER_SERVICE_NAME
SERVICE_DESCRIPTION=$PORTAINER_SERVICE_DESCRIPTION
SERVICE_USER=$PORTAINER_SERVICE_USER
SERVICE_PORTS=${PORTAINER_PORTS[@]}
VOLUME_NAMES=${PORTAINER_VOLUME_NAMES[@]}
VOLUME_PATHS=${PORTAINER_VOLUME_PATHS[@]}
SERVICE_DEVICES=${PORTAINER_DEVICES[@]}
IMAGE=$PORTAINER_IMAGE

echo -en "\033[0;96mCreating $SERVICE_USER: $NC"
sudo useradd -r -s /sbin/nologin $SERVICE_USER 1> /dev/null
sudo usermod -a -G $SERVICE_USER $SERVICE_USER 1> /dev/null
echo -e "\033[1;92mComplete!$NC"
SERVICE_USER_UID=$(id -u $SERVICE_USER)
SERVICE_USER_GID=$(id -g $SERVICE_USER)

PORTAINER_ENVIRONMENT_VARIABLES+=("USER_ID=$SERVICE_USER_UID")
PORTAINER_ENVIRONMENT_VARIABLES+=("GROUP_ID=$SERVICE_USER_GID")
ENVIRONMENT_VARIABLES=${PORTAINER_ENVIRONMENT_VARIABLES[@]}

create_service
# sudo ln -s /lib/systemd/system/portainer.service /etc/systemd/system/portainer.service

# install deconz for conbee2 zigbee stick
SERVICE_NAME=$DECONZ_SERVICE_NAME
SERVICE_DESCRIPTION=$DECONZ_SERVICE_DESCRIPTION
SERVICE_USER=$DECONZ_SERVICE_USER
SERVICE_PORTS=${DECONZ_PORTS[@]}
VOLUME_NAMES=${DECONZ_VOLUME_NAMES[@]}
VOLUME_PATHS=${DECONZ_VOLUME_PATHS[@]}
SERVICE_DEVICES=${DECONZ_DEVICES[@]}
IMAGE=$DECONZ_IMAGE

echo -en "\033[0;96mCreating $SERVICE_USER: $NC"
sudo useradd -r -s /sbin/nologin $SERVICE_USER 1> /dev/null
sudo usermod -a -G $SERVICE_USER $SERVICE_USER 1> /dev/null
sudo usermod -a -G dialout $SERVICE_USER 1> /dev/null
echo -e "\033[1;92mComplete!$NC"
SERVICE_USER_UID=$(id -u $SERVICE_USER)
SERVICE_USER_GID=$(id -g $SERVICE_USER)

DECONZ_ENVIRONMENT_VARIABLES+=("DECONZ_UID=$SERVICE_USER_UID")
DECONZ_ENVIRONMENT_VARIABLES+=("DECONZ_GID=$SERVICE_USER_GID")
ENVIRONMENT_VARIABLES=${DECONZ_ENVIRONMENT_VARIABLES[@]}

create_service
# sudo ln -s /lib/systemd/system/deconz.service /etc/systemd/system/deconz.service

# install openHAB
SERVICE_NAME=$OPENHAB_SERVICE_NAME
SERVICE_DESCRIPTION=$OPENHAB_SERVICE_DESCRIPTION
SERVICE_USER=$OPENHAB_SERVICE_USER
SERVICE_PORTS=${OPENHAB_PORTS[@]}
VOLUME_NAMES=${OPENHAB_VOLUME_NAMES[@]}
VOLUME_PATHS=${OPENHAB_VOLUME_PATHS[@]}
SERVICE_DEVICES=${OPENHAB_DEVICES[@]}
IMAGE=$OPENHAB_IMAGE

echo -en "\033[0;96mCreating $SERVICE_USER: $NC"
sudo useradd -r -s /sbin/nologin $SERVICE_USER 1> /dev/null
sudo usermod -a -G $SERVICE_USER $SERVICE_USER 1> /dev/null
echo -e "\033[1;92mComplete!$NC"
SERVICE_USER_UID=$(id -u $SERVICE_USER)
SERVICE_USER_GID=$(id -g $SERVICE_USER)

OPENHAB_ENVIRONMENT_VARIABLES+=("USER_ID=$SERVICE_USER_UID")
OPENHAB_ENVIRONMENT_VARIABLES+=("GROUP_ID=$SERVICE_USER_GID")
ENVIRONMENT_VARIABLES=${OPENHAB_ENVIRONMENT_VARIABLES[@]}

create_service
# sudo ln -s /lib/systemd/system/openhab.service /etc/systemd/system/openhab.service

# install Sepia
SERVICE_NAME=$SEPIA_SERVICE_NAME
SERVICE_DESCRIPTION=$SEPIA_SERVICE_DESCRIPTION
SERVICE_USER=$SEPIA_SERVICE_USER
SERVICE_PORTS=${SEPIA_PORTS[@]}
VOLUME_NAMES=${SEPIA_VOLUME_NAMES[@]}
VOLUME_PATHS=${SEPIA_VOLUME_PATHS[@]}
SERVICE_DEVICES=${SEPIA_DEVICES[@]}
IMAGE=$SEPIA_IMAGE

sudo bash -c 'echo "vm.max_map_count=262144" >> /etc/sysctl.conf'

echo -en "\033[0;96mCreating $SERVICE_USER: $NC"
sudo useradd -r -s /sbin/nologin $SERVICE_USER 1> /dev/null
sudo usermod -a -G $SERVICE_USER $SERVICE_USER 1> /dev/null
echo -e "\033[1;92mComplete!$NC"
SERVICE_USER_UID=$(id -u $SERVICE_USER)
SERVICE_USER_GID=$(id -g $SERVICE_USER)

SEPIA_ENVIRONMENT_VARIABLES+=("USER_ID=$SERVICE_USER_UID")
SEPIA_ENVIRONMENT_VARIABLES+=("GROUP_ID=$SERVICE_USER_GID")
ENVIRONMENT_VARIABLES=${SEPIA_ENVIRONMENT_VARIABLES[@]}

create_service
# sudo ln -s /lib/systemd/system/sepia.service /etc/systemd/system/sepia.service

# install Sepia-STT
SERVICE_NAME=$SEPIA_STT_SERVICE_NAME
SERVICE_DESCRIPTION=$SEPIA_STT_SERVICE_DESCRIPTION
SERVICE_USER=$SEPIA_STT_SERVICE_USER
SERVICE_PORTS=${SEPIA_STT_PORTS[@]}
VOLUME_NAMES=${SEPIA_STT_VOLUME_NAMES[@]}
VOLUME_PATHS=${SEPIA_STT_VOLUME_PATHS[@]}
SERVICE_DEVICES=${SEPIA_STT_DEVICES[@]}
IMAGE=$SEPIA_STT_IMAGE

SEPIA_STT_ENVIRONMENT_VARIABLES+=("USER_ID=$SERVICE_USER_UID")
SEPIA_STT_ENVIRONMENT_VARIABLES+=("GROUP_ID=$SERVICE_USER_GID")
ENVIRONMENT_VARIABLES=${SEPIA_STT_ENVIRONMENT_VARIABLES[@]}

create_service
# sudo ln -s /lib/systemd/system/sepia-stt.service /etc/systemd/system/sepia-stt.service

# setup Mosquitto for MQTT broker for zigbee
SERVICE_NAME=$MOSQUITTO_SERVICE_NAME
SERVICE_DESCRIPTION=$MOSQUITTO_SERVICE_DESCRIPTION
SERVICE_USER=$MOSQUITTO_SERVICE_USER
SERVICE_PORTS=${MOSQUITTO_PORTS[@]}
VOLUME_NAMES=${MOSQUITTO_VOLUME_NAMES[@]}
VOLUME_PATHS=${MOSQUITTO_VOLUME_PATHS[@]}
SERVICE_DEVICES=${MOSQUITTO_DEVICES[@]}
IMAGE=$MOSQUITTO_IMAGE

# get current user id and group id's for service creation
echo -en "\033[0;96mCreating $SERVICE_USER: $NC"
sudo useradd -r -s /sbin/nologin $SERVICE_USER 1> /dev/null
sudo usermod -a -G $SERVICE_USER $SERVICE_USER 1> /dev/null
echo -e "\033[1;92mComplete!$NC"
SERVICE_USER_UID=$(id -u $SERVICE_USER)
SERVICE_USER_GID=$(id -g $SERVICE_USER)

MOSQUITTO_ENVIRONMENT_VARIABLES+=("USER_ID=$SERVICE_USER_UID")
MOSQUITTO_ENVIRONMENT_VARIABLES+=("GROUP_ID=$SERVICE_USER_GID")
ENVIRONMENT_VARIABLES=${MOSQUITTO_ENVIRONMENT_VARIABLES[@]}

create_service
# sudo ln -s /lib/systemd/system/mosquitto.service /etc/systemd/system/mosquitto.service

# create zigbee2mqtt broker
SERVICE_NAME=$ZIGBEE2MQTT_SERVICE_NAME
SERVICE_DESCRIPTION=$ZIGBEE2MQTT_SERVICE_DESCRIPTION
SERVICE_USER=$ZIGBEE2MQTT_SERVICE_USER
SERVICE_PORTS=${ZIGBEE2MQTT_PORTS[@]}
VOLUME_NAMES=${ZIGBEE2MQTT_VOLUME_NAMES[@]}
VOLUME_PATHS=${ZIGBEE2MQTT_VOLUME_PATHS[@]}
DEVICES=${ZIGBEE2MQTT_DEVICES[@]}
IMAGE=$ZIGBEE2MQTT_IMAGE

ZIGBEE2MQTT_ENVIRONMENT_VARIABLES+=("USER_ID=$SERVICE_USER_UID")
ZIGBEE2MQTT_ENVIRONMENT_VARIABLES+=("GROUP_ID=$SERVICE_USER_GID")
ENVIRONMENT_VARIABLES=${ZIGBEE2MQTT_ENVIRONMENT_VARIABLES[@]}

create_service
# sudo ln -s /lib/systemd/system/zigbee2mqtt.service /etc/systemd/system/zigbee2mqtt.service

# enabling all new services
sudo systemctl daemon-reload 1> /dev/null
sudo systemctl enable portainer.service 1> /dev/null
sudo systemctl enable deconz.service 1> /dev/null
sudo systemctl enable openhab.service 1> /dev/null
sudo systemctl enable sepia.service 1> /dev/null
sudo systemctl enable sepia-stt.service 1> /dev/null
sudo systemctl enable mosquitto.service 1> /dev/null
sudo systemctl enable zigbee2mqtt.service 1> /dev/null

echo -e "\033[0;93mPortainer is running on port(s): \033[1;31m${PORTAINER_PORTS[*]}"
echo -e "\033[0;93mDeCONZ is running on port(s): \033[1;31m${DECONZ_PORTS[*]}"
echo -e "\033[0;93mOpenHAB is running on port(s): \033[1;31m${OPENHAB_PORTS[*]}"
echo -e "\033[0;93mSEPIA Home is running on port(s): \033[1;31m${SEPIA_PORTS[*]}"
echo -e "\033[0;93mSEPIA-STT Home is running on port(s): \033[1;31m${SEPIA_STT_PORTS[*]}"
echo -e "\033[0;93mEclipse Mosquitto is running on port(s): \033[1;31m${MOSQUITTO_PORTS[*]}"
echo -e "\033[0;93mZigbee2MQTT is running on port(s): \033[1;31m${ZIGBEE2MQTT_PORTS[*]}$NC"

# set hostname
read -p "Enter this Pi's hostname:" NEWHOSTNAME
sudo sed -i -e "s/$HOSTNAME/$NEWHOSTNAME/g" /etc/hosts &> /dev/null
sudo sed -i -e "s/$HOSTNAME/$NEWHOSTNAME/g" /etc/hostname &> /dev/null
#sudo hostname $NEWHOSTNAME

# complete and reboot
echo Setup is complete.
read -p "Reboot system? [Y/n] " REBOOT_COMMAND
if [ $REBOOT_COMMAND = "Y" ] || [ $REBOOT_COMMAND = "y" ]
then
    sudo reboot &> /dev/null
fi
