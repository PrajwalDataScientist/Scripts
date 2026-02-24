#!/bin/bash
set -e

echo "Updating system..."
sudo apt update -y

echo "Installing Java (required for Maven)..."
sudo apt install openjdk-17-jdk -y

echo "Installing Maven..."
sudo apt install maven -y

echo "Verifying Installation..."
mvn -version

echo "---------------------------------"
echo "Maven Installed Successfully ✅"
echo "---------------------------------"
