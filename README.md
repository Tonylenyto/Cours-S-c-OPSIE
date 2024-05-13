# Cours-S-c-OPSIE
Ce repo contient l'ensemble des cours et tps du cours de sécurité applicative OPSIE2
'''shell
# Utilisation d'une version GNU/Linux Ubuntu
FROM debian:bookworm-slim

ENV UnixAgent 2.10.0
ENV SERVER 192.168.2.169:6080

# Installation des dépendances systèmes
RUN apt-get update && DEBIAN_FRONTEND=noninteractive \
    apt-get install -y \
    wget \
    curl \
    git \
    make \
    perl \
    cpanminus \
    apache2 \
    gcc \
    nano \
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
    dmidecode \
    libxml-simple-perl \
    libcompress-zlib-perl \
    libnet-ip-perl \
    libwww-perl \
    libdigest-md5-perl \
    libcrypt-ssleay-perl \
    libnet-snmp-perl \
    libproc-pid-file-perl \
    libproc-daemon-perl \
    net-tools \
    libsys-syslog-perl \
    pciutils \
    libnet-cups-perl \
    smartmontools \
    read-edid \
    nmap \
    libnet-netmask-perl \
    && apt-get clean

RUN mkdir -p /data

# Installation des dépendances recommandées pour les modules Perl
RUN cpanm --force IO::Socket::SSL \
    XML::Simple \
    Compress::Zlib \
    Net::IP \
    LWP::Protocol::https \
    Proc::Daemon \
    Proc::PID::File \
    Net::SNMP \
    Net::Netmask \
    Nmap::Parser \
    Module::Install \
    Parse::EDID \
    LWP::UserAgent
    
VOLUME /data

RUN wget https://github.com/OCSInventory-NG/UnixAgent/releases/download/v${UnixAgent}/Ocsinventory-Unix-Agent-${UnixAgent}.tar.gz -P /home && \
    tar xzf /home/Ocsinventory-Unix-Agent-${UnixAgent}.tar.gz -C /home;

RUN cd /home/Ocsinventory-Unix-Agent-${UnixAgent} && \
    env PERL_AUTOINSTALL=1 perl Makefile.PL && \
    make && \
    make install && \
    perl postinst.pl --nowizard --server=http://${SERVER}/ocsinventory --crontab --now 

COPY --chown=$user entrypoint.sh .
RUN chmod +x entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]
'''
