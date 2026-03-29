#!/bin/bash

# --- 1. Variables ---
# Using a specific stable version for consistency
NEXUS_VERSION="3.65.0-02"
NEXUS_URL="https://download.sonatype.com/nexus/3/nexus-${NEXUS_VERSION}-unix.tar.gz"
INSTALL_DIR="/opt"

# --- 2. Clean Existing Setup (Fresh Start) ---
echo "Cleaning up previous attempts..."
sudo systemctl stop nexus 2>/dev/null
sudo rm -rf ${INSTALL_DIR}/nexus* ${INSTALL_DIR}/sonatype-work
if id "nexus" &>/dev/null; then
    sudo userdel -r nexus 2>/dev/null
fi

# --- 3. Install Java 8 (Required for Nexus 3.x) ---
echo "Installing OpenJDK 8..."
sudo apt update -y
sudo apt install openjdk-8-jre-headless -y

# --- 4. Download and Extract ---
echo "Downloading Nexus ${NEXUS_VERSION}..."
cd $INSTALL_DIR
sudo wget -q --show-progress $NEXUS_URL

if [ ! -f "nexus-${NEXUS_VERSION}-unix.tar.gz" ]; then
    echo "ERROR: Download failed. Check internet connection."
    exit 1
fi

echo "Extracting files..."
sudo tar -xzf nexus-${NEXUS_VERSION}-unix.tar.gz
sudo mv ${INSTALL_DIR}/nexus-${NEXUS_VERSION} ${INSTALL_DIR}/nexus
sudo rm nexus-${NEXUS_VERSION}-unix.tar.gz

# --- 5. User & Permissions ---
echo "Creating nexus user and setting permissions..."
sudo useradd -d /opt/nexus -s /bin/bash nexus
sudo echo "nexus ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/nexus > /dev/null
sudo chown -R nexus:nexus ${INSTALL_DIR}/nexus
sudo chown -R nexus:nexus ${INSTALL_DIR}/sonatype-work

# --- 6. Configure Run-As User ---
echo "Configuring nexus.rc..."
echo 'run_as_user="nexus"' | sudo tee ${INSTALL_DIR}/nexus/bin/nexus.rc > /dev/null

# --- 7. Create Systemd Service (Modern approach) ---
echo "Creating systemd service file..."
sudo bash -c 'cat <<EOF > /etc/systemd/system/nexus.service
[Unit]
Description=nexus service
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/bin/nexus start
ExecStop=/opt/nexus/bin/nexus stop
User=nexus
Restart=on-abort
TimeoutSec=600

[Install]
WantedBy=multi-user.target
EOF'

# --- 8. Start Nexus ---
echo "Starting Nexus..."
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus

# --- 9. Final Output ---
echo "----------------------------------------------------"
echo "Nexus Installation Complete!"
echo "Status: Check with 'sudo systemctl status nexus'"
echo "URL: http://$(curl -s ifconfig.me):8081"
echo "----------------------------------------------------"
echo "NOTE: It takes 2-3 minutes for the UI to load."
echo "Initial Admin Password Location:"
echo "cat /opt/sonatype-work/nexus3/admin.password"
echo "----------------------------------------------------"
