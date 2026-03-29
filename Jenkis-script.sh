#!/bin/bash

set -e

echo "=============================="
echo " Jenkins + Java Installer"
echo "=============================="

# Must be run as root
if [ "$EUID" -ne 0 ]; then
  echo "❌ Please run as root or use sudo"
  exit 1
fi

echo "▶ Updating system..."
apt update -y

echo "▶ Installing dependencies..."
apt install -y curl gnupg ca-certificates openjdk-17-jdk

echo "▶ Verifying Java installation..."
java -version

echo "▶ Cleaning old Jenkins repo and keys..."
rm -f /etc/apt/sources.list.d/jenkins.list
rm -f /usr/share/keyrings/jenkins-keyring.gpg
apt clean

echo "▶ Importing Jenkins GPG key (7198F4B714ABFC68)..."
gpg --keyserver keyserver.ubuntu.com --recv-keys 7198F4B714ABFC68

echo "▶ Exporting Jenkins key to APT keyring..."
gpg --export 7198F4B714ABFC68 \
  | tee /usr/share/keyrings/jenkins-keyring.gpg > /dev/null

echo "▶ Adding Jenkins repository..."
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.gpg] https://pkg.jenkins.io/debian-stable binary/" \
  | tee /etc/apt/sources.list.d/jenkins.list

echo "▶ Updating package list..."
apt update -y

echo "▶ Installing Jenkins..."
apt install -y jenkins

echo "▶ Enabling and starting Jenkins service..."
systemctl enable jenkins
systemctl start jenkins

echo "▶ Jenkins status:"
systemctl status jenkins --no-pager

echo "=============================="
echo " Jenkins installation complete"
echo "=============================="

echo "▶ Initial Admin Password:"
cat /var/lib/jenkins/secrets/initialAdminPassword
#sudo cat /var/lib/jenkins/secrets/initialAdminPassword
echo ""
echo "Access Jenkins at:"
echo "http://<SERVER_IP>:8080"
