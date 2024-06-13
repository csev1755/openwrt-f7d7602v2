echo 20 > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio20/direction
value=$(cat /sys/class/gpio/gpio20/value)
if [ "$value" -eq 1 ]; then
    echo "Switch is on, resetting network config"
    cp /root/netconfig /etc/config/network
    cp /root/wificonfig /etc/config/wireless
fi
