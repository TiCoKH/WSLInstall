# Basic setup information

# Install a fresh system
install
url --url="http://linux.int.net.nokia.com/ftp/rhel/7.7/Client/x86_64/os/"

# Keyboard layouts
keyboard us

# Root password
# rootpw --iscrypted $6$if.5zqyPMclY6s7d$F8189vVlouusVOEx3Vv//4NVrhtMGheo6EeDi0CNW10wg3Nhdf.2q8HPxpusU17VvYQOorzdwCGwg6dnG0NUT.
rootpw --lock --iscrypted locked

# System timezone
timezone --isUtc --nontp UTC

# SELinux configuration
selinux --enforcing

firewall --disabled

# Network information
network --bootproto=dhcp --device=link --activate --onboot=on
shutdown
# network --bootproto=dhcp --onboot=on --ipv6=auto --hostname=localhost.localdomain

# System bootloader configuration
# bootloader --driveorder=sda --iscrypted --password=grub.pbkdf2.sha512.10000.E9D1B3AE387ABAF6B016C3CD26E2517315A7F659126823C8C3A43E1F0D292B059E45808434689B6026E80353E9C89E34FC667FB1BD2D352A8BAFD3B54609F58B.FD4DB6D356452240320870D8E40FA7FC566985F5B2836E325B304C70321AB6DAC26E97BF10A5046D21114E8D039AA79D70741315BDCF87ABDE0021009B76F8EE
bootloader --disable

# System language
lang en_US

# Package repositories
# Need to be after network section to work
repo --name="rhel-optional" --baseurl=http://linux.int.net.nokia.com/ftp/rhel/7.7/Client/x86_64/os/Optional/
repo --name="rhel-supplementary" --baseurl=http://linux.int.net.nokia.com/ftp/rhel/7.7/Client/x86_64/os/Supplementary/
repo --name="epel" --baseurl=http://linux.int.net.nokia.com/ftp/rhel/epel/7/x86_64/
repo --name="nokia-base" --baseurl=http://linux.int.net.nokia.com/ftp/nokia/rhel/releases/7.7/x86_64/os/
repo --name="SL" --baseurl=http://ftp.scientificlinux.org/linux/scientific/7x/x86_64/os/ --cost=100
repo --name="SL Updates" --baseurl=http://ftp.scientificlinux.org/linux/scientific/7x/x86_64/updates/ --cost=100

# System authorization information
authconfig --passalgo=sha512 --enableshadow --enablesssd --enablesssdauth --enablepamaccess --enablemkhomedir --enablefingerprint

# Disk setup
zerombr
clearpart --all --initlabel
part / --size 3000 --fstype ext4

# EULA - auto approve end user license
eula --agreed

# Package setup
%packages --instLangs=en --nocore
bind-utils
bash
yum
sudo
openssh-clients
vim
centos-release
less
-kernel*
-*firmware
-firewalld-filesystem
-os-prober
-gettext*
-GeoIP
-bind-license
-freetype
iputils
iproute
systemd
rootfiles
-libteam
-teamd
tar
passwd
yum-utils
yum-plugin-ovl
man-pages
man-db
man
bash-completion
wget

#Nokia Groups
#@base
#@core
#@directory-client
#@network-file-system-client
#@networkmanager-submodules
#@security-tools
@x11

#Nokia Packages
#evolution-mapi
ntpdate
#oddjob-mkhomedir
redhat-lsb-core
#sssd
#sssd-client
tcp_wrappers
tcsh
nspluginwrapper
#tigervnc
#tigervnc-server
noel-userinfo
-subscription-manager*
initial-setup

#NOKIA-ADDONS
nokia-config-auth
nokia-config-certs
nokia-config-ntpd
nokia-config-yum-workstation
nokia-config-yum-epel
nokia-libs-python
nokia-linux-docs
nokia-register
nokia-release

#end packages
%end

%pre

# Don't add the anaconda build logs to the image
# see /usr/share/anaconda/post-scripts/99-copy-logs.ks
touch /tmp/NOSAVE_LOGS
%end

%post --log=/anaconda-post.log

# Install standard Red Hat RPM GPG keys
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-NOEL-7
rpm --import /etc/pki/RPM-GPG-KEY-NOEL-NEW-7
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7

# remove stuff we don't need that anaconda insists on
# kernel needs to be removed by rpm, because of grubby
rpm -e kernel

yum -y remove bind-libs bind-libs-lite dhclient dhcp-common dhcp-libs \
  dracut-network e2fsprogs e2fsprogs-libs ebtables ethtool file \
  firewalld freetype gettext gettext-libs grub2 grub2-tools \
  grubby initscripts iproute iptables kexec-tools libcroco libgomp \
  libmnl libnetfilter_conntrack libnfnetlink libselinux-python lzo \
  libunistring os-prober python-decorator python-slip python-slip-dbus \
  snappy sysvinit-tools linux-firmware GeoIP firewalld-filesystem \
  qemu-guest-agent

yum clean all

# Remove subscription-manager and RNH stuff
rpm -e subscription-manager-firstboot subscription-manager-gui subscription-manager > /dev/null 2>&1 || :
rpm -e rhnlib rhnsd rhn-check rhn-client-tools rhn-setup rhn-setup-gnome yum-rhn-plugin > /dev/null 2>&1 || :

#clean up unused directories
rm -rf /boot
rm -rf /etc/firewalld

# Lock roots account, keep roots account password-less.
passwd -l root

#LANG="en_US"
#echo "%_install_lang $LANG" > /etc/rpm/macros.image-language-conf

awk '(NF==0&&!done){print "override_install_langs=en_US.utf8";done=1}{print}' \
    < /etc/yum.conf > /etc/yum.conf.new
mv /etc/yum.conf.new /etc/yum.conf
echo 'container' > /etc/yum/vars/infra

##Setup locale properly
# Commenting out, as this seems to no longer be needed
#rm -f /usr/lib/locale/locale-archive
#localedef -v -c -i en_US -f UTF-8 en_US.UTF-8

## Remove some things we don't need
rm -rf /var/cache/yum/x86_64
rm -f /tmp/ks-script*
rm -rf /etc/sysconfig/network-scripts/ifcfg-*
# do we really need a hardware database in a container?
rm -rf /etc/udev/hwdb.bin
rm -rf /usr/lib/udev/hwdb.d/*

## Systemd fixes
# no machine-id by default.
:> /etc/machine-id
# Fix /run/lock breakage since it's not tmpfs in docker
umount /run
systemd-tmpfiles --create --boot
# Make sure login works
rm /var/run/nologin

# Some shell tweaks
echo "source /etc/vimrc" > /etc/skel/.vimrc
echo "set background=dark" >> /etc/skel/.vimrc
echo "set visualbell" >> /etc/skel/.vimrc
echo "set noerrorbells" >> /etc/skel/.vimrc

echo "\$include /etc/inputrc" > /etc/skel/.inputrc
echo "set bell-style none" >> /etc/skel/.inputrc
echo "set show-all-if-ambiguous on" >> /etc/skel/.inputrc
echo "set show-all-if-unmodified on" >> /etc/skel/.inputrc

#Fix ping
chmod u+s /usr/bin/ping

#Upgrade to the latest
yum -y upgrade

#Generate installtime file record
/bin/date +%Y%m%d_%H%M > /etc/BUILDTIME

# Nokia
# Add needed user/group information locally
groupadd -g 55555 everybody

# Profile information
echo "profile=noel-desktop" >> /etc/sysconfig/nokia-sysprofile

authconfig --passalgo=sha512 --enableshadow --enablesssd --enablesssdauth --enablepamaccess --enablemkhomedir --enablefingerprint

#end post
%end

%addon com_redhat_kdump --disable --reserve-mb='auto'

%end
