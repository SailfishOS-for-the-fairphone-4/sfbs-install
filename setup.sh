#!/bin/sh


usage() {
cat << EOF
Usage: $0 [OPTION] ..."
	-h, --help			You're reading it
	-p, --install-all-packages	Install all the needed packages
	-i, --install		
      	-v, --version			Get the current version
EOF
}

OPTIONS=$(getopt -o hpiv -l help,install-all-packages,do-not-install,version,install -- "$@")

if [ $? -ne 0 ]; then
    echo "getopt error"
    exit 1
fi

unset INSTALL_PACKAGES FULL_INSTALL GET_VERSION INSTALL TARGET
eval set -- $OPTIONS
while true; do
    case "$1" in
      -h|--help) usage ;;
      -p|--install-all-packages) INSTALL_PACKAGES=1;;
      -i|--install) case "${@: -1}" in
      			"fullbuild")  FULL_INSTALL=1 TARGET="fullbuild";;
		      	*) INSTALL=1 ;;
		    esac ;;
      -v|--version) GET_VERSION=1 ;;
      --)        shift ; break ;;
    esac
    shift
done

#!/bin/sh

# TO-DO SFBOOTSTRAP!
# Extra prompts for debugging
# Add docker support
# DEPRECATED
# no provider fo droid-configs

# DONE
# Check Git-SSH
# remove second Git requireMENT?
# check for requirements?
# remove I/O-prints
# auto color.ui
# rework setup.sh and utils.sh
# hybris AFTER repo sync. So the 
# no force if succes fetch
# pybind remove
# check for || return 
# automated Echo's for auto color?

INPUTPKGS="pkgs.rq"

# Console/CLI color I/O
merror() { >&2 echo -e "\e[01;31m!! $* \e[00m" 
}
mgood() { echo -e "\e[01;32m* $* \e[00m" 
}
minstall() { echo -e "\e[01;33m* $* \e[00m" 
}
minfo() { echo -e "\e[01;34m* $* \e[00m" 
}


silent(){
	"$@"&>/dev/null
}

install_packages() {
	minstall "Updating/Upgrading package Manager..."
	silent sudo apt-get update 
	echo y | silent sudo apt-get upgrade
	pkgs=""
	while IFS= read -r pkg
	do
		pkgs+="$pkg "
	done < "$INPUTPKGS"
	
	minstall "Installing: $pkgs"
	echo y | sudo apt-get install $pkgs
}


git_check_ssh_auth(){
	minstall "Checking GitHub-ssh-connection..."
	ssh -T git@github.com &>/dev/null; [ $? -eq 1 ] || return 0
	mgood "Git-ssh is successfully configured!"
	return 1
}

git_check_setup_config(){
	if [ ! -f "$HOME/.gitconfig" ]; then
		merror "No Git-Configuration found!"
		minfo "Run: \n\tgit config --global user.name \"yourname\" \
			   \n\tgit config --global user.email \"your@email.com\"\
			   \n\tgit config --global color.ui \"auto\""
	   	return 0
	fi
	if [ ! -f "$HOME/.ssh/id_rsa.pub" ]; then
		merror "GitHub-ssh is not setup yet!"
		minfo "Run:\n\tssh-keygen"
		minfo "Make sure you add the .ssh/id_rsa.pub to your GitHub-account!";
		return 0
	fi 
	
	git_check_ssh_auth; [ $? -eq 1 ] && return 1
	merror "The config_setup did not succeed..."
	minfo "Make sure you add the .ssh/id_rsa.pub to your GitHub-account!";
	return 0
}

start_installer(){
	git_check_setup_config; [ $? -eq 1 ] || return
	
	if [ "$1" == "fullbuild" ]; then
		./sfbootstrap/sfbootstrap.sh init || return
		./sfbootstrap/sfbootstrap.sh chroot setup || return
		./sfbootstrap/sfbootstrap.sh sync || return
		./sfbootstrap/sfbootstrap.sh build hal || return
		./sfbootstrap/sfbootstrap.sh build packages || return
	# else
		#TO DO
		# check (w prompt?) which steps we want to do?
	fi
}

get_version(){
	mgood "Version: Beta"
}

main(){
	[ "$GET_VERSION" ] && get_version;
	[ "$INSTALL_PACKAGES" ] && install_packages;
	[[ "$INSTALL"  || "$FULL_INSTALL" ]] && start_installer $1;
}

main $TARGET
