#!/bin/bash
#
# Name:         centospostinstaller.sh
# Description:  This script set to day the packages, add system
#               tools and set configuration of multipropourse
#               server with dev headers: apache, php, ruby_rvm, 
#               rvm_tools, python, tomcat, webmin, developer apps, 
#               mariadb, postgresql, http proxypass multi service.
#               network conf, security conf, dhcp conf, pxe, etc
# Author:       @kseltar
# DateInit:     23 Jan 2012
# DateUpdate:   13 Feb 2013
# Version:      0.6

#!/bin/bash
### curl -O http://192.168.16.14/centosinstall.sh & /bin/chmod 777 ,/centosinstall.sh & ./centosinstall.sh
cd ~/
export rtinst="/root/0rtinst";
export rtdown=$rtinst"/downs";
export rtback=$rtinst"/backups";
export rtntdr="/etc/sysconfig/network-scripts"
export yumrepo="/etc/yum.repos.d";
export yumconf="/etc/yum.conf";
mkdir -p {$rtinst,$rtdown,$rtback"/"{etc/{sysconfig/{network-scripts},udev/{rules.d},yum.repos.d},root,var/{cache/yum,lib,www}}}
export rtetc=$rtback"/etc"
export rtsyc=$rtetc"/sysconfig"
export rtsyn=$rtsyc"/network-scripts"
export rtymr=$rtetc"/yum.repos.d"
export rtudv=$rtetc"/udev"
export rtudr=$rtudv"/rules.d"
export rtvar=$rtback"/var"
export rtlib=$rtvar"/lib"
export rtche=$rtvar"/cache"
export rtwww=$rtvar"/www"
export rtrot=$rtback"/root"

function f_date () {
  v_date=`date +"%Y%m%d_%H%M%S"`;
}

function f_menu () {
  echo "0) volver a descarcar este script";
  echo "1) proxy | 2) \"selinux\" y \"firewall\"";
  echo "3) red   | 4) \"yumgrade\"/\"actualizar\"";
  echo "";
  echo "";
  echo "97) agregrar atrpms repo";
  echo "98) reboot | 99) salir";
}

function f_this_install () {
  da=$PWD
  cd $rtdown
  /usr/bin/curl -O http://192.168.16.14/centosinstall.sh
  chmod 777 $rtdown/centosinstall.sh
  $rtdown/centosinstall.sh
  cd $da
}

function f_proxy () {
  echo -n "Requerira configuracion proxy para navegar? (S/N): "; read pxyreq;
  if [[ $pxyreq =~ ^([yY][eE][sS]|[yY]|[sS]|[sS][iI]|[sS][íÍ])$ ]]; then
    echo -n "Formato proxy \"http://proxyuser:password@servidor:puerto/\"? (S/N): "; read pxyreq2;
    if [[ $pxyreq2 =~ ^([yY][eE][sS]|[yY]|[sS]|[sS][iI]|[sS][íÍ])$ ]]; then
      echo -n "Usuario   : "; read pxyuser;
      echo -n "Contraseña: "; read pxypass;
      echo -n "Servidor  : "; read pxysrvr;
      echo -n "Puerto    : "; read pxyport;
      confprx="#export";
    else d="";
    fi
    echo -n "Dejar activa la configuracion proxy? (S/N): "; read pxyreq3;
    if [[ $pxyreq3 =~ ^([yY][eE][sS]|[yY]|[sS]|[sS][iI]|[sS][íÍ])$ ]]; then d="";
    else
      confprx="export";
    fi
    f_date;
    cp /etc/bashrc $rtetc"/bashrc-"$v_date".old"
    v=$(cat /etc/bashrc | grep -m 1 "export prx" | cut -c1-10);
    if [ "$v" != "export prx=\"\"" ]; then
      echo "" >> /etc/bashrc
      echo "" >> /etc/bashrc
      echo "export prx=\"http://"$pxyuser":"$pxypass"@"$pxysrvr":"$pxyport"/\"" >> /etc/bashrc
      echo $confprx" prx=\"\"" >> /etc/bashrc
      echo "export ftp_proxy=\$prx" >> /etc/bashrc
      echo "export http_proxy=\$prx" >> /etc/bashrc
      echo "export https_proxy=\$prx" >> /etc/bashrc
      echo "" >> /etc/bashrc
    fi
  else
    echo "saliendo de configuracion de proxy";
  fi
}

function f_selinux () {
  echo -n "Requerira desactivar la proteccion SELinux? (S/N): "; read slnreq;
  echo -n "Requerira desactivar la proteccion Firewall? (S/N): "; read fwlreq;
  if [[ $slnreq =~ ^([yY][eE][sS]|[yY]|[sS]|[sS][iI]|[sS][íÍ])$ ]]; then
    f_date;
    tar cvf $rtsyc"/selinux-"$v_date".tar" /etc/sysconfig/selinux
    v=$(sed '7!d' /etc/sysconfig/selinux);
    if [ "$v" == "SELINUX=enforcing" ]; then
      echo ""
      sed -e '7s/SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux > /etc/sysconfig/selinuxs
      mv /etc/sysconfig/selinuxs /etc/sysconfig/selinux
    fi
  fi
  if [[ $fwlreq =~ ^([yY][eE][sS]|[yY]|[sS]|[sS][iI]|[sS][íÍ])$ ]]; then
    /sbin/service iptables save
    /sbin/service iptables stop
    /sbin/chkconfig iptables off
    /sbin/service ip6tables save
    /sbin/service ip6tables stop
    /sbin/chkconfig ip6tables off
  fi
}

function f_ethconf () {
  echo -n "Desea configurar manualmente una tarjeta de red? (S/N): "; read rednum;
  if [[ $rednum =~ ^([yY][eE][sS]|[yY]|[sS]|[sS][iI]|[sS][íÍ])$ ]]; then
    netnr=0
    while [[ $rednum =~ ^([yY][eE][sS]|[yY]|[sS]|[sS][iI]|[sS][íÍ])$ ]]; do
      phcard="ifcfg-eth"$netnr"";
      ecard=$rtntdr"/"$phcard"";
      #ecard="/opt/ifcfg-eth"$netnr"";
      echo "Configurando eth"$netnr"."
      echo "eth"$netnr") DEVICE           (eth"$netnr")  "; #: "; read ethdev;
      echo "eth"$netnr") TYPE         (ethernet) "; #): "; read ethtyp;
      echo "eth"$netnr") BOOTPROTO        (none) "; #/bootp/dhcp)"; read ethboo;
      echo -n "eth"$netnr") IPADDR    (192.168.X.X): "; read ethipa;
      #echo -n "eth"$netnr") NETMASK (255.255.255.0): "; read ethmsk;
      #echo -n "eth"$netnr") GATEWAY   (192.168.X.X): "; read ethgwy;
      echo -n "eth"$netnr") DNS1       (172.16.0.2): "; read ethdn1;
      #echo -n "eth"$netnr") DNS2       (172.16.0.2): "; read ethdn2;
      ec0=`echo $ethipa | cut -d\. -f1`;
      eca=`echo $ethipa | cut -d\. -f2`;
      ecb=`echo $ethipa | cut -d\. -f3`;
      ecc=`echo $ethipa | cut -d\. -f4`;
      narra=$ec0"."$eca"."$ecb".";
      ethgwy=$narra"1";
      ethbro=$narra"255";
      ethnwk=$narra"0";
      f_date;
      mv $rtntdr"/"$phcard $rtsyn"/"$phcard"-"$v_date".old";
      mv /etc/resolv.conf $rtetc"/resolv.conf-"$v_date".old";
      mv /etc/resolv.conf $rtetc"/resolv.conf-"$v_date".old";
      echo "####### RESUMEN eth"$netnr" #######";
      echo "DEVICE=eth"$netnr""; echo "DEVICE=eth"$netnr"" > $ecard;
      ##TYPE=ethernet
      echo "TYPE=ethernet"; echo "TYPE=ethernet" >> $ecard;
      ##BOOTPROTO=none,bootp,dhcp
      echo "BOOTPROTO=none"; echo "BOOTPROTO=none" >> $ecard;
      ##ONBOOT=yes,no
      echo "ONBOOT=yes"; echo "ONBOOT=yes" >> $ecard;
      echo "IPADDR="$ethipa""; echo "IPADDR="$ethipa"" >> $ecard;
      echo "NETMASK=255.255.255.0"; echo "NETMASK=255.255.255.0" >> $ecard;
      echo "GATEWAY="$ethgwy""; echo "GATEWAY="$ethgwy"" >> $ecard;
      echo "NETWORK="$ethnwk""; echo "NETWORK="$ethnwk"" >> $ecard;
      echo "BROADCAST="$ethbro""; echo "BROADCAST="$ethbro"" >> $ecard;
      echo "DNS1="$ethdn1""; echo "DNS1="$ethdn1"" >> $ecard;
      echo "NM_CONTROLLED=no"; echo "NM_CONTROLLED=no" >> $ecard;
      echo "USERCTL=no"; echo "USERCTL=no" >> $ecard;
      echo "DEFROUTE=yes"; echo "DEFROUTE=yes" >> $ecard;
      echo "IPV4_FAILURE_FATAL=yes"; echo "IPV4_FAILURE_FATAL=yes" >> $ecard;
      echo "" >> $ecard;
      echo "############################"
      if [ "$netnr" -gt "2" ]; then d="";
        rednum="N";
      else
        echo -n "Desea configurar manualmente otra tarjeta de red? (S/N): "; read rednum;
      fi
      netnr=$(( $netnr + 1 ));
    done
  else
    echo "terminando configuracion de red";
  fi
  /etc/init.d/network restart
}

function f_reboot () {
  /sbin/reboot
}

function f_atrpmrepo () {
  wget -c http://packages.atrpms.net/RPM-GPG-KEY.atrpms -O $rtdown/RPM-GPG-KEY.atrpms
  atrp=$yumrepo"/atrpms.repo";
  if [ ! -f $atrp ]; then
    rpm --import $rtdown/RPM-GPG-KEY.atrpms
    echo "" > $atrp
    echo "[atrpms]" >> $atrp
    echo "name=Fedora Core $releasever - $basearch - ATrpms" >> $atrp
    echo "baseurl=http://ftp-stud.fht-esslingen.de/atrpms/dl.atrpms.net/el\$releasever-\$basearch/atrpms/stable/" >> $atrp
    echo "enable=1" >> $atrp
    echo "" >> $atrp
    #echo "[atrpms]" >> $atrp
    #echo "name=Fedora Core $releasever - $basearch - ATrpms" >> $atrp
    #echo "baseurl=http://dl.atrpms.net/el$releasever-$basearch/atrpms/stable" >> $atrp
    #echo "gpgkey=http://ATrpms.net/RPM-GPG-KEY.atrpms" >> $atrp
    #echo "gpgcheck=0" >> $atrp
    #echo "" >> $atrp
  fi
}

function f_mariadb_repo () {
  wget -c http://yum.mariadb.org/RPM-GPG-KEY-MariaDB -O $rtdown/RPM-GPG-KEY-MariaDB
  mdrp=$yumrepo"/mariadb.repo";
  if [ ! -f $mdrp ]; then
    rpm --import $rtdown/RPM-GPG-KEY-MariaDB
    echo "" > $mdrp
    echo "# MariaDB 10.0 CentOS repository list - created 2013-03-08 15:30 UTC" >> $mdrp
    echo "# http://mariadb.org/mariadb/repositories/" >> $mdrp
    echo "[mariadb]" >> $mdrp
    echo "name = MariaDB" >> $mdrp
    echo "baseurl = http://yum.mariadb.org/10.0/centos6-amd64" >> $mdrp
    echo "enable=1" >> $mdrp
    echo "gpgkey=https://yum.mariadb.org/RPM-GPG-KEY-MariaDB" >> $mdrp
    echo "gpgcheck=1" >> $mdrp
    echo "" >> $mdrp
  fi
}

function f_yumgrade () {
  f_date;
  tar cvf $rtetc"/yumcfg-"$v_date".tar" /etc/yum*
  #cp $yumconf $rtetc"/yum.conf-"$v_date".old"
  v=$(sed '3!d' $yumconf);
  if [ "$v" == "keepcache=0" ]; then
    echo ""
    sed -e '3s/keepcache=0/keepcache=1/' $yumconf > $yumconf"s"
    mv $yumconf"s" $yumconf
  fi

  yum -y update
  yum -y upgrade
}

function f_installplus () {
  yum -y install wget mc elinks xinetd ksh
  f_mariadb_repo;
  cd $rtdown
  wget -c https://raw.github.com/kseltar/rvm-rpm/master/RPMS/noarch/rvm-ruby-1.17.6-0.el6.noarch.rpm -O $rtdown/rvm-ruby-1.17.6-0.el6.noarch.rpm
  wget -c http://ufpr.dl.sourceforge.net/project/webadmin/webmin/1.610/webmin-1.610-1.noarch.rpm -O $rtdown/webmin-1.610-1.noarch.rpm
  wget -c http://www.princexml.com/download/prince-8.1-4.centos60.x86_64.rpm -O $rtdown/prince-8.1-4.centos60.x86_64.rpm
  wget -c http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm -O $rtdown/epel-release-6-8.noarch.rpm
  wget -c http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm -O $rtdown/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm
  wget -c http://repo.webtatic.com/yum/el6/x86_64/webtatic-release-6-2.noarch.rpm -O $rtdown/webtatic-release-6-2.noarch.rpm
  wget -c https://bitbucket.org/zhb/iredmail/downloads/iRedMail-0.8.3.tar.bz2 -O $rtdown/iRedMail-0.8.3.tar.bz2
  wget -c http://ufpr.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/4.0.0-beta1/phpMyAdmin-4.0.0-beta1-all-languages.tar.gz -O $rtdown/phpMyAdmin-4.0.0-beta1-all-languages.tar.gz
  wget -c http://ufpr.dl.sourceforge.net/project/phppgadmin/phpPgAdmin%20%5Bstable%5D/phpPgAdmin-5.0/phpPgAdmin-5.0.4.tar.gz -O $rtdown/phpPgAdmin-5.0.4.tar.gz
  rpm -ivh $rtdown/epel-release-6-8.noarch.rpm
  rpm -ivh $rtdown/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm
  rpm -ivh $rtdown/webtatic-release-6-2.noarch.rpm
  rpm -ivh $rtdown/webmin-1.610-1.noarch.rpm
  rpm -ivh $rtdown/prince-8.1-4.centos60.x86_64.rpm
  f_yumgrade;
}

function f_esentialpaks () {
  yum -y install MariaDB* galera
  yum -y install postgresql-pgpool-II.x86_64 postgresql-pgpool-II-recovery.x86_64 postgresql-pgpool-II pgadmin3
  yum -y install postgresql-devel mysql-devel sqlite-devel.x86_64 db4-devel libcurl-devel.x86_64
  yum -y install httpd-devel ImageMagick-devel postgresql-pgpool-II-devel.x86_64
  yum -y install zlib-devel openssl-devel rpm-devel popt-devel file-devel rpm-devel
  yum -y install gettext-devel kernel-devel gd-devel gpm-devel gtk2-devel
  yum -y install createrepo rpmrebuild rpmdevtools rpmconf libxml2-python python-deltarpm gitk
  yum -y install tcl-devel tk-devel libffi-devel libyaml libyaml-devel ncurses-devel readline-devel
  yum -y install memcached-devel.x86_64 memcached.x86_64 libmemcached-devel.x86_64 libmemcached.x86_64
  yum -y install samba4.x86_64 samba4-devel.x86_64 samba-winbind.x86_64 samba-swat.x86_64
  yum -y install samba-domainjoin-gui.x86_64 samba-winbind-devel.x86_64 samba-doc.x86_64
  yum -y install python-memcached.noarch perl-Cache-Memcached.noarch
  #yum -y install php php-common.x86_64 php-cgi php-pear php-pecl php-cli php-gd php-mysql php-pgsql
  yum -y install php54w php54w-common.x86_64 php54w-cgi php54w-pear php54w-pecl php54w-cli php54w-gd php54w-mysql php54w-pgsql
  #yum -y install php-sqlite php-xml.x86_64 php-xmlrpc.x86_64 php-pecl-memcached.x86_64
  yum -y install php54w-xml.x86_64 php54w-xmlrpc.x86_64 php54w-pecl-memcached.x86_64
  #yum -y install php-pecl-memcache.x86_64 php-odbc.x86_64 php-mcrypt.x86_64 php-mbstring.x86_64
  yum -y install php54w-pecl-memcache.x86_64 php54w-odbc.x86_64 php54w-mcrypt.x86_64 php54w-mbstring.x86_64
  #yum -y install php-devel.x86_64 php-dba.x86_64 php-soap.x86_64 php-snmp.x86_64
  yum -y install php54w-devel.x86_64 php54w-dba.x86_64 php54w-soap.x86_64 php54w-snmp.x86_64
  yum -y install git-all subversion subversion-tools gcc-c++ compat-readline5
  yum -y install patch make bzip2 autoconf automake libtool bison readline
  yum -y groupinstall "Development Tools"
}

function f_desktop () {
  yum groupinstall "Desktop" "Desktop Platform" "X Window System" "Fonts"
}

function f_yumgrp0100applications () {
  yum -y groupinstall "Applications"


  yum -y groupinstall "Emacs"
  yum -y groupinstall "Graphics Creation Tools"
  yum -y groupinstall "Internet Applications"
  yum -y groupinstall "Internet Browser"
  yum -y groupinstall "Office Suite and Productivity"
  yum -y groupinstall "TeX Support"
  yum -y groupinstall "Technical Writing"
}

function f_yumgrp0200basesys () {

  yum -y groupinstall "Base System"

  yum -y groupinstall "Backup Client"
  yum -y groupinstall "Base"
  yum -y groupinstall "Client management tools"
  yum -y groupinstall "Compatibility libraries"
  yum -y groupinstall "Console Internet tools"
  yum -y groupinstall "Debugging tools"
  yum -y groupinstall "Dial-up Networking Support"
  yum -y groupinstall "Directory Client"
  yum -y groupinstall "FCoE Storage Client"
  yum -y groupinstall "Hardware monitoring utilities"
  yum -y groupinstall "Infiniband Support"
  yum -y groupinstall "Java Platform"
  yum -y groupinstall "Large Systems Performance"
  yum -y groupinstall "Legacy UNIX compatibility"
  yum -y groupinstall "Mainframe Access"
  yum -y groupinstall "Network file system client"
  yum -y groupinstall "Networking Tools"
  yum -y groupinstall "Performance Tools"
  yum -y groupinstall "Perl Support"
  yum -y groupinstall "Printing client"
  yum -y groupinstall "Ruby Support"
  yum -y groupinstall "Scientific support"
  yum -y groupinstall "Security Tools"
  yum -y groupinstall "Smart card support"
  yum -y groupinstall "Storage Availability Tools"
  yum -y groupinstall "iSCSI Storage Client"


}

function f_yumgrp0300databases () {
  yum -y groupinstall "Databases"

  yum -y groupinstall "MySQL Database client"
  yum -y groupinstall "MySQL Database server"
  yum -y groupinstall "PostgreSQL Database client"
  yum -y groupinstall "PostgreSQL Database server"
}

function f_yumgrp0400desktops () {
  yum -y groupinstall "Desktops"

  yum -y groupinstall "Desktop"
  yum -y groupinstall "Desktop Debugging and Performance Tools"
  yum -y groupinstall "Desktop Platform"
  yum -y groupinstall "Fonts"
  yum -y groupinstall "General Purpose Desktop"
  yum -y groupinstall "Graphical Administration Tools"
  yum -y groupinstall "Input Methods"
  yum -y groupinstall "KDE Desktop"
  yum -y groupinstall "Legacy X Window System compatibility"
  yum -y groupinstall "Remote Desktop Clients"
  yum -y groupinstall "X Window System"
}

function f_yumgrp0500development () {
  yum -y groupinstall "Development"

  yum -y groupinstall "Additional Development"
  yum -y groupinstall "Desktop Platform Development"
  yum -y groupinstall "Development tools"
  yum -y groupinstall "Eclipse"
  yum -y groupinstall "Server Platform Development"
}

function f_yumgrp0600highavailability () {
  yum -y groupinstall "High Availability"

  yum -y groupinstall "High Availability"
  yum -y groupinstall "High Availability Management"
}

function f_yumgrp0700languages () {
  yum -y groupinstall "Languages"

#   Afrikaans Support [af]
  yum -y groupinstall "Afrikaans Support"
#   Albanian Support [sq]
  yum -y groupinstall "Albanian Support"
#   Amazigh Support [ber]
  yum -y groupinstall "Amazigh Support"
#   Arabic Support [ar]
  yum -y groupinstall "Arabic Support"
#   Armenian Support [hy]
  yum -y groupinstall "Armenian Support"
#   Assamese Support [as]
  yum -y groupinstall "Assamese Support"
#   Azerbaijani Support [az]
  yum -y groupinstall "Azerbaijani Support"
#   Basque Support [eu]
  yum -y groupinstall "Basque Support"
#   Belarusian Support [be]
  yum -y groupinstall "Belarusian Support"
#   Bengali Support [bn]
  yum -y groupinstall "Bengali Support"
#   Bhutanese Support [dz]
  yum -y groupinstall "Bhutanese Support"
#   Brazilian Portuguese Support [pt_BR]
  yum -y groupinstall "Brazilian Portuguese Support"
#   Breton Support [br]
  yum -y groupinstall "Breton Support"
#   Bulgarian Support [bg]
  yum -y groupinstall "Bulgarian Support"
#   Catalan Support [ca]
  yum -y groupinstall "Catalan Support"
#   Chhattisgarhi Support [hne]
  yum -y groupinstall "Chhattisgarhi Support"
#   Chichewa Support [ny]
  yum -y groupinstall "Chichewa Support"
#   Chinese Support [zh]
  yum -y groupinstall "Chinese Support"
#   Coptic Support [cop]
  yum -y groupinstall "Coptic Support"
#   Croatian Support [hr]
  yum -y groupinstall "Croatian Support"
#   Czech Support [cs]
  yum -y groupinstall "Czech Support"
#   Danish Support [da]
  yum -y groupinstall "Danish Support"
#   Dutch Support [nl]
  yum -y groupinstall "Dutch Support"
#   English (UK) Support [en_GB]
  yum -y groupinstall "English (UK) Support"
#   Esperanto Support [eo]
  yum -y groupinstall "Esperanto Support"
#   Estonian Support [et]
  yum -y groupinstall "Estonian Support"
#   Ethiopic Support [am]
  yum -y groupinstall "Ethiopic Support"
#   Faroese Support [fo]
  yum -y groupinstall "Faroese Support"
#   Fijian Support [fj]
  yum -y groupinstall "Fijian Support"
#   Filipino Support [fil]
  yum -y groupinstall "Filipino Support"
#   Finnish Support [fi]
  yum -y groupinstall "Finnish Support"
#   French Support [fr]
  yum -y groupinstall "French Support"
#   Frisian Support [fy]
  yum -y groupinstall "Frisian Support"
#   Friulian Support [fur]
  yum -y groupinstall "Friulian Support"
#   Gaelic Support [gd]
  yum -y groupinstall "Gaelic Support"
#   Galician Support [gl]
  yum -y groupinstall "Galician Support"
#   Georgian Support [ka]
  yum -y groupinstall "Georgian Support"
#   German Support [de]
  yum -y groupinstall "German Support"
#   Greek Support [el]
  yum -y groupinstall "Greek Support"
#   Gujarati Support [gu]
  yum -y groupinstall "Gujarati Support"
#   Hebrew Support [he]
  yum -y groupinstall "Hebrew Support"
#   Hiligaynon Support [hil]
  yum -y groupinstall "Hiligaynon Support"
#   Hindi Support [hi]
  yum -y groupinstall "Hindi Support"
#   Hungarian Support [hu]
  yum -y groupinstall "Hungarian Support"
#   Icelandic Support [is]
  yum -y groupinstall "Icelandic Support"
#   Indonesian Support [id]
  yum -y groupinstall "Indonesian Support"
#   Interlingua Support [ia]
  yum -y groupinstall "Interlingua Support"
#   Inuktitut Support [iu]
  yum -y groupinstall "Inuktitut Support"
#   Irish Support [ga]
  yum -y groupinstall "Irish Support"
#   Italian Support [it]
  yum -y groupinstall "Italian Support"
#   Japanese Support [ja]
  yum -y groupinstall "Japanese Support"
#   Kannada Support [kn]
  yum -y groupinstall "Kannada Support"
#   Kashmiri Support [ks]
  yum -y groupinstall "Kashmiri Support"
#   Kashubian Support [csb]
  yum -y groupinstall "Kashubian Support"
#   Kazakh Support [kk]
  yum -y groupinstall "Kazakh Support"
#   Khmer Support [km]
  yum -y groupinstall "Khmer Support"
#   Kinyarwanda Support [rw]
  yum -y groupinstall "Kinyarwanda Support"
#   Konkani Support [kok]
  yum -y groupinstall "Konkani Support"
#   Korean Support [ko]
  yum -y groupinstall "Korean Support"
#   Kurdish Support [ku]
  yum -y groupinstall "Kurdish Support"
#   Lao Support [lo]
  yum -y groupinstall "Lao Support"
#   Latin Support [la]
  yum -y groupinstall "Latin Support"
#   Latvian Support [lv]
  yum -y groupinstall "Latvian Support"
#   Lithuanian Support [lt]
  yum -y groupinstall "Lithuanian Support"
#   Low Saxon Support [nds]
  yum -y groupinstall "Low Saxon Support"
#   Luxembourgish Support [lb]
  yum -y groupinstall "Luxembourgish Support"
#   Macedonian Support [mk]
  yum -y groupinstall "Macedonian Support"
#   Maithili Support [mai]
  yum -y groupinstall "Maithili Support"
#   Malagasy Support [mg]
  yum -y groupinstall "Malagasy Support"
#   Malay Support [ms]
  yum -y groupinstall "Malay Support"
#   Malayalam Support [ml]
  yum -y groupinstall "Malayalam Support"
#   Maltese Support [mt]
  yum -y groupinstall "Maltese Support"
#   Manx Support [gv]
  yum -y groupinstall "Manx Support"
#   Maori Support [mi]
  yum -y groupinstall "Maori Support"
#   Marathi Support [mr]
  yum -y groupinstall "Marathi Support"
#   Mongolian Support [mn]
  yum -y groupinstall "Mongolian Support"
#   Myanmar (Burmese) Support [my]
  yum -y groupinstall "Myanmar (Burmese) Support"
#   Nepali Support [ne]
  yum -y groupinstall "Nepali Support"
#   Northern Sotho Support [nso]
  yum -y groupinstall "Northern Sotho Support"
#   Norwegian Support [nb]
  yum -y groupinstall "Norwegian Support"
#   Occitan Support [oc]
  yum -y groupinstall "Occitan Support"
#   Oriya Support [or]
  yum -y groupinstall "Oriya Support"
#   Persian Support [fa]
  yum -y groupinstall "Persian Support"
#   Polish Support [pl]
  yum -y groupinstall "Polish Support"
#   Portuguese Support [pt]
  yum -y groupinstall "Portuguese Support"
#   Punjabi Support [pa]
  yum -y groupinstall "Punjabi Support"
#   Romanian Support [ro]
  yum -y groupinstall "Romanian Support"
#   Russian Support [ru]
  yum -y groupinstall "Russian Support"
#   Sanskrit Support [sa]
  yum -y groupinstall "Sanskrit Support"
#   Sardinian Support [sc]
  yum -y groupinstall "Sardinian Support"
#   Serbian Support [sr]
  yum -y groupinstall "Serbian Support"
#   Sindhi Support [sd]
  yum -y groupinstall "Sindhi Support"
#   Sinhala Support [si]
  yum -y groupinstall "Sinhala Support"
#   Slovak Support [sk]
  yum -y groupinstall "Slovak Support"
#   Slovenian Support [sl]
  yum -y groupinstall "Slovenian Support"
#   Somali Support [nr]
  yum -y groupinstall "Somali Support"
#   Southern Ndebele Support [nr]
  yum -y groupinstall "Southern Ndebele Support"
#   Southern Sotho Support [st]
  yum -y groupinstall "Southern Sotho Support"
#   Spanish Support [es]
  yum -y groupinstall "Spanish Support"
#   Swahili Support [sw]
  yum -y groupinstall "Swahili Support"
#   Swati Support [ss]
  yum -y groupinstall "Swati Support"
#   Swedish Support [sv]
  yum -y groupinstall "Swedish Support"
#   Tagalog Support [tl]
  yum -y groupinstall "Tagalog Support"
#   Tajik Support [tg]
  yum -y groupinstall "Tajik Support"
#   Tamil Support [ta]
  yum -y groupinstall "Tamil Support"
#   Telugu Support [te]
  yum -y groupinstall "Telugu Support"
#   Tetum Support [tet]
  yum -y groupinstall "Tetum Support"
#   Thai Support [th]
  yum -y groupinstall "Thai Support"
#   Tibetan Support [bo]
  yum -y groupinstall "Tibetan Support"
#   Tsonga Support [ts]
  yum -y groupinstall "Tsonga Support"
#   Tswana Support [tn]
  yum -y groupinstall "Tswana Support"
#   Turkish Support [tr]
  yum -y groupinstall "Turkish Support"
#   Turkmen Support [tk]
  yum -y groupinstall "Turkmen Support"
#   Ukrainian Support [uk]
  yum -y groupinstall "Ukrainian Support"
#   Upper Sorbian Support [hsb]
  yum -y groupinstall "Upper Sorbian Support"
#   Urdu Support [ur]
  yum -y groupinstall "Urdu Support"
#   Uzbek Support [uz]
  yum -y groupinstall "Uzbek Support"
#   Venda Support [ve]
  yum -y groupinstall "Venda Support"
#   Vietnamese Support [vi]
  yum -y groupinstall "Vietnamese Support"
#   Walloon Support [wa]
  yum -y groupinstall "Walloon Support"
#   Welsh Support [cy]
  yum -y groupinstall "Welsh Support"
#   Xhosa Support [xh]
  yum -y groupinstall "Xhosa Support"
#   Zulu Support [zu]
  yum -y groupinstall "Zulu Support"
}

function f_yumgrp0800loadbalancer () {
  yum -y groupinstall "Load Balancer"

  yum -y groupinstall "Load Balancer"
}

function f_yumgrp0900resilientstorage () {
  yum -y groupinstall "Resilient Storage"

  yum -y groupinstall "Resilient Storage"
}

function f_yumgrp1000scalablefilesystem () {
  yum -y groupinstall "Scalable Filesystem Support"

  yum -y groupinstall "Scalable Filesystem"
}

function f_yumgrp1100servers () {
  yum -y groupinstall "Servers"

  yum -y groupinstall "Backup Server"
  yum -y groupinstall "CIFS file server"
  yum -y groupinstall "Directory Server"
  yum -y groupinstall "E-mail server"
  yum -y groupinstall "FTP Server"
  yum -y groupinstall "Identity Management Server"
  yum -y groupinstall "NFS file server"
  yum -y groupinstall "Network Infrastructure Server"
  yum -y groupinstall "Network Storage Server"
  yum -y groupinstall "Print Server"
  yum -y groupinstall "Server Platform"
  yum -y groupinstall "System administration tools"
}

function f_yumgrp1200systemmanagement () {
  yum -y groupinstall "System Management"

  yum -y groupinstall "Messaging Client Support"
  yum -y groupinstall "SNMP Support"
  yum -y groupinstall "System Management"
  yum -y groupinstall "System Management and Messaging Server support"
  yum -y groupinstall "Web-Based Enterprise Management"
}

function f_yumgrp1300virtualization () {
  yum -y groupinstall "Virtualization"

  yum -y groupinstall "Virtualization"
  yum -y groupinstall "Virtualization Client"
  yum -y groupinstall "Virtualization Platform"
  yum -y groupinstall "Virtualization Tools"
}

function f_yumgrp1400webservices () {
  yum -y groupinstall "Web Services"

  yum -y groupinstall "PHP Support"
  yum -y groupinstall "TurboGears application framework"
  yum -y groupinstall "Web Server"
  yum -y groupinstall "Web Servlet Engine"
}

#function hhh () {
  while [ "$seleccion" != "exit" ]; do
  #  if [ "$seleccion" == "" ]; then
    echo "";
    f_menu;
#  fi
    echo "Seleccion anterior: \""$seleccion"\".";
    echo -n "Seleccionar un item del menu: "; read seleccion;
    case $seleccion in
      "0" | "reload" | "actualizar") f_this_install; ;;
      "1" | "proxy") f_proxy; ;;
      "2" | "selinux" | "firewall") f_selinux; ;;
      "3" | "red" | "nertwork") f_ethconf; ;;
      "4" | "update" | "upgrade" | "actualizar") f_yumgrade; ;;
      "5" | "installplus" | "instalar") f_installplus; ;;
      "6" | "isnstallplus" | "isnstalar") f_desktop; ;;
      "7" | "sinstallplus" | "insstalar") f_esentialpaks; ;;
      "97" | "atrpms") f_atrpmrepo; ;;
      "98" | "reboot" | "reiniciar") f_reboot; ;;
      "99" | "q" | "salir" | "exit" | "quit") seleccion="exit"; ;;
      *) f_menu; ;;
    esac
  done
#}


function dasd () {
#u=PWD
#wget http://192.168.16.210/pub/floss/pkgs/y.tar
#cd /
#tar xvf $u/y.tar
#cd $u
#}

Desktop
Minimal Desktop
Minimal
Basic Server
Database Server
Web Server
Virual Host
Software Development Workstation

-----
Available Groups:
   Backup Client
   Backup Server
   Client management tools
   Eclipse
   Emacs
   FCoE Storage Client
   High Availability
   High Availability Management
   Identity Management Server
   Infiniband Support
   KDE Desktop
   Load Balancer
   Mainframe Access
   Messaging Client Support
   Remote Desktop Clients
   Resilient Storage
   Ruby Support
   Scalable Filesystems
   Server Platform Development
   Smart card support
   Somali Support
   System Management
   Systems Management Messaging Server support
   TeX support
   Technical Writing
   TurboGears application framework
   Virtualization Platform
   Web Servlet Engine
   Web-Based Enterprise Management
Available Language Groups:


yum -y update
yum -y upgrade

#yum -y groupinstall desktop
#}


#function hhh () {
cd $rtinst/
tar xvjf iRedMail-0.8.3.tar.bz2
cd iRedMail-0.8.3
bash iRedMail.sh
#}

#function hhh () {
#yum -y update
#yum -y upgrade

#tar cvf ~/y.tar /var/cache/yum

#rpm -ivh --force $rtinst/rvm-ruby-1.17.6-0.el6.noarch.rpm
#rvm get head --auto
#rvm pkg install openssl
#rvm reinstall all --force
#/sbin/reboot
#rvm install 1.9.3
#rvm install 1.8.7
#rvm 1.8.7 do gem update --system 1.3.7
#rvm 1.8.7 do gem install rdoc rdoc-data
#rvm 1.8.7 do rdoc-data --install ri
#rvm 1.8.7 do gem install rails -v=2.3.11
#rvm 1.8.7 do gem install rails -v=2.3.8
#rvm 1.8.7 do gem install rails -v=2.3.5
#rvm 1.8.7 do gem install authlogic -v=2.1.6
#rvm 1.8.7 do gem install will_paginate -v=2.3.11
#rvm 1.8.7 do gem install searchlogic -v=2.4.26
#rvm 1.8.7 do gem install passenger
#rvm 1.8.7 do passenger-install-apache2-module
#   LoadModule passenger_module /usr/lib/rvm/gems/ruby-1.8.7-p371/gems/passenger-3.0.19/ext/apache2/mod_passenger.so
#   PassengerRoot /usr/lib/rvm/gems/ruby-1.8.7-p371/gems/passenger-3.0.19
#   PassengerRuby /usr/lib/rvm/wrappers/ruby-1.8.7-p371/ruby

#   <VirtualHost *:80>
#      ServerName www.yourhost.com
#      # !!! Be sure to point DocumentRoot to 'public'!
#      DocumentRoot /somewhere/public
#      <Directory /somewhere/public>
#         # This relaxes Apache security settings.
#         AllowOverride all
#         # MultiViews must be turned off.
#         Options -MultiViews
#      </Directory>
#   </VirtualHost>

#rvm 1.9.3 do gem install passenger
#rvm 1.9.3 do passenger-install-apache2-module

#   LoadModule passenger_module /usr/lib/rvm/gems/ruby-1.9.3-p362/gems/passenger-3.0.19/ext/apache2/mod_passenger.so
#   PassengerRoot /usr/lib/rvm/gems/ruby-1.9.3-p362/gems/passenger-3.0.19
#   PassengerRuby /usr/lib/rvm/wrappers/ruby-1.9.3-p362/ruby


#   <VirtualHost *:80>
#      ServerName www.yourhost.com
#      # !!! Be sure to point DocumentRoot to 'public'!
#      DocumentRoot /somewhere/public
#      <Directory /somewhere/public>
#         # This relaxes Apache security settings.
#         AllowOverride all
#         # MultiViews must be turned off.
#         Options -MultiViews
#      </Directory>
#   </VirtualHost>




#rvm 1.9.3 do gem install passenger

#rvm 1.8.7 do gem install abstract akami archive-zip arel Ascii85 awesome_nested_set
#rvm 1.8.7 do gem install bcrypt-ruby builder bundler
#rvm 1.8.7 do gem install cgi_multipart_eof_fix closure-compiler cocaine coffee-rails coffee-script coffee-script-source configatron crack
#rvm 1.8.7 do gem install daemon_controller daemons
#rvm 1.8.7 do gem install erubis execjs
#rvm 1.8.7 do gem install fastthread flash_tool
#rvm 1.8.7 do gem install gem_plugin geocoder gmaps4rails gyoku
#rvm 1.8.7 do gem install haml hike hirb holidays htmlentities httpclient httpi
#rvm 1.8.7 do gem install i18n io-like
#rvm 1.8.7 do gem install jammit journey jquery-rails jrails json
#rvm 1.8.7 do gem install libv8
#rvm 1.8.7 do gem install mail mime-types mongrel multi_json mysql
#rvm 1.8.7 do gem install nokogiri nori
#rvm 1.8.7 do gem install open4
#rvm 1.8.7 do gem install pdf-reader pdfkit pg Platform polyglot POpen4 postgres postgres-pr prawn prawn-core prawn-format prawn-layout prawn-security princely
#rvm 1.8.7 do gem install rack-cache rack-mount rack-ssl rack-test rails-settings rails3-generators railties rake rake-compiler rmagick ruby-ole ruby-rc4
#rvm 1.8.7 do gem install sass sass-rails savon searchlogic soap4r spreadsheet sprockets
#rvm 1.8.7 do gem install therubyracer thor tilt treetop ttfunk tzinfo
#rvm 1.8.7 do gem install uglifier
#rvm 1.8.7 do gem install wasabi
#rvm 1.8.7 do gem install xml-simple
#rvm 1.8.7 do gem install yamler yui-compressor
#rvm 1.8.7 do gem install zip
#passenger-install-apache2-module

#rvm 1.9.3 do gem install rdoc
#rvm 1.9.3 do gem install rails
#rvm 1.9.3 do gem install passenger

#rvm install ree
}
#wget http://rubyforge.org/frs/download.php/70696/rubygems-1.3.7.tgz
##cd rubygems-1.3.7
##ruby setup.rb
cd ~/
