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
# DateUpdate:   02 Feb 2013
# Version:      0.6

cd ~/

function f_menu () {
  echo "1) proxy | 2) \"selinux\" y \"firewall\"";
  echo "3) red";
  echo "";
  echo "";
  echo "";
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
      ecard="/opt/ifcfg-eth"$netnr"";
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
      narr=$(echo $ethipa | tr "." | tr " ");

      narra=${narr[0]}"\."${narr[1]}"\."${narr[2]}"\.";
      ethgwy=$narra"1";
      ethbro=$narra"255";
      ethnwk=$narra"0";
      mv $ecard $ecard"-"$e
      echo "DEVICE=eth"$netnr"" > $ecard
      ##TYPE=ethernet
      echo "TYPE=ethernet" >> $ecard
      ##BOOTPROTO=none,bootp,dhcp
      echo "BOOTPROTO=none" >> $ecard
      ##ONBOOT=yes,no
      echo "ONBOOT=yes" >> $ecard
      echo "IPADDR="$ethipa"" >> $ecard
      echo "NETMASK=255.255.255.0" >> $ecard
      echo "GATEWAY="$ethgwy"" >> $ecard
      echo "NETWORK="$ethnwk"" >> $ecard
      echo "BROADCAST="$ethbro"" $ecard
      echo "DNS1="$ethdn1"" >> $ecard
      echo "NM_CONTROLLED=no" >> $ecard
      echo "USERCTL=no" >> $ecard
      echo "DEFROUTE=yes" >> $ecard
      echo "IPV4_FAILURE_FATAL=yes" >> $ecard
      echo "" >> $ecard
      if [ "$netnr" -gt "2" ]; then d="";
        rednum="N";
      else
        echo -n "Desea configurar manualmente otra tarjeta de red? (S/N): "; read rednum;
      fi
      netnr=$(( $netnr + 1 ));
    done
#  fi

#    echo -n "Cuantas tarjetas de red configurara? (1/2): "; read rednum;
#    if [[ $rednum == "2" ]]; then


  else
    echo "terminando configuracion de red";
  fi
}

function hhh () {
#}
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
    "99" | "salir" | "exit" | "quit") seleccion="exit"; ;;
    *) f_menu; ;;
  esac
done

#function hhh () {
}



function dasd () {














ifconfig eth0 192.168.1.204 up
route add default gw 192.168.1.1
echo "nameserver 8.8.8.8">/etc/resolf.conf

/etc/sysconfig/network-scripts/ifcfg-eth0

#HWADDR=52:54:00:C3:35:4E
IPV6INIT=no
BROADCAST=192.168.16.255
DNS1=172.16.0.2
#UUID=915e01ed-6c45-4a7f-be61-4a175dcb0151
BOOTPROTO=none
NAME=""
MACADDR=""
NM_CONTROLLED=yes
TYPE=Ethernet
DEVICE=eth0
PREFIX=24
NETMASK=255.255.255.0
MTU=""
IPADDR=192.168.16.210
DEFROUTE=yes
NETWORK=192.168.16.0
IPV4_FAILURE_FATAL=yes
ONBOOT=yes







#u=PWD
#wget http://192.168.16.210/pub/floss/pkgs/y.tar
#cd /
#tar xvf $u/y.tar
#cd $u
}
yum -y update
yum -y upgrade
yum -y install wget mc elinks xinetd ksh

mkdir /root/downs
cd /root/downs
wget -c https://raw.github.com/kseltar/rvm-rpm/master/RPMS/noarch/rvm-ruby-1.17.6-0.el6.noarch.rpm
###-O /root/downs/rvm-ruby-1.17.6-0.el6.noarch.rpm

wget -c http://ufpr.dl.sourceforge.net/project/webadmin/webmin/1.610/webmin-1.610-1.noarch.rpm -O /root/downs/webmin-1.610-1.noarch.rpm
wget -c http://www.princexml.com/download/prince-8.1-4.centos60.x86_64.rpm -O /root/downs/prince-8.1-4.centos60.x86_64.rpm
wget -c http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm -O /root/downs/epel-release-6-8.noarch.rpm
wget -c http://pkgs.repoforge.org/rpmforge-release/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm -O /root/downs/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm
wget -c http://repo.webtatic.com/yum/el6/x86_64/webtatic-release-6-2.noarch.rpm -O /root/downs/webtatic-release-6-2.noarch.rpm
wget -c http://packages.atrpms.net/RPM-GPG-KEY.atrpms -O /root/downs/RPM-GPG-KEY.atrpms
wget -c https://bitbucket.org/zhb/iredmail/downloads/iRedMail-0.8.3.tar.bz2 -O /root/downs/iRedMail-0.8.3.tar.bz2
wget -c http://ufpr.dl.sourceforge.net/project/phpmyadmin/phpMyAdmin/4.0.0-alpha1/phpMyAdmin-4.0.0-alpha1-all-languages.tar.gz -O /root/downs/phpMyAdmin-4.0.0-alpha1-all-languages.tar.gz
wget -c http://ufpr.dl.sourceforge.net/project/phppgadmin/phpPgAdmin%20%5Bstable%5D/phpPgAdmin-5.0/phpPgAdmin-5.0.4.tar.gz -O /root/downs/phpPgAdmin-5.0.4.tar.gz

yum -y install /root/downs/epel-release-6-8.noarch.rpm
yum -y install /root/downs/rpmforge-release-0.5.2-2.el6.rf.x86_64.rpm
yum -y install /root/downs/root/downs/webtatic-release-6-2.noarch.rpm
yum -y install /root/downs/webmin-1.610-1.noarch.rpm
yum -y install /root/downs/prince-8.1-4.centos60.x86_64.rpm
rpm --import /root/downs/RPM-GPG-KEY.atrpms
echo "" >
atrp="/etc/yum.repos.d/atrpms.repo";
echo "" > $atrp
echo "[atrpms]" >> $atrp
echo "name=Fedora Core $releasever - $basearch - ATrpms" >> $atrp
echo "baseurl=http://dl.atrpms.net/el$releasever-$basearch/atrpms/stable" >> $atrp
echo "gpgkey=http://ATrpms.net/RPM-GPG-KEY.atrpms" >> $atrp
echo "gpgcheck=0" >> $atrp
echo "enable=1" >> $atrp
echo "" >> $atrp


yum -y update
yum -y upgrade

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
#yum -y groupinstall desktop
#}


#function hhh () {
cd /root/downs/
tar xvjf iRedMail-0.8.3.tar.bz2
cd iRedMail-0.8.3
bash iRedMail.sh
#}

function hhh () {
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
