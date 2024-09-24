#!/bin/bash

# Variables
OCS_SERVER_URL="https://ocs.atlog.io/inventory"
TAG=""
ocs_basedir="/var/lib/ocsinventory-agent"
ocs_configdir="/etc/ocsinventory"
ocs_logfile="/var/log/ocsinventory-agent.log"

# Modules Spécifique macOS

PERL_MODULES_REQUIRED=(
    "XML::Simple"
    "Compress::Zlib"
    "Net::IP"
    "LWP::UserAgent"
    "Digest::MD5"
    "Net::SSLeay"
    "Data::UUID"
    "Mac::SysProfile"  
)

PERL_MODULES_RECOMMENDED=(
    "IO::Socket::SSL"
    "Crypt::SSLeay"
    "LWP::Protocol::https"
    "Proc::Daemon"
    "Proc::PID::File"
    "Net::SNMP"
    "Net::Netmask"
    "Nmap::Parser"
    "Module::Install"
    "Net::CUPS"
    "Parse::EDID"
)

LINUX_PACKAGES_REQUIRED=(
    "libmodule-install-perl"
    "dmidecode"
    "libxml-simple-perl"
    "libcompress-zlib-perl"
    "libnet-ip-perl"
    "libwww-perl"
    "libdigest-md5-perl"
    "libdata-uuid-perl"
)

LINUX_PACKAGES_RECOMMENDED=(
    "libcrypt-ssleay-perl"
    "libnet-snmp-perl"
    "libproc-pid-file-perl"
    "libproc-daemon-perl"
    "net-tools"
    "libsys-syslog-perl"
    "pciutils"
    "smartmontools"
    "read-edid"
    "nmap"
    "libnet-netmask-perl"
)

# Vérification des privilèges root
if [ "$EUID" -ne 0 ]; then
  echo "Ce script doit être exécuté avec des privilèges root (sudo)."
  exit 1
fi

# Détection du système d'exploitation
OS_TYPE=$(uname)

# Fonction pour installer les paquets sous Debian/Linux

install_on_linux() {
  echo "Système d'exploitation : Linux"

  # Mise à jour des paquets
  echo "Mise à jour des dépôts apt..."
  sudo apt update

  # Installation des paquets requis pour Linux
  echo "Installation des paquets requis..."
  sudo apt install -y "${LINUX_PACKAGES_REQUIRED[@]}"

  # Installation des paquets recommandés pour Linux
  echo "Installation des paquets recommandés..."
  sudo apt install -y "${LINUX_PACKAGES_RECOMMENDED[@]}"
}

# Fonction pour installer les paquets et modules sous macOS
install_on_macos() {
  echo "Système d'exploitation : macOS"

  # Vérification de la présence de Homebrew
  if ! command -v brew &> /dev/null
  then
      echo "Homebrew n'est pas installé. Installation de Homebrew..."
      /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
      echo "Homebrew est déjà installé."
  fi

  # Mise à jour de Homebrew
  echo "Mise à jour des paquets Homebrew..."
  brew update

  # Installation des utilitaires requis
  echo "Installation des utilitaires requis (gcc, make, dmidecode, pciutils, nmap)..."
  brew install gcc make dmidecode pciutils nmap

  # Vérification et installation de Perl via Homebrew (si nécessaire)
  if ! perl -v | grep "v5.8" &> /dev/null; then
      echo "Installation de Perl 5.8 et des dépendances..."
      brew install perl
      brew install xz
  else
      echo "Perl est déjà installé."
  fi

  # Mise à jour des modules CPAN
  echo "Mise à jour des modules CPAN..."
  cpan App::cpanminus
  cpan install CPAN

  # Installation des modules Perl requis
  echo "Installation des modules Perl requis..."
  for module in "${PERL_MODULES_REQUIRED[@]}"; do
      echo "Installation du module Perl: $module..."
      cpan install "$module"
  done

  # Installation des modules Perl recommandés
  echo "Installation des modules Perl recommandés..."
  for module in "${PERL_MODULES_RECOMMENDED[@]}"; do
      echo "Installation du module Perl: $module..."
      cpan install "$module"
  done
}

# Fonction pour installer l'agent OCS Inventory

install_ocs_agent() {
  AGENT_PATH="/usr/local/bin/ocsinventory-agent"
  if [ ! -f "$AGENT_PATH" ]; then
      echo "Téléchargement et installation de l'agent OCS Inventory..."
      wget -O /tmp/OCSNG_UNIX_SERVER.tar.gz https://github.com/OCSInventory-NG/UnixAgent/archive/refs/tags/v2.10.2-MAC.tar.gz
      cd /tmp
      tar -xzf OCSNG_UNIX_SERVER.tar.gz
      cd UnixAgent-*
      sudo env PERL_AUTOINSTALL=1 perl Makefile.PL
      sudo make
      sudo make install 
       sudo perl postinst.pl --nowizard --server="${OCS_SERVER_UR}" --basevardir="${ocs_basedir}" --configdir="${ocs_configdir}" --tag="${TAG}" --logfile="${ocs_logfile}" --crontab --now  --debug --download --snmp --nossl
  else
      echo "L'agent OCS Inventory est déjà installé."
  fi
}

# Lancement de l'installation en fonction de l'OS
if [[ "$OS_TYPE" == "Linux" ]]; then
  install_on_linux
elif [[ "$OS_TYPE" == "Darwin" ]]; then
  install_on_macos
else
  echo "Système d'exploitation non supporté."
  exit 1
fi

# Installation de l'agent OCS Inventory
install_ocs_agent

# Finalisation
echo "END! END! END!"
