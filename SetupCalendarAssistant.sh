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
PORTAINER_LABELS=()
PORTAINER_DEVICES=()
PORTAINER_COMMANDS=()

# deCONZ config

# OpenHAB config

# SEPIA config
SEPIA_IMAGE="sepia/home:latest"
SEPIA_SERVICE_NAME=sepia
SEPIA_SERVICE_DESCRIPTION="SEPIA Home"
SEPIA_SERVICE_USER=sepia
SEPIA_PORTS=(20741)
SEPIA_VOLUME_NAMES=("sepia-home-data:/home/admin/sepia-home-data" "/etc/timezone:/etc/timezone:ro" "/etc/localtime:/etc/localtime:ro")
SEPIA_VOLUME_PATHS=("/opt/sepia")
SEPIA_ENVIRONMENT_VARIABLES=()
SEPIA_LABELS=()
SEPIA_DEVICES=()
SEPIA_COMMANDS=()

# SEPIA-STT config
SEPIA_STT_IMAGE="sepia/stt-server:vosk_aarch64"
SEPIA_STT_SERVICE_NAME=sepia-stt
SEPIA_STT_SERVICE_DESCRIPTION="SEPIA Speech-To-Text"
SEPIA_STT_SERVICE_USER=sepia
SEPIA_STT_PORTS=(20741)
SEPIA_STT_VOLUME_NAMES=("/etc/timezone:/etc/timezone:ro" "/etc/localtime:/etc/localtime:ro")
SEPIA_STT_VOLUME_PATHS=()
SEPIA_STT_ENVIRONMENT_VARIABLES=()
SEPIA_STT_LABELS=()
SEPIA_STT_DEVICES=()
SEPIA_STT_COMMANDS=()

# Mosquitto config

# Zigbee2MQTT config

# OpenHAB Cloud config

# mongodb config

# Redis config

# traefik config

# Other variables
NC='\033[0m' # No Color

# Function that creates the services
function create_service () {
PORTS=""
for i in ${SERVICE_PORTS[@]}; do PORTS+="  -p ${i}:${i} \\\\\n";done
PORTS=${PORTS%\\\n}

VOLUMES=""
for i in ${VOLUME_NAMES[@]}
do 
  if [[ ${i} == *":"* ]]
  then
    VOLUMES+="  -v ${i} \\\\\n"
  fi
done
VOLUMES=${VOLUMES%\\\n}

ENV_VARS=""
for i in ${ENVIRONMENT_VARIABLES[@]}; do ENV_VARS+="  -e ${i} \\\\\n";done
ENV_VARS=${ENV_VARS%\\\n}

LABELS=""
for i in ${SERVICE_LABELS[@]}; do LABELS+="  -l ${i} \\\\\n";done
LABELS=${LABELS%\\\n}

DEVICES=""
for i in ${SERVICE_DEVICES[@]}; do DEVICES+="  --device=${i} \\\\\n";done
DEVICES=${DEVICES%\\\n}

COMMANDS=""
for i in ${SERVICE_COMMANDS[@]}; do COMMANDS+=" ${i}";done

echo -en "\033[0;96mCreating shared folders: $NC"
COUNTER=0
for i in ${VOLUME_PATHS[@]}
do
  sudo mkdir -p ${i} 1> /dev/null
  sudo chown -R $SERVICE_USER:$SERVICE_USER ${i} 1> /dev/null
  if [[ ${i} == *"/opt/"* ]] && [[ ${VOLUME_NAMES[COUNTER]} == *":"* ]]
  then
    VOL=(${VOLUME_NAMES[$COUNTER]//:/ })
    if [[ ${VOL[0]} != *"/"* ]]
    then
      # the command below for some reason does not create any of the volumes with the options shown below.  I've run out of time and need to look at this later.
      sudo docker volume create --opt type=none --opt device=${i} --opt o=bind ${VOL[0]} 1> /dev/null
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
EOT
rm ./temp.service
echo -e "Requires=docker.service" >> ./temp.service
echo -e "After=docker.service" >> ./temp.service

sudo bash -c "cat ./temp.service >> /lib/systemd/system/$SERVICE_NAME.service"
sudo tee -a /lib/systemd/system/$SERVICE_NAME.service > /dev/null <<EOT
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
if [[ ! -z "$LABELS" ]]
then
  echo -e "$LABELS" >> ./temp.service
fi
if [[ ! -z "$DEVICES" ]]
then
  echo -e "$DEVICES" >> ./temp.service
fi
sudo bash -c "cat ./temp.service >> /lib/systemd/system/$SERVICE_NAME.service"
sudo tee -a /lib/systemd/system/$SERVICE_NAME.service > /dev/null <<EOT
  $IMAGE$COMMANDS
ExecStop=/usr/bin/docker stop -t 2 %n ; /usr/bin/docker rm -f %n

[Install]
WantedBy=multi-user.target
EOT
sudo systemctl daemon-reload 1> /dev/null
sudo systemctl enable $SERVICE_NAME 1> /dev/null

echo -e "\033[1;92mComplete!$NC"
}

# install basics
echo -en "\033[0;96mInstalling base software and configuring calendar: $NC"
sudo apt -y install vim chromium-browser docker.io &> /dev/null
sudo usermod -a -G docker $USER 1> /dev/null

# setup calendar function
tar -xzf xorg.pi.config.tgz 1> /dev/null
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

echo -e "\033[0;96mSetting up container services.  \033[0;5;33mTHIS WILL TAKE A FEW MINUTES. $NC"

# install docker and portainer
SERVICE_NAME=$PORTAINER_SERVICE_NAME
SERVICE_DESCRIPTION=$PORTAINER_SERVICE_DESCRIPTION
SERVICE_USER=$PORTAINER_SERVICE_USER
SERVICE_PORTS=(${PORTAINER_PORTS[@]})
VOLUME_NAMES=(${PORTAINER_VOLUME_NAMES[@]})
VOLUME_PATHS=(${PORTAINER_VOLUME_PATHS[@]})
SERVICE_LABELS=(${PORTAINER_CLOUD_LABELS[@]})
SERVICE_DEVICES=(${PORTAINER_DEVICES[@]})
IMAGE=$PORTAINER_IMAGE
SERVICE_COMMANDS=(${PORTAINER_COMMANDS[@]})

echo -en "\033[0;96mCreating $SERVICE_USER: $NC"
sudo useradd -r -s /sbin/nologin $SERVICE_USER 1> /dev/null
sudo usermod -a -G $SERVICE_USER $SERVICE_USER 1> /dev/null
echo -e "\033[1;92mComplete!$NC"
SERVICE_USER_UID=$(id -u $SERVICE_USER)
SERVICE_USER_GID=$(id -g $SERVICE_USER)

PORTAINER_ENVIRONMENT_VARIABLES+=("USER_ID=$SERVICE_USER_UID")
PORTAINER_ENVIRONMENT_VARIABLES+=("GROUP_ID=$SERVICE_USER_GID")
ENVIRONMENT_VARIABLES=(${PORTAINER_ENVIRONMENT_VARIABLES[@]})

create_service
# sudo ln -s /lib/systemd/system/portainer.service /etc/systemd/system/portainer.service


# install Sepia
SERVICE_NAME=$SEPIA_SERVICE_NAME
SERVICE_DESCRIPTION=$SEPIA_SERVICE_DESCRIPTION
SERVICE_USER=$SEPIA_SERVICE_USER
SERVICE_PORTS=(${SEPIA_PORTS[@]})
VOLUME_NAMES=(${SEPIA_VOLUME_NAMES[@]})
VOLUME_PATHS=(${SEPIA_VOLUME_PATHS[@]})
SERVICE_LABELS=(${SEPIA_LABELS[@]})
SERVICE_DEVICES=(${SEPIA_DEVICES[@]})
IMAGE=$SEPIA_IMAGE
SERVICE_COMMANDS=(${SEPIA_COMMANDS[@]})

MAX_MAP_COUNT_DEFINED=$(grep 'vm.max_map_count=262144' /etc/sysctl.conf)
if [[ -z ${MAX_MAP_COUNT_DEFINED} ]]
then
  sudo bash -c 'echo "vm.max_map_count=262144" >> /etc/sysctl.conf'
fi

echo -en "\033[0;96mCreating $SERVICE_USER: $NC"
sudo useradd -r -s /sbin/nologin $SERVICE_USER 1> /dev/null
sudo usermod -a -G $SERVICE_USER $SERVICE_USER 1> /dev/null
echo -e "\033[1;92mComplete!$NC"
SERVICE_USER_UID=$(id -u $SERVICE_USER)
SERVICE_USER_GID=$(id -g $SERVICE_USER)

SEPIA_ENVIRONMENT_VARIABLES+=("USER_ID=$SERVICE_USER_UID")
SEPIA_ENVIRONMENT_VARIABLES+=("GROUP_ID=$SERVICE_USER_GID")
ENVIRONMENT_VARIABLES=(${SEPIA_ENVIRONMENT_VARIABLES[@]})

create_service
# sudo ln -s /lib/systemd/system/sepia.service /etc/systemd/system/sepia.service

# install Sepia-STT
SERVICE_NAME=$SEPIA_STT_SERVICE_NAME
SERVICE_DESCRIPTION=$SEPIA_STT_SERVICE_DESCRIPTION
SERVICE_USER=$SEPIA_STT_SERVICE_USER
SERVICE_PORTS=(${SEPIA_STT_PORTS[@]})
VOLUME_NAMES=(${SEPIA_STT_VOLUME_NAMES[@]})
VOLUME_PATHS=(${SEPIA_STT_VOLUME_PATHS[@]})
SERVICE_LABELS=(${SEPIA_STT_LABELS[@]})
SERVICE_DEVICES=(${SEPIA_STT_DEVICES[@]})
IMAGE=$SEPIA_STT_IMAGE
SERVICE_COMMANDS=(${SEPIA_STT_COMMANDS[@]})

SEPIA_STT_ENVIRONMENT_VARIABLES+=("USER_ID=$SERVICE_USER_UID")
SEPIA_STT_ENVIRONMENT_VARIABLES+=("GROUP_ID=$SERVICE_USER_GID")
ENVIRONMENT_VARIABLES=(${SEPIA_STT_ENVIRONMENT_VARIABLES[@]})

create_service
# sudo ln -s /lib/systemd/system/sepia-stt.service /etc/systemd/system/sepia-stt.service

# enabling all new services

echo -e "\033[0;93mPortainer is running on port(s): \033[1;31m${PORTAINER_PORTS[*]}"
echo -e "\033[0;93mSEPIA Home is running on port(s): \033[1;31m${SEPIA_PORTS[*]}"
echo -e "\033[0;93mSEPIA-STT Home is running on port(s): \033[1;31m${SEPIA_STT_PORTS[*]}"

# set hostname
#read -p "Enter this Pi's hostname:" NEWHOSTNAME
#sudo sed -i -e "s/$HOSTNAME/$NEWHOSTNAME/g" /etc/hosts &> /dev/null
#sudo sed -i -e "s/$HOSTNAME/$NEWHOSTNAME/g" /etc/hostname &> /dev/null
#sudo hostname $NEWHOSTNAME

echo -en "\033[0;96mCreating power-saving cron jobs: "
{ sudo crontab -l -u root 2> /dev/null; echo '0 23 * * * root vcgencmd display_power 0'; } | sudo crontab -u root -
{ sudo crontab -l -u root 2> /dev/null; echo '0 6 * * * root vcgencmd display_power 1'; } | sudo crontab -u root -
echo -e "\033[1;92mComplete!$NC"

# complete and reboot
echo Setup is complete.
read -p "Reboot system? [Y/n] " REBOOT_COMMAND
if [ $REBOOT_COMMAND == "Y" ] || [ $REBOOT_COMMAND == "y" ]
then
    sudo reboot &> /dev/null
fi