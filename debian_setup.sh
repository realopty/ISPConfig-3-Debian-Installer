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

back_title="ISPConfig 3 System Installer"

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
  while [ "x$web_server" == "x" ]
  do
    web_server=$(whiptail --title "Web Server" --backtitle "$back_title" --nocancel --radiolist "Select Web Server Software" 10 50 2 "Apache" "(default)" ON "NginX" "" OFF 3>&1 1>&2 2>&3)
  done
  while [ "x$mail_server" == "x" ]
  do
    mail_server=$(whiptail --title "Mail Server" --backtitle "$back_title" --nocancel --radiolist "Select Mail Server Software" 10 50 2 "Dovecot" "(default)" ON "Courier" "" OFF 3>&1 1>&2 2>&3)
  done
  while [ "x$sql_server" == "x" ]
  do
    sql_server=$(whiptail --title "SQL Server" --backtitle "$back_title" --nocancel --radiolist "Select SQL Server Software" 10 50 2 "MySQL" "(default)" ON "MariaDB" "" OFF 3>&1 1>&2 2>&3)
  done
  while [ "x$mysql_pass" == "x" ]
  do
    mysql_pass=$(whiptail --title "MySQL Root Password" --backtitle "$back_title" --inputbox "Please specify a MySQL Root Password" --nocancel 10 50 3>&1 1>&2 2>&3)
  done
  if (whiptail --title "Install Quota" --backtitle "$back_title" --yesno "Setup User Quotas?" 10 50) then
    quota=Yes
  else
    quota=No
  fi
  if (whiptail --title "Install Mailman" --backtitle "$back_title" --yesno "Setup Mailman?" 10 50) then
    mailman=Yes
  else
    mailman=No
  fi
  if (whiptail --title "Install Jailkit" --backtitle "$back_title" --yesno "Setup User Jailkits?" 10 50) then
    jailkit=Yes
  else
    jailkit=No
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
deb http://ftp.de.debian.org/debian/ wheezy main contrib non-free
deb-src http://ftp.de.debian.org/debian/ wheezy main contrib non-free

deb http://security.debian.org/ wheezy/updates main contrib non-free
deb-src http://security.debian.org/ wheezy/updates main contrib non-free

# wheezy-updates, previously known as 'volatile'
deb http://ftp.de.debian.org/debian/ wheezy-updates main contrib non-free
deb-src http://ftp.de.debian.org/debian/ wheezy-updates main contrib non-free

# DotDeb
deb http://packages.dotdeb.org wheezy all
deb-src http://packages.dotdeb.org wheezy all
EOF

wget http://www.dotdeb.org/dotdeb.gpg
cat dotdeb.gpg | apt-key add -
apt-get update
apt-get -y upgrade
apt-get -y install vim-nox dnsutils unzip 

} #end function debian_install_basic

debian_install_DashNTP (){

echo "dash dash/sh boolean false" | debconf-set-selections
dpkg-reconfigure -f noninteractive dash > /dev/null 2>&1

#Synchronize the System Clock
apt-get -y install ntp ntpdate

} #end function debian_install_DashNTP


#Execute functions#
if [ -f /etc/debian_version ]; then 
  questions
  debian_install_basic
  debian_install_DashNTP

  if [[ $sql_server == "MariaDB" && $mail_server ==  "Dovecot" ]]; then
      debian_install_MariaDBDovecot
  fi

  if [ $jailkit == "Yes" ]; then
		debian_install_Jailkit
	fi
  debian_install_SquirrelMail
  install_ISPConfig
else echo "Unsupported Linux Distribution."
fi		

#End execute functions#
