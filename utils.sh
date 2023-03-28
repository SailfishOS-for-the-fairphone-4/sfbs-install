#!/bin/sh

SUDO=sudo
PKGMNGR=apt-get
INPUTPKGS="requirements.txt"

minfo() {
    echo -e "\e[01;34m* $* \e[00m"
}

merror() {
	>&2 echo -e "\e[01;31m!! $* \e[00m"
}

minstall() {
	echo -e "\e[01;33m* $* \e[00m"
}


install_packages() {
	minstall "Updating package Manager..."
	$SUDO $PKGMNGR update
	while IFS= read -r pkgs 
	do
		minstall "Installing: $pkgs"
		yes | $SUDO $PKGMNGR install $pkgs
	done < "$INPUTPKGS"
}


start_install(){
	SFB_ROOT=$(pwd)/sfbootstrap
	if [ ! -f "$HOME/.gitconfig" ]; then
		minfo "Setting up Git..."
		git config --global user.name "Jordieboyz"
		git config --global user.email "boer.jort@gmail.com"
	fi
	if [ ! -d "$SFB_ROOT" ]; then
		git clone https://github.com/JamiKettunen/sfbootstrap.git
	fi
	
	cd $SFB_ROOT
	./sfbootstrap.sh init 
	./sfbootstrap.sh chroot setup
	./sfbootstrap.sh sync
	./sfbootstrap.sh build hal
	./sfbootstrap.sh build packages
	cd ..
}
get_version() { 
	echo "getting curent version..."
}
