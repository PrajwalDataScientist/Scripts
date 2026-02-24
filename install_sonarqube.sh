#!/bin/bash

set -e

echo "Updating system..."
sudo apt update -y

echo "Installing Java 17..."
sudo apt install openjdk-17-jdk -y

echo "Installing required packages..."
sudo apt install wget unzip -y

echo "Installing PostgreSQL..."
sudo apt install postgresql postgresql-contrib -y

echo "Starting PostgreSQL..."
sudo systemctl enable postgresql
sudo systemctl start postgresql

echo "Creating SonarQube database and user..."
sudo -u postgres psql <<EOF
DROP DATABASE IF EXISTS sonarqube;
DROP USER IF EXISTS sonar;
CREATE USER sonar WITH ENCRYPTED PASSWORD 'StrongPassword@123';
CREATE DATABASE sonarqube OWNER sonar;
\c sonarqube
GRANT ALL ON SCHEMA public TO sonar;
ALTER SCHEMA public OWNER TO sonar;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO sonar;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO sonar;
EOF

echo "Configuring system limits..."
sudo bash -c 'echo "vm.max_map_count=262144" >> /etc/sysctl.conf'
sudo bash -c 'echo "fs.file-max=65536" >> /etc/sysctl.conf'
sudo sysctl -p

echo "Downloading SonarQube..."
cd /opt
sudo rm -rf sonarqube*
sudo wget https://binaries.sonarsource.com/Distribution/sonarqube/sonarqube-9.9.6.92038.zip
sudo unzip sonarqube-9.9.6.92038.zip
sudo mv sonarqube-9.9.6.92038 sonarqube

echo "Creating sonar user..."
sudo groupadd sonar || true
sudo useradd -d /opt/sonarqube -g sonar sonar || true

echo "Setting permissions..."
sudo chown -R sonar:sonar /opt/sonarqube

echo "Configuring SonarQube database..."
sudo sed -i 's|#sonar.jdbc.username=.*|sonar.jdbc.username=sonar|' /opt/sonarqube/conf/sonar.properties
sudo sed -i 's|#sonar.jdbc.password=.*|sonar.jdbc.password=sonar|' /opt/sonarqube/conf/sonar.properties
sudo sed -i 's|#sonar.jdbc.url=.*|sonar.jdbc.url=jdbc:postgresql://localhost:5432/sonarqube|' /opt/sonarqube/conf/sonar.properties

sudo sed -i 's|sonar.jdbc.password=.*|sonar.jdbc.password=StrongPassword@123|' /opt/sonarqube/conf/sonar.properties

echo "Creating systemd service..."
sudo tee /etc/systemd/system/sonar.service > /dev/null <<EOF
[Unit]
Description=SonarQube service
After=network.target postgresql.service

[Service]
Type=forking
User=sonar
Group=sonar
ExecStart=/opt/sonarqube/bin/linux-x86-64/sonar.sh start
ExecStop=/opt/sonarqube/bin/linux-x86-64/sonar.sh stop
Restart=always
LimitNOFILE=65536
LimitNPROC=4096
TimeoutStartSec=5min

[Install]
WantedBy=multi-user.target
EOF

echo "Reloading systemd..."
sudo systemctl daemon-reload
sudo systemctl enable sonar

echo "Starting SonarQube..."
sudo systemctl start sonar

echo "Waiting for SonarQube to start..."
sleep 20

echo "------------------------------------------------"
echo "SonarQube should be accessible at:"
echo "http://YOUR_PUBLIC_IP:9000"
echo "Default Login -> admin / admin"
echo "------------------------------------------------"
