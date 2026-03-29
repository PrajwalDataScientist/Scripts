#!/bin/bash

# --- 1. Variables ---
TOMCAT_VERSION="11.0.20"
TOMCAT_URL="https://dlcdn.apache.org/tomcat/tomcat-11/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz"
INSTALL_DIR="/opt/tomcat"

# --- 2. Update & Install Java ---
echo "Updating system and installing OpenJDK 21..."
sudo apt update -y
sudo apt install openjdk-21-jdk-headless -y

# --- 3. Create Tomcat User ---
echo "Creating dedicated tomcat user..."
# Create a system group and user with no login shell for security
sudo groupadd --system tomcat
sudo useradd -s /bin/false -g tomcat -d $INSTALL_DIR --system tomcat

# --- 4. Download and Extract ---
echo "Downloading Tomcat ${TOMCAT_VERSION}..."
cd /tmp
wget -q --show-progress $TOMCAT_URL

echo "Extracting to ${INSTALL_DIR}..."
sudo mkdir -p $INSTALL_DIR
sudo tar -xzf apache-tomcat-${TOMCAT_VERSION}.tar.gz -C $INSTALL_DIR --strip-components=1

# --- 5. Permissions ---
echo "Setting permissions..."
cd $INSTALL_DIR
sudo chgrp -R tomcat $INSTALL_DIR
sudo chmod -R g+r conf
sudo chmod g+x conf
sudo chown -R tomcat webapps/ work/ temp/ logs/
sudo chmod +x bin/*.sh

# --- 6. Create Systemd Service ---
echo "Configuring systemd service..."
JAVA_PATH=$(readlink -f $(which java) | sed "s:bin/java::")

sudo bash -c "cat <<EOF > /etc/systemd/system/tomcat.service
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

User=tomcat
Group=tomcat

Environment=\"JAVA_HOME=$JAVA_PATH\"
Environment=\"CATALINA_PID=$INSTALL_DIR/temp/tomcat.pid\"
Environment=\"CATALINA_HOME=$INSTALL_DIR\"
Environment=\"CATALINA_BASE=$INSTALL_DIR\"
Environment=\"CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseG1GC\"

ExecStart=$INSTALL_DIR/bin/startup.sh
ExecStop=$INSTALL_DIR/bin/shutdown.sh

RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
EOF"

# --- 7. Configure Admin User (Optional but Recommended) ---
echo "Adding admin user to tomcat-users.xml..."
sudo sed -i '/<\/tomcat-users>/i \
<role rolename="manager-gui"/> \
<role rolename="admin-gui"/> \
<user username="admin" password="Password123" roles="manager-gui,admin-gui"/>' $INSTALL_DIR/conf/tomcat-users.xml

# --- 8. Disable Remote IP Restrictions for Manager App ---
# This allows you to access the Manager GUI from outside localhost
sudo sed -i '/<Valve/,/\/>/d' $INSTALL_DIR/webapps/manager/META-INF/context.xml
sudo sed -i '/<Valve/,/\/>/d' $INSTALL_DIR/webapps/host-manager/META-INF/context.xml

# --- 9. Start Service ---
echo "Starting Tomcat..."
sudo systemctl daemon-reload
sudo systemctl start tomcat
sudo systemctl enable tomcat

# --- 10. Summary ---
echo "----------------------------------------------------"
echo "Tomcat ${TOMCAT_VERSION} Installation Complete!"
echo "URL: http://$(curl -s ifconfig.me):8080"
echo "Admin Username: admin"
echo "Admin Password: Password123"
echo "----------------------------------------------------"
