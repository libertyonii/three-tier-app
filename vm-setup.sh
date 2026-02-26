#!/bin/bash
# ══════════════════════════════════════════════════════════════════════════════
#  vm-setup.sh – One-time Linux VM provisioning script
#  Run this ONCE on your fresh Ubuntu/Debian VM to get everything ready.
#  Usage: curl -fsSL <raw-url> | bash
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

echo "==> Updating system packages..."
sudo apt-get update -y && sudo apt-get upgrade -y

echo "==> Installing prerequisites..."
sudo apt-get install -y ca-certificates curl gnupg git ufw

echo "==> Installing Docker Engine..."
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
                        docker-buildx-plugin docker-compose-plugin

echo "==> Enabling Docker..."
sudo systemctl enable --now docker

echo "==> Adding $USER to docker group..."
sudo usermod -aG docker "$USER"

echo "==> Configuring UFW firewall..."
sudo ufw allow 22/tcp comment "SSH"
sudo ufw allow 80/tcp comment "HTTP"
sudo ufw allow 443/tcp comment "HTTPS"
sudo ufw --force enable

echo "==> Creating app directory..."
mkdir -p ~/three-tier-app
cd ~/three-tier-app

echo ""
echo "╔══════════════════════════════════════════════════════════╗"
echo "║   VM setup complete!  Next steps:                       ║"
echo "║                                                          ║"
echo "║   1. Copy docker-compose.yml to ~/three-tier-app/       ║"
echo "║   2. Create .env from .env.example                      ║"
echo "║   3. Run:  docker compose up -d                         ║"
echo "║   4. App will be on  http://<VM-IP>                     ║"
echo "╚══════════════════════════════════════════════════════════╝"
