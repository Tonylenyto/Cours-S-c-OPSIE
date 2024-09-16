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

################################################################################
############  	Compatibilities for MacOS : 			    ############
############  		11.6 (Big Sur)				    ############ ############  		12.X (Monterey)				    ############
############  		13.X (Ventura)				    ############
############ 		14.X (Sonoma)   			    ############
################################################################################

version="1"
VERSION_Mac_AGENT="2.10.2"
SERVER="192.168.2.169:6080"
TAG=""
ocs_basedir="/var/lib/ocsinventory-agent"
ocs_configdir="/etc/ocsinventory"
ocs_logfile="/var/log/ocsinventory-agent.log"
HOST="http://${SERVER}/ocsinventory"


# liste des propriétés qui doivent être définie pour que le script fonctionne
# si une des propriété n'est pas définie echec du script avec message
PROPERTIES_TO_CHECK[1]="HOME"

# TODO
# TODO
# TODO
# TODO


################################################################################
###########   Fonction "usage" décrit le script et son utilisation   ###########
################################################################################

function usage 
{

    printf '\033[1m'"SYNOPSYS"'\033[0m\n'
    printf "\t%s [-h]\n" "$cmd"
    printf '\033[1m'"DESCRIPTION"'\033[0m\n'
    printf "\tce script permet l'installation d'OCS Inventory Agent sur un système d'exploitation Linux\n" 
    printf "\t.............................\n"
    printf "\tpour lancer le script, l'utilisateur doit avoir les privilèges du Super utilisateur (root)\n"
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
    printf "\tversion-agent : %s\n" "$VERSION_UNIX_AGENT"
}

function showversion
{
    printf "\tversion : %s\n" "$version"
}

function printErrors
{
    if [ ! ${#WARN_MSG_ARRAY[@]} -eq 0 ]; then
        printf '\033[0;31;1m'"ATTENTION : il y a eu des erreurs :\n"
        printf '\033[0;33;1m''%s''\033[0m\n' "${WARN_MSG_ARRAY[@]}"
    fi
}

function printInfos
{
    if [ ! ${#INFO_MSG_ARRAY[@]} -eq 0 ]; then
        printf '\033[0;31;1m'"Infos :\n"
        printf '\033[0;36;1m''%s''\033[0m\n' "${INFO_MSG_ARRAY[@]}"
    fi
}

function checkPropertiesSet
{
    for a in ${!PROPERTIES_TO_CHECK[*]} ;
    do
        #echo ${PROPERTIES_TO_CHECK[$a]}'='${!PROPERTIES_TO_CHECK[$a]}
        if [ "${!PROPERTIES_TO_CHECK[$a]}" = "" ] ; then
            printf '\033[0;31;1m'
            echo "ABORTED : la propriété ${PROPERTIES_TO_CHECK[$a]} n'est pas définie"
            printf '\033[0m\n'
            exit 102
        fi
    done
}


################################################################################
###############        Fonctions et traitements spécifique       ###############
################################################################################

function installDependance 
{
sudo apt-get update
sudo apt-get install -y \
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

}

function installRequirement 
{

     # Installation des modules Perl recommandés

     cpan -i IO::Socket::SSL XML::Simple Compress::Zlib Net::IP LWP::Protocol::https Proc::Daemon Proc::PID::File Net::SNMP Net::Netmask Nmap::Parser Module::Install Parse::EDID LWP::UserAgent


}

function installOcsAgent 
{

      # Installation de l'agent Unix OCSInventory
     cd "/tmp/Ocsinventory-Unix-Agent-${VERSION_UNIX_AGENT}"
     sudo env PERL_AUTOINSTALL=1 perl Makefile.PL
     sudo make
     sudo make install
     sudo perl postinst.pl --nowizard --server="${HOST}" --basevardir="${ocs_basedir}" --configdir="${ocs_configdir}" --tag="${TAG}" --logfile="${ocs_logfile}" --crontab --now  --remove-old-linux-agent --debug --download --snmp --nossl --daemon --force

}

function crontab {

#Execution ocs agent tous les jours à 10 heures

cd /etc/cron.d
sudo sed -i '2i */30 * * * * root /usr/local/bin/ocsinventory-agent --lazy > /dev/null 2>&1' ocsinventory-agent

}

function Nettoyage
{
     # Nettoyage
     sudo apt-get clean
     sudo rm -rf "/tmp/Ocsinventory-Unix-Agent-${VERSION_UNIX_AGENT}" "/tmp/Ocsinventory-Unix-Agent-${VERSION_UNIX_AGENT}.tar.gz"

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
            VERSION_UNIX_AGENT=$1
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


# Téléchargement de l'agent Unix OCSInventory
wget "https://github.com/OCSInventory-NG/UnixAgent/releases/download/v${VERSION_UNIX_AGENT}-MAC/Ocsinventory-Unix-Agent-${VERSION_UNIX_AGENT}-MAC.tar.gz" -P /tmp

# Extraction de l'agent Unix OCSInventory
tar xzf "/tmp/Ocsinventory-Unix-Agent-${VERSION_UNIX_AGENT}-MAC.tar.gz" -C /tmp

checkPropertiesSet

installDependance

installRequirement

installOcsAgent

crontab

Nettoyage

echo "L'agent OCS Inventory a été installé avec succès."


# exemple d'ajout d'un message d'info à afficher en récap à la fin du script
#INFO_MSG_ARRAY+=("INFO => Download : fichier toto.tgz disponible dans ....")

# exemple d'ajout d'un message d'erreur à afficher en récap à la fin du script
#WARN_MSG_ARRAY+=("ERROR => Download : echec du téléchargement de .....")



################################################################################
###############                   FIN DU SCRIPT                  ###############
################################################################################

printInfos
printErrors

# décommenter les 2 lignes ci-dessous pour afficher la durée du script
ELAPSED="Durée de $0 ..... : "$(($SECONDS / 3600))"h"$((($SECONDS / 60) % 60))"m "$(($SECONDS % 60))"sec"
echo $ELAPSED

exit 0
