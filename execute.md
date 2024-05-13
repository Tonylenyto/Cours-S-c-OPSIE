#!/bin/bash

# Vérification des privilèges root
if [ "$(id -u)" -ne 0 ]; then
  echo "Ce script doit être exécuté avec des privilèges root."
  exit 1
fi

# Définition des variables
VERSION_UNIX_AGENT="2.6"
SERVER="URL_DU_SERVEUR_OCSINVENTORY"

# Téléchargement de l'agent Unix OCSInventory
wget "https://github.com/OCSInventory-NG/UnixAgent/releases/download/v${VERSION_UNIX_AGENT}/Ocsinventory-Unix-Agent-${VERSION_UNIX_AGENT}.tar.gz" -P /tmp

# Extraction de l'agent Unix OCSInventory
tar xzf "/tmp/Ocsinventory-Unix-Agent-${VERSION_UNIX_AGENT}.tar.gz" -C /tmp

# Installation des dépendances
apt-get update
apt-get install -y \
    perl \
    make \
    gcc \
    libxml-simple-perl \
    libcrypt-ssleay-perl \
    libdbi-perl \
    libdbd-mysql-perl \
    libapache-dbi-perl \
    libnet-ip-perl \
    libsoap-lite-perl \
    libarchive-zip-perl \
    libswitch-perl \
    libmojolicious-perl \
    libplack-perl \
    build-essential \
    libmodule-install-perl \
    libcompress-zlib-perl \
    libwww-perl \
    libdigest-md5-perl \
    libnet-snmp-perl \
    libproc-pid-file-perl \
    libproc-daemon-perl \
    libsys-syslog-perl \
    libnet-cups-perl \
    libnet-netmask-perl \
    nmap \
    dmidecode \
    net-tools \
    pciutils \
    smartmontools \
    read-edid

# Installation des modules Perl recommandés
cpan -i IO::Socket::SSL XML::Simple Compress::Zlib Net::IP LWP::Protocol::https Proc::Daemon Proc::PID::File Net::SNMP Net::Netmask Nmap::Parser Module::Install Parse::EDID LWP::UserAgent

# Installation de l'agent Unix OCSInventory
cd "/tmp/Ocsinventory-Unix-Agent-${VERSION_UNIX_AGENT}"
env PERL_AUTOINSTALL=1 perl Makefile.PL
make
make install
perl postinst.pl --nowizard --server="http://${SERVER}/ocsinventory" --crontab --now

# Nettoyage
apt-get clean
rm -rf "/tmp/Ocsinventory-Unix-Agent-${VERSION_UNIX_AGENT}" "/tmp/Ocsinventory-Unix-Agent-${VERSION_UNIX_AGENT}.tar.gz"

echo "L'agent OCS Inventory a été installé avec succès."
