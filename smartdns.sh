#!/bin/bash
set -x
exec > >(tee -a /tmp/smartdns.log) 2>&1
date +"=== Script started at %Y-%m-%d %H:%M:%S ==="

# Update system
apt update -y && apt upgrade -y

# Install required packages
apt install curl unzip git -y

# Install SmartDNS
cd /tmp
wget https://github.com/pymumu/smartdns/releases/latest/download/smartdns.ubuntu.x86_64.deb
dpkg -i smartdns.ubuntu.x86_64.deb

# Enable SmartDNS
systemctl enable smartdns
systemctl start smartdns

# Setup SmartDNS config
cat <<EOF > /etc/smartdns/smartdns.conf
bind :53
cache-size 512
server-name smartdns
log-level info
dual-stack-ip-selection yes
prefetch-domain yes
speed-check-mode ping,tcp:80
speed-check-interval 10

# Google and Cloudflare DNS
server 8.8.8.8
server 1.1.1.1

# Netflix US redirect (example)
server /netflix.com/US_PUBLIC_IP
server /nflxvideo.net/US_PUBLIC_IP

# Block local IP leakage (optional)
force-AAAA-response no
EOF

# Restart SmartDNS
systemctl restart smartdns

# Set system DNS to SmartDNS
echo "nameserver 127.0.0.1" > /etc/resolv.conf

# Make persistent on reboot
cat <<EOF > /etc/rc.local
#!/bin/bash
systemctl start smartdns
exit 0
EOF
chmod +x /etc/rc.local

echo "SmartDNS setup completed."
