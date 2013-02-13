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
cd ~/
mkdir /root/downs
#export
function f_menu () {
  echo "1) proxy | 2) \"selinux\" y \"firewall\"";
  echo "3) red   | 4) \"yumgrade\"/\"actualizar\"";
  echo "";
  echo "";
  echo "97) agregrar atrpms repo";
  echo "98) reboot | 99) salir";
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
    v=$(cat /etc/bashrc | grep -m 1 "export prx" | cut -c1-10);
    if [ "$v" != "export prx" ]; then
      echo "" >> /etc/bashrc
      echo "" >> /etc/bashrc
      echo "export prx=\"http://"$pxyuser":"$pxypass"@"$pxysrvr":"$pxyport"/\"" >> /etc/bashrc
      echo $confprx >> /etc/bashrc
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
      ecard="/etc/sysconfig/network-scripts/ifcfg-eth"$netnr"";
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
      e=`date +"%Y%m%d_%H%M%S"`;
      ec0=`echo $ethipa | cut -d\. -f1`;
      eca=`echo $ethipa | cut -d\. -f2`;
      ecb=`echo $ethipa | cut -d\. -f3`;
      ecc=`echo $ethipa | cut -d\. -f4`;
      narra=$ec0"."$eca"."$ecb".";
      ethgwy=$narra"1";
      ethbro=$narra"255";
      ethnwk=$narra"0";
      mv $ecard $ecard"-"$e
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
}

function f_reboot () {
  /sbin/reboot
}

function f_atrpmrepo () {
  wget -c http://packages.atrpms.net/RPM-GPG-KEY.atrpms -O /root/downs/RPM-GPG-KEY.atrpms
  atrp="/etc/yum.repos.d/atrpms.repo";
  if [ ! -f $atrp ]; then
    rpm --import /root/downs/RPM-GPG-KEY.atrpms
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

function f_yumgrade () {
  v=$(sed '3!d' /etc/yum.conf);
  if [ "$v" == "keepcache=0" ]; then
    echo ""
    sed -e '3s/keepcache=0/keepcache=1/' /etc/yum.conf > /etc/yum.confs
    mv /etc/yum.confs /etc/yum.conf
  fi

  yum -y update
  yum -y upgrade
}

function f_installplus () {
  yum -y install wget mc elinks xinetd ksh
  cd /root/downs
  wget -c https://raw.github.com/kseltar/rvm-rpm/master/RPMS/noarch/rvm-ruby-1.17.6-0.el6.noarch.rpm -O /root/downs/rvm-ruby-1.17.6-0.el6.noarch.rpm
  wget -c http://ufpr.dl.sourceforge.net/project/webadmin/webmin/1.610/webmin-1.610-1.noarch.rpm -O /root/downs/webmin-1.610-1.noarch.rpm
  wget -c http://www.princexml.com/download/prince-8.1-4.centos60.x86_64.rpm -O /root/downs/prince-8.1-4.centos60.x86_64.rpm
  wget -c http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm -O /root/downs/epel-release-6-8.noarch.rpm
  wget -c http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm -O /root/downs/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm
  wget -c http://repo.webtatic.com/yum/el6/x86_64/webtatic-release-6-2.noarch.rpm -O /root/downs/webtatic-release-6-2.noarch.rpm
  wget -c https://bitbucket.org/zhb/iredmail/downloads/iRedMail-0.8.3.tar.bz2 -O /root/downs/iRedMail-0.8.3.tar.bz2
  wget -c http://ufpr.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/4.0.0-alpha1/phpMyAdmin-4.0.0-alpha1-all-languages.tar.gz -O /root/downs/phpMyAdmin-4.0.0-alpha1-all-languages.tar.gz
  wget -c http://ufpr.dl.sourceforge.net/project/phppgadmin/phpPgAdmin%20%5Bstable%5D/phpPgAdmin-5.0/phpPgAdmin-5.0.4.tar.gz -O /root/downs/phpPgAdmin-5.0.4.tar.gz
  yum -y install /root/downs/epel-release-6-8.noarch.rpm
  yum -y install /root/downs/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm
  yum -y install /root/downs/root/downs/webtatic-release-6-2.noarch.rpm
  yum -y install /root/downs/webmin-1.610-1.noarch.rpm
  yum -y install /root/downs/prince-8.1-4.centos60.x86_64.rpm
  f_yumgrade;
}

function f_esentialpaks () {
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
  yum -y install php php-common.x86_64 php-cgi php-pear php-pecl php-cli php-gd php-mysql php-pgsql
  yum -y install php-sqlite php-xml.x86_64 php-xml.x86_64 php-pecl-memcached.x86_64
  yum -y install php-pecl-memcache.x86_64 php-odbc.x86_64 php-mcrypt.x86_64 php-mbstring.x86_64
  yum -y install php-devel.x86_64 php-dba.x86_64 php-soap.x86_64 php-snmp.x86_64
  yum -y install git-all subversion subversion-tools gcc-c++ compat-readline5
  yum -y install patch make bzip2 autoconf automake libtool bison readline
  yum -y groupinstall "Development Tools"
}

function f_desktop () {
  yum groupinstall "Desktop" "Desktop Platform" "X Window System" "Fonts"
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
      "1" | "proxy") f_proxy; ;;
      "2" | "selinux" | "firewall") f_selinux; ;;
      "3" | "red" | "nertwork") f_ethconf; ;;
      "4" | "update" | "upgrade" | "actualizar") f_yumgrade; ;;
      "5" | "installplus" | "instalar") f_installplus; ;;
      "6" | "isnstallplus" | "isnstalar") f_desktop; ;;
      "7" | "sinstallplus" | "insstalar") f_esentialpaks; ;;
      "97" | "atrpms") f_atrpmrepo; ;;
      "98" | "reboot" | "reiniciar") f_reboot; ;;
      "99" | "salir" | "exit" | "quit") seleccion="exit"; ;;
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
function f_yumgrp01applications () {
  yum -y groupinstall "Applications";
}

  yum -y groupinstall "Applications"


  yum -y groupinstall "Emacs"
  yum -y groupinstall "Graphics Creation Tools"
  yum -y groupinstall "Internet Applications"
  yum -y groupinstall "Internet Browser"
  yum -y groupinstall "Office Suite and Productivity"
  yum -y groupinstall "TeX Support"
  yum -y groupinstall "Technical Writing"
-----

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


-----

  yum -y groupinstall "Databases"

  yum -y groupinstall "MySQL Database client"
  yum -y groupinstall "MySQL Database server"
  yum -y groupinstall "PostgreSQL Database client"
  yum -y groupinstall "PostgreSQL Database server"


-----

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


-----

  yum -y groupinstall "Development"

  yum -y groupinstall "Additional Development"
  yum -y groupinstall "Desktop Platform Development"
  yum -y groupinstall "Development tools"
  yum -y groupinstall "Eclipse"
  yum -y groupinstall "Server Platform Development"


-----

  yum -y groupinstall "High Availability"

  yum -y groupinstall "High Availability"
  yum -y groupinstall "High Availability Management"


-----

  yum -y groupinstall "Languages"

  yum -y groupinstall "Afrikaans Support"
  yum -y groupinstall "Albanian Support"
  yum -y groupinstall "Arabic Support"
  yum -y groupinstall "Armenian Support"
  yum -y groupinstall "Assamese Support"
  yum -y groupinstall "Azerbaijani Support"
  yum -y groupinstall "Basque Support"
  yum -y groupinstall "Belarusian Support"
  yum -y groupinstall "Bengali Support"
  yum -y groupinstall "Bhutanese Support"
  yum -y groupinstall "Brazilian Portuguese Support"
  yum -y groupinstall "Breton Support"
  yum -y groupinstall "Bulgarian Support"
  yum -y groupinstall "Catalan Support"
  yum -y groupinstall "Chhattisgarhi Support"
  yum -y groupinstall "Chichewa Support"
  yum -y groupinstall "Chinese Support"
  yum -y groupinstall "Coptic Support"
  yum -y groupinstall "Croatian Support"
  yum -y groupinstall "Czech Support"
  yum -y groupinstall "Danish Support"
  yum -y groupinstall "English (UK) Support"
  yum -y groupinstall "Esperanto Support"
  yum -y groupinstall "Ethiopic Support"
  yum -y groupinstall "Faroese Support"
  yum -y groupinstall "Fijian Support"
  yum -y groupinstall "Filipino Support"
  yum -y groupinstall "Finnish Support"
  yum -y groupinstall "French Support"
  yum -y groupinstall "Frisian Support"
  yum -y groupinstall "Friulian Support"
  yum -y groupinstall "Gaelic Support"
  yum -y groupinstall "Galician Support"
  yum -y groupinstall "Georgian Support"
  yum -y groupinstall "German Support"
  yum -y groupinstall "Greek Support"
  yum -y groupinstall "Gujarati Support"
  yum -y groupinstall "Hebrew Support"
  yum -y groupinstall "Hiligaynon Support"
  yum -y groupinstall "Hindi Support"
  yum -y groupinstall "Hungarian Support"
  yum -y groupinstall "Icelandic Support"
  yum -y groupinstall "Indonesian Support"
  yum -y groupinstall "Inuktitut Support"
  yum -y groupinstall "Irish Support"
  yum -y groupinstall "Italian Support"
  yum -y groupinstall "Japanese Support"
  yum -y groupinstall "Kannada Support"
  yum -y groupinstall "Kashmiri Support"
  yum -y groupinstall "Kashubian Support"
  yum -y groupinstall "Kazakh Support"
  yum -y groupinstall "Khmer Support"
  yum -y groupinstall "Kinyarwanda Support"
  yum -y groupinstall "Konkani Support"
  yum -y groupinstall "Korean Support"
  yum -y groupinstall "Kurdish Support"
  yum -y groupinstall "Lao Support"
  yum -y groupinstall "Latin Support"
  yum -y groupinstall "Latvian Support"
  yum -y groupinstall "Lithuanian Support"
  yum -y groupinstall "Low Saxon Support"
  yum -y groupinstall "Luxembourgish Support"
  yum -y groupinstall "Macedonian Support"
  yum -y groupinstall "Maithili Support"
  yum -y groupinstall "Malagasy Support"
  yum -y groupinstall "Malay Support"
  yum -y groupinstall "Malayalam Support"
  yum -y groupinstall "Maltese Support"
  yum -y groupinstall "Manx Support"
  yum -y groupinstall "Maori Support"
  yum -y groupinstall "Marathi Support"
  yum -y groupinstall "Mongolian Support"
  yum -y groupinstall "Myanmar (Burmese) Support"
  yum -y groupinstall "Nepali Support"
  yum -y groupinstall "Northern Sotho Support"
  yum -y groupinstall "Norwegian Support"
  yum -y groupinstall "Occitan Support"
  yum -y groupinstall "Oriya Support"
  yum -y groupinstall "Persian Support"
  yum -y groupinstall "Polish Support"
  yum -y groupinstall "Portuguese Support"
  yum -y groupinstall "Punjabi Support"
  yum -y groupinstall "Romanian Support"
  yum -y groupinstall "Russian Support"
  yum -y groupinstall "Sanskrit Support"
  yum -y groupinstall "Sardinian Support"
  yum -y groupinstall "Serbian Support"
  yum -y groupinstall "Sindhi Support"
  yum -y groupinstall "Sinhala Support"
  yum -y groupinstall "Slovak Support"
  yum -y groupinstall "Slovenian Support"
  yum -y groupinstall "Somali Support"
  yum -y groupinstall "Southern Ndebele Support"
  yum -y groupinstall "Southern Sotho Support"
  yum -y groupinstall "Spanish Support"
  yum -y groupinstall "Swahili Support"
  yum -y groupinstall "Swati Support"
  yum -y groupinstall "Swedish Support"
  yum -y groupinstall "Tagalog Support"
  yum -y groupinstall "Tajik Support"
  yum -y groupinstall "Tamil Support"
  yum -y groupinstall "Telugu Support"
  yum -y groupinstall "Tetum Support"
  yum -y groupinstall "Thai Support"
  yum -y groupinstall "Tibetan Support"
  yum -y groupinstall "Tsonga Support"
  yum -y groupinstall "Tswana Support"
  yum -y groupinstall "Turkish Support"
  yum -y groupinstall "Turkmen Support"
  yum -y groupinstall "Ukrainian Support"
  yum -y groupinstall "Upper Sorbian Support"
  yum -y groupinstall "Urdu Support"
  yum -y groupinstall "Uzbek Support"
  yum -y groupinstall "Venda Support"
  yum -y groupinstall "Vietnamese Support"
  yum -y groupinstall "Walloon Support"
  yum -y groupinstall "Welsh Support"
  yum -y groupinstall "Xhosa Support"
  yum -y groupinstall "Zulu Support"


-----

  yum -y groupinstall "Load Balancer"

  yum -y groupinstall "Load Balancer"

-----

  yum -y groupinstall "Resilient Storage"

  yum -y groupinstall "Resilient Storage"

-----

  yum -y groupinstall "Scalable Filesystem Support"

  yum -y groupinstall "Scalable Filesystem"


-----

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


-----

  yum -y groupinstall "System Management"

  yum -y groupinstall "Messaging Client Support"
  yum -y groupinstall "SNMP Support"
  yum -y groupinstall "System Management"
  yum -y groupinstall "System Management and Messaging Server support"
  yum -y groupinstall "Web-Based Enterprise Management"

-----

  yum -y groupinstall "Virtualization"

  yum -y groupinstall "Virtualization"
  yum -y groupinstall "Virtualization Client"
  yum -y groupinstall "Virtualization Platform"
  yum -y groupinstall "Virtualization Tools"

-----

  yum -y groupinstall "Web Services"

  yum -y groupinstall "PHP Support"
  yum -y groupinstall "TurboGears application framework"
  yum -y groupinstall "Web Server"
  yum -y groupinstall "Web Servlet Engine"

   Arabic Support [ar]
   Armenian Support [hy]
   Assamese Support [as]
   Bengali Support [bn]
   Bhutanese Support [dz]
   Chinese Support [zh]
   Ethiopic Support [am]
   Georgian Support [ka]
   Gujarati Support [gu]
   Hebrew Support [he]
   Hindi Support [hi]
   Inuktitut Support [iu]
   Japanese Support [ja]
   Kannada Support [kn]
   Khmer Support [km]
   Konkani Support [kok]
   Korean Support [ko]
   Kurdish Support [ku]
   Lao Support [lo]
   Maithili Support [mai]
   Malayalam Support [ml]
   Marathi Support [mr]
   Myanmar (Burmese) Support [my]
   Oriya Support [or]
   Punjabi Support [pa]
   Sinhala Support [si]
   Tajik Support [tg]
   Tamil Support [ta]
   Telugu Support [te]
   Thai Support [th]
   Urdu Support [ur]
   Venda Support [ve]
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
   Afrikaans Support [af]
   Albanian Support [sq]
   Amazigh Support [ber]
   Azerbaijani Support [az]
   Basque Support [eu]
   Belarusian Support [be]
   Brazilian Portuguese Support [pt_BR]
   Breton Support [br]
   Bulgarian Support [bg]
   Catalan Support [ca]
   Chhattisgarhi Support [hne]
   Chichewa Support [ny]
   Coptic Support [cop]
   Croatian Support [hr]
   Czech Support [cs]
   Danish Support [da]
   Dutch Support [nl]
   English (UK) Support [en_GB]
   Esperanto Support [eo]
   Estonian Support [et]
   Faroese Support [fo]
   Fijian Support [fj]
   Filipino Support [fil]
   Finnish Support [fi]
   French Support [fr]
   Frisian Support [fy]
   Friulian Support [fur]
   Gaelic Support [gd]
   Galician Support [gl]
   German Support [de]
   Greek Support [el]
   Hiligaynon Support [hil]
   Hungarian Support [hu]
   Icelandic Support [is]
   Indonesian Support [id]
   Interlingua Support [ia]
   Irish Support [ga]
   Italian Support [it]
   Kashmiri Support [ks]
   Kashubian Support [csb]
   Kazakh Support [kk]
   Kinyarwanda Support [rw]
   Latin Support [la]
   Latvian Support [lv]
   Lithuanian Support [lt]
   Low Saxon Support [nds]
   Luxembourgish Support [lb]
   Macedonian Support [mk]
   Malagasy Support [mg]
   Malay Support [ms]
   Maltese Support [mt]
   Manx Support [gv]
   Maori Support [mi]
   Mongolian Support [mn]
   Nepali Support [ne]
   Northern Sotho Support [nso]
   Norwegian Support [nb]
   Occitan Support [oc]
   Persian Support [fa]
   Polish Support [pl]
   Portuguese Support [pt]
   Romanian Support [ro]
   Russian Support [ru]
   Sanskrit Support [sa]
   Sardinian Support [sc]
   Serbian Support [sr]
   Sindhi Support [sd]
   Slovak Support [sk]
   Slovenian Support [sl]
   Southern Ndebele Support [nr]
   Southern Sotho Support [st]
   Spanish Support [es]
   Swahili Support [sw]
   Swati Support [ss]
   Swedish Support [sv]
   Tagalog Support [tl]
   Tetum Support [tet]
   Tibetan Support [bo]
   Tsonga Support [ts]
   Tswana Support [tn]
   Turkish Support [tr]
   Turkmen Support [tk]
   Ukrainian Support [uk]
   Upper Sorbian Support [hsb]
   Uzbek Support [uz]
   Vietnamese Support [vi]
   Walloon Support [wa]
   Welsh Support [cy]
   Xhosa Support [xh]
   Zulu Support [zu]


yum -y update
yum -y upgrade

#yum -y groupinstall desktop
#}


#function hhh () {
cd /root/downs/
tar xvjf iRedMail-0.8.3.tar.bz2
cd iRedMail-0.8.3
bash iRedMail.sh
#}

#function hhh () {
#yum -y update
#yum -y upgrade

#tar cvf ~/y.tar /var/cache/yum

#rpm -ivh --force /root/downs/rvm-ruby-1.17.6-0.el6.noarch.rpm
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
