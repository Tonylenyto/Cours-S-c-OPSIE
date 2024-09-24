#!/bin/bash

nb_arg=$#
cmd=$0
cmdLine=$@

DATE=$(date +%Y%m%d_%H%M)
WARN_MSG_ARRAY=()
INFO_MSG_ARRAY=()
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"


################################################################################
############     Déclaration des variables spécifiques au script    ############
################################################################################

OCS_SERVER_URL="https://ocs.atlog.io/ocsinventory" # URL du serveur OCS Inventory
TAG=""
ocs_basedir="/var/lib/ocsinventory-agent"
ocs_configdir="/etc/ocsinventory"
ocs_logfile="/var/log/ocsinventory-agent.log"
version="1" # version du script
VERSION_MAC_AGENT="2.10.2" # version agent

################################################################################
###########   Fonction "usage" décrit le script et son utilisation   ###########
################################################################################

function usage 
{

    printf '\033[1m'"SYNOPSYS"'\033[0m\n'
    printf "\t%s [-h]\n" "$cmd"
    printf '\033[1m'"DESCRIPTION"'\033[0m\n'
    printf "\tce script permet l'installation d'OCS Inventory Agent sur un système d'exploitation LMacOS\n" 
    printf "\t.............................\n"
    printf '\033[1m'"OPTION"'\033[0m\n'
    printf "\t-h     --help			 afficher ce message\n"
    printf "\t-v     --version		 print script version\n"
    printf "\t-V     --version-agent set agent version\n"
    printf "\t-s     --server        set IP server\n"
    printf "\t-T     --tag          set tag\n"
    printf '\033[1m'"EXEMPLES"'\033[0m\n'
    printf "\t%s -h\n" "$cmd"

}

################################################################################
###############        Fonctions et traitements générique        ###############
################################################################################

# gestion du passage en mode debug
# pour passer en mode DEBUG lancer "export DEBUG=1" avant de lancer le script

if [[ $DEBUG == 1 ]] ; then
    set -x
else
    set +x
fi

function ocsAgentVersion {
    printf "\tversion-agent : %s\n" "$VERSION_MAC_AGENT"
}

function showversion
{
    printf "\tversion : %s\n" "$version"
}


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
#if [ "$EUID" -ne 0 ]; then
#  echo "Ce script doit être exécuté avec des privilèges root (sudo)."
#  exit 1
#fi

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
  echo "Installation des utilitaires requis (gcc, make, pciutils, nmap, cron, cups, xz)..."
  brew install gcc make pciutils nmap cron cups xz

  # Vérification et installation de Perl via Homebrew (si nécessaire)
  if ! perl -v | grep "v5.8" &> /dev/null; then
      echo "Installation de Perl 5.8 et des dépendances..."
      brew install perl
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
      wget -O /tmp/OCSNG_UNIX_SERVER.tar.gz https://github.com/OCSInventory-NG/UnixAgent/archive/refs/tags/v${VERSION_MAC_AGENT}-MAC.tar.gz
      cd /tmp
      tar -xzf OCSNG_UNIX_SERVER.tar.gz
      cd UnixAgent-*
      sudo env PERL_AUTOINSTALL=1 perl Makefile.PL
      sudo make
      sudo make install 
      sudo perl postinst.pl --nowizard --server="${OCS_SERVER_UR}" --basevardir="${ocs_basedir}" --configdir="${ocs_configdir}" --tag="${TAG}" --logfile="${ocs_logfile}" --crontab --now --lazy --debug --download --snmp --nossl
  else
      echo "L'agent OCS Inventory est déjà installé."
  fi
}

     
# Nettoyage

function Nettoyage
{
     sudo rm -rf "/tmp/OCSNG_UNIX_SERVER.tar.gz" "/tmp/UnixAgent-*"

}

################################################################################
###############  Gestion des parametres de la ligne de commande  ###############
################################################################################

while [ "$1" != "" ]; do
    case $1 in
        # TODO
        # TODO
        # TODO
        # TODO
        -V | --version-agent )
            shift
            VERSION_MAC_AGENT=$1
            ;;
        -s | --server )
            shift
            SERVER=$1
            ;;
        -T | --tag )
            shift
            TAG=$1
            ;;
        -h | --help )
            usage
            exit 0
            ;;
        -v | --version )
            showversion
            exit 0
            ;;
        * )
            usage
            printf '\n\033[0;31;1m'"ERROR : invalid parameter %s %s"'\033[0m\n' "$0" "$cmdLine"
            exit 101
        ;;
    esac
    shift
done

SECONDS=0


################################################################################
###############                       MAIN                       ###############
################################################################################

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
Nettoyage

# Fin
echo "Enjoy !!"
echo "END! END! END!"

################################################################################
###############                   FIN DU SCRIPT                  ###############
################################################################################

printInfos
printErrors

# décommenter les 2 lignes ci-dessous pour afficher la durée du script
ELAPSED="Durée de $0 ..... : "$(($SECONDS / 3600))"h"$((($SECONDS / 60) % 60))"m "$(($SECONDS % 60))"sec"
echo $ELAPSED

exit 0
