# Process to setup Zigbee2MQTT with Aeotec Zi-Stick:

Buy the Zi-Stick first.

Setup your service to look like the following.  This basically turns a container launch into a service that starts on boot.

Setup the configuration script like so:

### /lib/systemd/system/zigbee2mqtt.service file
    [Unit]
    Description=Zigbee2MQTT Broker
    Requires=docker.service
    After=docker.service
    [Service]
    Restart=always
    ExecStart=/usr/bin/docker run --rm --name=%n \
      -p 8008:8080 \
      -v zigbee2mqtt-app-data:/app/data \
      -v /run/udev:/run/udev:ro \
      --user 992:988 \
      --group-add dialout \
      -e TZ=America/Chicago \
      --device=/dev/zigbee2:/dev/zigbee \
      koenkk/zigbee2mqtt:latest
    ExecStop=/usr/bin/docker stop -t 2 %n ; /usr/bin/docker rm -f %n

    [Install]
    WantedBy=multi-user.target

Pay special attention to the --device switch.  Specify the zigbee serial device to be passed through in the format of [`code`](--device=/dev/<source_host_device>:/dev/<target_container_device>).
It is best to configure an alias for ease of readablility in the UDEV rules.  An example file (/etc/udev/rules.d/99-usb-serial.rules) would look like this:

    SUBSYSTEM=="tty", ATTRS{idVendor}=="1cf1", ATTRS{idProduct}=="0030", ATTRS{serial}=="DE2469919", SYMLINK+="zigbee"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="0658", ATTRS{idProduct}=="0200", SYMLINK+="zwave"
    SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", SYMLINK+="zigbee2"

In the example UDEV rules file above, /dev/zigbee2 is being assigned to the device with a Vendor ID of 1a86 and a Product ID of 7523.  Those should be the Vendor and Product IDs of the Aeotec Zi-Stick, but always check with lsusb.  lsusb can be used with the -v switch to reveal the idVendor and idProduct values to put in the attribute fields above.  This will basically create a symlink for /dev/zigbee2 to point to the associated device in the OS.  Additionally, make note of the target container device that is referencing the source host device in the [`code`](--device=/dev/<source_host_device>:/dev/<target_container_device>) switch in the service script.  This is required for the configuration.yaml file described below.

Also pay special attention to the volume for [`code`](/app/data).  In the example above the volume zigbe2mqtt-app-data was created in docker ahead of time.  This will FAIL to create the configuration.yaml file on initial run due to the fact that when a container is run, precreated volumes are repermissioned to only allow root to access them.  Thus, zigbee2mqtt will not start.  Instead, hard wire the path of the volume into the [`code`](-v switch) on your service.  Make it look like this:

Change the service to look like this for the initial configuration

### /lib/systemd/system/zigbee2mqtt.service file
    [Unit]
    Description=Zigbee2MQTT Broker
    Requires=docker.service
    After=docker.service
    [Service]
    Restart=always
    ExecStart=/usr/bin/docker run --rm --name=%n \
      -p 8008:8080 \
      -v /opt/zigbee2mqtt/data:/app/data \
      -v /run/udev:/run/udev:ro \
      --user 992:988 \
      --group-add dialout \
      -e TZ=America/Chicago \
      --device=/dev/zigbee2:/dev/zigbee \
      koenkk/zigbee2mqtt:latest
    ExecStop=/usr/bin/docker stop -t 2 %n ; /usr/bin/docker rm -f %n

    [Install]
    WantedBy=multi-user.target

Lastly on the service script, be aware that zigbee2mqtt expects to run on port 8080.  If passing the default openhab port (8080) to the openhab port of 8080, this port cannot be passed through to the Zigbee2MQTT container.  Instead, pass a different port through.  In the example script above, the host port 8008 is being passed through to container port 8080.
 
Next, for the Aeotec Zi-Stick, configuration.yaml file to change the serial port to match the passthrough device that is configured in service script, add an adapter statement to enable experimental support for the Zi-Stick, and set the baud rate and flow control for the serial connection.  Additionally it's might be a good idea to go ahead and configure the connection settings for the MQTT Broker while editing this file.  For the scenario below, the broker in question Mosquitto, and it is also running in a Docker container as a system service.  Add/change only the following lines in the configuration.yaml file.  Leave everything else as is unless there is an intention to use TLS for broker connections.  If TLS is to be enabled additional certificate
configureation is required in this file (not described in this document).

### Zigbee2MQTT configuration.yaml file
    mqtt:
      base_topic: zigbee2mqtt
      user: <broker_user_account>
      password: <broker_user_password>
      server: mqtt://<name_of_raspberrypi_or_external_broker>:1883
    serial:
      adapter: ezsp
      port: /dev/zigbee
      baudrate: 115200
      rtscts: false

Notice how the port is set to the same [`code`](</dev/target_container_device>) mentioned above in the service script.

# Process for setting Mosquitto MQTT broker

Setup the configuration script like so:

### /lib/systemd/system/mosquitto.service file
    [Unit]
    Description=Eclipse Mosquitto
    Requires=docker.service
    After=docker.service
    [Service]
    Restart=always
    ExecStart=/usr/bin/docker run --rm --name=%n \
      -p 1883:1883 \
      -p 9001:9001 \
      -v mosquitto-config:/mosquitto/config \
      -v mosquitto-data:/mosquitto/data \
      -v mosquitto-log:/mosquitto/log \
      -v /etc/timezone:/etc/timezone:ro \
      -v /etc/localtime:/etc/localtime:ro \
      -e USER_ID=992 \
      -e GROUP_ID=988 \
    eclipse-mosquitto:latest
    ExecStop=/usr/bin/docker stop -t 2 %n ; /usr/bin/docker rm -f %n

    [Install]
    WantedBy=multi-user.target

Notice that 2 ports are being passed through.  Port 1883 is the default port for MQTT brokers to queue messages.  Interestingly, the user running the service inside the container has a user ID of 1883.  This is probably intentional.

After initial startup, configuration files will be placed into the mosquitto-config volume.  Edit the mosquitto.conf file in this directory to turn on a listener on port 1883, block anonymous access, and specify a password file location for authenticated connections (this is the file that contains the user information to be input into the Zigbee2MQTT configuration.yaml file described above).  Find and modify/uncomment the following lines:

### Mosquitto mosquitto.conf file
    listener 1883 0.0.0.0
    allow_anonymous false
    password_file /mosquitto/config/passwd

Start the mosquitto service.  Connect to the console of the container in portainer using /bin/sh as the shell or connect through the CLI using the docker command (portainer is easier and actually connected) and use the following command to create a user account that can be used to authenticate connections to the broker:

    # login interactively into the mqtt container
    sudo docker exec -it <container-id> sh

    # add user and it will prompt for password
    mosquitto_passwd -c /mosquitto/config/pwfile user1

A decent Mosquitto docker walk-through can be found here
https://github.com/sukesh-ak/setup-mosquitto-with-docker

and here
https://cedalo.com/blog/mosquitto-docker-configuration-ultimate-guide/

Put the login information created in the previous step into the zigbee2mqtt's configuration.yaml previously discussed in this article.