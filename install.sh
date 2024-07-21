#!/bin/bash

# Input value
function typeVal() {
	while :
	do
		echo -n -e "$1\n > " >&2 && read rtn && echo "" >&2

		if [ -n "$rtn" ]; then
			break
		fi
	done
	echo $rtn
}

# Edit pacman.conf
function confPacman() {
	sed -i -e "/^#\(Color\|VerbosePkgLists\|ParallelDownloads\)/s/^#//" $1
	sed -i -e "/\[multilib\]/,/Include/"'s/^#//' $1
}

# Search CPU vendor
if [ -n "`lscpu | grep Intel`" ]; then
	ucode=intel-ucode
elif [ -n "`lscpu | grep AMD`" ]; then
	ucode=amd-ucode
fi

# Input install partition
while :
do
	part=/dev/$(typeVal "Type the partition.")

	if [[ -e $part ]]; then
		if [ "$part" == "nvme*" ]; then
			part_boot=${part}p1
			part_root=${part}p2
		else
			part_boot=${part}1
			part_root=${part}2
		fi
		break
	else
		echo -e "Not found \"${part}\"."
	fi
done

# Input some value(create user/user password/root password/hostname)
rootpw=$(typeVal "Type root password")
usernm=$(typeVal "Type user name.")
userpw=$(typeVal "Type $usernm password.")
hostnm=$(typeVal "type host name")

# Create partition
sgdisk -Z $part
sgdisk -o $part
sgdisk -n 1:0:+300M -t 1:ef00 $part
sgdisk -n 2:0: -t 2:8304 $part

# Format partitions
mkfs.vfat -F32 $part_boot
mkfs.ext4 $part_root

# Mount Partition
mount $part_root /mnt
mount --mkdir $part_boot /mnt/boot

# setting pacman / Install Base packages
confPacman "/etc/pacman.conf"
pacman --noconfirm -Sy archlinux-keyring
pacstrap /mnt base base-devel linux-zen linux-zen-headers linux-firmware 
pacstrap /mnt booster git go wget neovim networkmanager $ucode pacman-contrib clamav ufw man man-db man-pages openssh reflector
confPacman "/mnt/etc/pacman.conf"

# Gen-fstab / Change mask
genfstab -U /mnt >> /mnt/etc/fstab

# arch-chroot
arch-chroot /mnt << _EOF_

# Update mirrorlist
reflector --country Japan --age 24 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# Setting Time
ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime
hwclock --systohc

# Setting locale/vconsole
echo LANG=\"en_US.UTF-8\" > /etc/locale.conf
echo KEYMAP=\"jp106\"     > /etc/vconsole.conf

# Locale-gen
sed -i -e '/^#\(ja_JP\|en_US\).UTF-8/s/^#//' /etc/locale.gen
locale-gen

# Setting Hosts
echo $hostnm > /etc/hostname
echo -e "127.0.0.1 localhost\n::1 localhost\n127.0.1.1 ${hostnm}.localdomain ${hostnm}" > /etc/hosts

# Create User
useradd -m -G wheel $usernm
echo root:${rootpw} | chpasswd
echo ${usernm}:${userpw} | chpasswd

# Install bootctl
bootctl install
echo -e "default arch.conf\ntimeout 4\nconsole-mode max\neditor no" > /boot/loader/loader.conf
echo -e "title Arch Linux\nlinux /vmlinuz-linux-zen\ninitrd ${ucode}.img\ninitrd /booster-linux-zen.img\noptions root=$(blkid -o export ${part_root} | grep ^PARTUUID) rw" > /boot/loader/entries/arch.conf

# Setting sudoers
sed -e '/%wheel ALL=(ALL:ALL) ALL/s/^# //' /etc/sudoers | EDITOR=tee visudo > /dev/null

# Install AUR Helper(yay)
echo $usernm ALL=NOPASSWD: ALL | EDITOR='tee -a' visudo > /dev/null
su $usernm << __EOF__
cd
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
__EOF__
rm -rf /home/${usernm}/yay
sed -e 's/${usernm} ALL=NOPASSWD: ALL//g' /etc/sudoers | EDITOR=tee visudo > /dev/null

# Enable Services
systemctl enable NetworkManager.service systemd-resolved.service systemd-timesyncd.service paccache.timer fstrim.timer sshd.service

_EOF_
