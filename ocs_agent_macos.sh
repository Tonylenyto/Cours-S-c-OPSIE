#!/bin/bash

# Variables
OCS_SERVER_URL="https://ocs.atlog.io/inventory"  # l'URL du serveur OCS
ocs_basedir="/var/lib/ocsinventory-agent"
ocs_configdir="/etc/ocsinventory"
ocs_logfile="/var/log/ocsinventory-agent.log"
INTERVAL="3600" # Intervalle d'exécution en secondes (1 heure = 3600 secondes)
PLIST_FILE="/Library/LaunchDaemons/com.ocsinventory.agent.plist"
AGENT_PATH="/usr/local/bin/ocsinventory-agent"
AGENT_DOWNLOAD_URL="https://github.com/OCSInventory-NG/UnixAgent/archive/refs/tags/v2.10.2-MAC.tar.gz"
TAG=""


# Vérification de la présence de Homebrew
if ! command -v brew &> /dev/null
then
    echo "Homebrew n'est pas installé. Installation de Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew est déjà installé."
fi

# Installation de wget si nécessaire (pour télécharger l'agent)
if ! command -v wget &> /dev/null
then
    echo "wget n'est pas installé. Installation de wget..."
    brew install wget
else
    echo "wget est déjà installé."
fi

 cpan -i IO::Socket::SSL XML::Simple Compress::Zlib Net::IP LWP::Protocol::https Proc::Daemon Proc::PID::File Net::SNMP Net::Netmask Nmap::Parser Module::Install Parse::EDID LWP::UserAgent



# Vérification de la présence de l'agent OCS Inventory
if [ ! -f "$AGENT_PATH" ]; then
    echo "OCS Inventory Agent n'est pas installé. Téléchargement et installation de l'agent..."

    # Téléchargement de l'agent OCS Inventory
    wget -O /tmp/OCSNG_UNIX_SERVER.tar.gz "${AGENT_DOWNLOAD_URL}"

    # Extraction et installation
    cd "/tmp"
    tar -xzf OCSNG_UNIX_SERVER.tar.gz
    cd OCSNG_UNIX_SERVER-*
    sudo env PERL_AUTOINSTALL=1 perl Makefile.PL
    sudo make
    sudo make install --nowizard --server="${OCS_SERVER_URL}" --basevardir="${ocs_basedir}" --configdir="${ocs_configdir}" --tag="${TAG}" --logfile="${ocs_logfile}" --crontab --now  --remove-old-linux-agent --debug --download --snmp --nossl 

else
    echo "OCS Inventory Agent est déjà installé."
fi

# Configuration de l'agent
if [ ! -f /etc/ocsinventory/ocsinventory-agent.cfg ]; then
    echo "Configuration de l'agent OCS..."
    sudo ocsinventory-agent --server="${OCS_SERVER_URL}"
else
    echo "L'agent OCS est déjà configuré."
fi

# Création du fichier de log si inexistant
if [ ! -f "${ocs_logfile}" ]; then
    sudo touch "${ocs_logfile}"
    sudo chmod 644 "${ocs_logfile}"
fi
