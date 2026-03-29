#!/bin/bash
set -e

echo "🔄 Updating system..."
sudo apt update -y

echo "☕ Installing Java..."
sudo apt install -y openjdk-17-jdk unzip wget

echo "🧹 Cleaning old install..."
sudo systemctl stop sonarqube || true
sudo rm -rf /opt/sonarqube*

echo "👤 Fixing sonar user..."
sudo userdel -r sonar || true
sudo useradd -m -d /opt/sonar -s /bin/bash sonar

echo "📥 Downloading SonarQube..."
cd /opt
wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-10.5.1.90531.zip

echo "📦 Extracting..."
unzip sonarqube-10.5.1.90531.zip
mv sonarqube-10.5.1.90531 sonarqube

echo "🔐 Setting permissions..."
sudo chown -R sonar:sonar /opt/sonarqube

echo "⚙️ Configure sonar user..."
sudo sed -i 's/#RUN_AS_USER=/RUN_AS_USER=sonar/' /opt/sonarqube/bin/linux-x86-64/sonar.sh

echo "🛠️ Creating service..."
sudo tee /etc/systemd/system/sonarqube.service > /dev/null <<EOF
[Unit]
Description=SonarQube
After=network.target

[Service]
Type=forking
User=sonar
Group=sonar
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "🔄 Reload systemd..."
sudo systemctl daemon-reload

echo "🚀 Start SonarQube..."
sudo systemctl enable sonarqube
sudo systemctl start sonarqube

echo "📊 Status:"
sudo systemctl status sonarqube --no-pager

echo "✅ Done: http://<IP>:9000"
