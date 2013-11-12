#!/bin/bash

###############################################################################################
# Complete ISPConfig setup script for Debian 7.         						 			                    #
# Drew Clardy																				                                          #
# http://drewclardy.com							                                                          #
###############################################################################################


# Check if user is root
if [ $(id -u) != "0" ]; then
    echo "Error: You must be root to run this script, please use the root user to install the software."
    exit 1
fi

back_title="Debian 7 System Setup"

questions (){

  PKG_OK=$(dpkg-query -W --showformat='${Status}\n' whiptail|grep "install ok installed")
  echo Checking for whiptail: $PKG_OK
  if [ "" == "$PKG_OK" ]; then
    echo "No whiptail installed. Setting up whiptail."
    apt-get update
    apt-get --force-yes --yes install whiptail
  fi

  while [ "x$serverIP" == "x" ]
  do
    serverIP=$(whiptail --title "Server IP" --backtitle "$back_title" --inputbox "Please specify a Server IP" --nocancel 10 50 3>&1 1>&2 2>&3)
  done
  while [ "x$HOSTNAMESHORT" == "x" ]
  do
    HOSTNAMESHORT=$(whiptail --title "Short Hostname" --backtitle "$back_title" --inputbox "Please specify a Short Hostname" --nocancel 10 50 3>&1 1>&2 2>&3)
  done
  while [ "x$HOSTNAMEFQDN" == "x" ]
  do
    HOSTNAMEFQDN=$(whiptail --title "Fully Qualified Hostname" --backtitle "$back_title" --inputbox "Please specify a Fully Qualified Hostname" --nocancel 10 50 3>&1 1>&2 2>&3)
  done
  
  while [ "x$db_server" == "x" ]
  do
    db_server=$(whiptail --title "MariaDB Cluster" --backtitle "$back_title" --nocancel --radiolist "Select Web Server Software" 10 50 2 "MariaDB" "(default)" ON 3>&1 1>&2 2>&3)
  done

  if (whiptail --title "Install Quota" --backtitle "$back_title" --yesno "Setup User Quotas?" 10 50) then
    quota=Yes
  else
    quota=No
  fi

}

debian_install_basic (){

#Set hostname and FQDN
sed -i "s/${serverIP}.*/${serverIP} ${HOSTNAMEFQDN} ${HOSTNAMESHORT}/" /etc/hosts
echo "$HOSTNAMESHORT" > /etc/hostname
/etc/init.d/hostname.sh start >/dev/null 2>&1

#Updates server and install commonly used utilities
cp /etc/apt/sources.list /etc/apt/sources.list.backup
cat > /etc/apt/sources.list <<EOF
deb http://ftp.us.debian.org/debian/ wheezy main contrib non-free
deb-src http://ftp.us.debian.org/debian/ wheezy main contrib non-free

deb http://security.debian.org/ wheezy/updates main contrib non-free
deb-src http://security.debian.org/ wheezy/updates main contrib non-free

# wheezy-updates, previously known as 'volatile'
deb http://ftp.us.debian.org/debian/ wheezy-updates main contrib non-free
deb-src http://ftp.us.debian.org/debian/ wheezy-updates main contrib non-free

# DotDeb
deb http://packages.dotdeb.org wheezy all
deb-src http://packages.dotdeb.org wheezy all
EOF

wget http://www.dotdeb.org/dotdeb.gpg
cat dotdeb.gpg | apt-key add -
apt-get update
apt-get -y upgrade
apt-get -y install vim-nox dnsutils unzip nano htop git dialog tmux

dpkg-reconfigure tzdata

echo "dash dash/sh boolean false" | debconf-set-selections
dpkg-reconfigure -f noninteractive dash > /dev/null 2>&1

#Synchronize the System Clock
apt-get -y install ntp ntpdate

} #end function debian_install_DashNTP

debian_install_maria_cluster () {
apt-get install python-software-properties
apt-key adv --recv-keys --keyserver keyserver.ubuntu.com 0xcbcb082a1bb943db
add-apt-repository 'deb http://mirror.jmu.edu/pub/mariadb/repo/5.5/debian wheezy main'

apt-get update
apt-get install mariadb-galera-server galera

} #END CLUSTER


#Execute functions#
if [ -f /etc/debian_version ]; then 
  questions
  debian_install_basic
  debian_install_maria_cluster

  if [ $jailkit == "Yes" ]; then
		#debian_install_Jailkit
	fi

else echo "Unsupported Linux Distribution."
fi		

#End execute functions#
