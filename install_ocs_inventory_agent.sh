#!/bin/bash

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
    printf "\tce script permet l'installation d'OCS Inventory Agent sur un système d'exploitation MacOS\n" 
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


function ocsAgentVersion {
    printf "\tversion-agent : %s\n" "$VERSION_MAC_AGENT"
}

function showversion
{
    printf "\tversion : %s\n" "$version"
}


# Fonction pour installer les paquets et modules sous macOS

function install_on_macos  {

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
  echo "Installation des utilitaires requis (gcc, make, pciutils, nmap, cron, cups, xz, yaml-cpp)..."
  brew install wget gcc make nmap cron cups xz yaml-cpp

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
}

# Fonction d'installation des modules Perl recommandés

function installRequirement 
{

     
  cpan -i IO::Socket::SSL XML::Simple Compress::Zlib Net::IP LWP::Protocol::https Proc::Daemon Proc::PID::File Net::SNMP Net::Netmask Nmap::Parser Module::Install Parse::EDID LWP::UserAgent


}


# Fonction pour installer l'agent OCS Inventory

function install_ocs_agent {

      echo "Téléchargement et installation de l'agent OCS Inventory..."
      wget -O /tmp/OCSNG_UNIX_SERVER.tar.gz https://github.com/OCSInventory-NG/UnixAgent/archive/refs/tags/v${VERSION_MAC_AGENT}-MAC.tar.gz
      cd /tmp
      tar -xzf OCSNG_UNIX_SERVER.tar.gz
      cd UnixAgent-*
      sudo env PERL_AUTOINSTALL=1 perl Makefile.PL
      sudo make
      sudo make install 
      sudo perl postinst.pl --nowizard --server="${OCS_SERVER_URL}" --basevardir="${ocs_basedir}" --configdir="${ocs_configdir}" --tag="${TAG}" --logfile="${ocs_logfile}" --crontab --now --lazy --debug --download --snmp --nossl

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



# Installation de l'agent OCS Inventory
install_on_macos
installRequirement 
install_ocs_agent
Nettoyage


ELAPSED="Durée de $0 ..... : "$(($SECONDS / 3600))"h"$((($SECONDS / 60) % 60))"m "$(($SECONDS % 60))"sec"
echo $ELAPSED

exit 0
