#!/bin/bash

OCS_URL="https://github.com/OCSInventory-NG/UnixAgent/releases/download/v2.10.2-MAC/Ocsinventory-Unix-Agent-2.10.2-MAC.tar.gz"
OCS_TAR="Ocsinventory-Unix-Agent-2.10.2-MAC.tar.gz"
OCS_DIR="Ocsinventory-Unix-Agent-2.10.2-MAC"
OCS_SERVER_URL="http://192.168.2.169:6080/ocsinventory" 
echo "Téléchargement de l'archive de l'agent OCS Inventory..."
curl -L -o $OCS_TAR $OCS_URL
echo "Extraction de l'archive .tar.gz..."
tar -xvzf $OCS_TAR
cd $OCS_DIR/"Ocsinventory-Unix-Agent-2.10.2-MAC"
echo "Installation de l'agent OCS Inventory..."
sudo installer -pkg OCS Inventory Pkg Setup.pkg -target /
echo "Configuration de l'agent OCS Inventory pour le serveur OCS..."
CONFIG_FILE="/etc/ocsinventory/ocsinventory-agent.cfg"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Le fichier de configuration $CONFIG_FILE n'existe pas. Création..."
    sudo touch $CONFIG_FILE
fi

sudo bash -c "echo 'server=$OCS_SERVER_URL' >> $CONFIG_FILE"

echo "Nettoyage des fichiers téléchargés..."
cd ..
rm -rf $OCS_TAR $OCS_DIR

echo "Lancement de l'agent OCS Inventory pour la première synchronisation..."
sudo /usr/local/bin/ocsinventory-agent
