#!/bin/sh

usage() {
cat << EOF
Usage: $0 [OPTION] ..."
	-h, --help			You're reading it
	-p, --install-all-packages	Install all the needed packages
	-i, --install			Start the main build process
	-m, --enable-manual-setup	Enable to continue setting up manually at any point by running sfossdk in the $HOME directory
      	-v, --version			Get the current sfbs-install version
EOF
}

OPTIONS=$(getopt -o hpmiv -l help,install-all-packages,version,install,enable-manual-setup -- "$@")

unset INSTALL_PACKAGES FULL_INSTALL GET_VERSION INSTALL TARGET ENABLE_MANUAL_SETUP

# If there are no cmd args; get packages and fullbuild
if [[ $# -eq 0 && -z "$1" ]]; then
    INSTALL_PACKAGES=1
    INSTALL=1 
fi

eval set -- $OPTIONS
while true; do
    case "$1" in
      -h|--help) usage; return;;
      -p|--install-all-packages) INSTALL_PACKAGES=1;;
      -i|--install)  INSTALL=1 ;;
      -m|--enable-manual-setup) ENABLE_MANUAL_SETUP=1;; 
      -v|--version) GET_VERSION=1 ;;
      --) shift ; break ;;
      *)         echo "Unknown option: $1" ; usage ;;
    esac
    shift
done

# Envoke Sudo password lmao
sudo echo "Sudo envoke succesfull!"
[ $? -eq 1 ] && return

. sfb_io.sh

alias rc=return_control
SFB_ROOT_SH=sfbootstrap/sfbootstrap.sh
DEPS=("git" "curl")
CMDS=("init" "chroot setup" "sync" "build hal" "build packages")

git_check_ssh(){
	sfb_log "Checking GitHub-ssh-connection..."
	silent ssh -T git@github.com; [ $? -eq 1 ] || return 0
	sfb_succes "Git-ssh is successfully configured!"
	return 1
}

install_packages() {
	local NOFAIL ans=""
	
	sfb_log "Installing required packages..."
	for pkg in ${DEPS[@]}; do
		sfb_install "$pkg"
		silent sudo apt-get -y install $pkg;
		[ $? != 0 ] && NOFAIL=0;
	done
	
	if [ ! -z "$NOFAIL" ]; then
		sfb_prompt "Some packages failed to install! upgrade apt and try again (Y/n)?" ans "$SFB_YESNO_REGEX"
		[[ "${ans^^}" != "Y"* ]] && return
		sfb_log "Upgrading apt. \n\t Please Wait..."
		silent sudo apt update && silent sudo apt -y upgrade
		install_packages
	else
		sfb_succes "All packages are succesfully installed!"	
	fi
}


start_installing(){
	local ans="" start=0 end=$1
	
	[ -z "$1" ] && return
	
	if [[ "$1" == "Full" ]]; then
		end=$((${#CMDS[@]}-1))
	else
		sfb_prompt "Do you want to run this ($1: ${CMDS[$1]}) single command (or the sequence until $1) (Y/n)?" ans "[a-zA-Z]"
		[[ "${ans^^}" == "Y"* ]] && start=$1
	fi

	for i in $(seq $start $end); do
		sfb_log "Starting: ${CMDS[i]}!"
		$SFB_ROOT_SH ${CMDS[i]}
		[ "$?" -ne "0" ] && return
		sfb_log "Done executing ${CMDS[i]}"
	done
}


setup_installer(){
	local ans="" iType
	
	git_check_ssh; [ $? -eq 1 ] || return
	
	sfb_log "The next commands need te be run to complete the whole setup: "
	for i in "${!CMDS[@]}"; do
		echo -e "${GREEN}\t$i: ${CMDS[i]}${RESET}" 
	done
	
	sfb_prompt "Until Nth command do you want to run (all/(0-4))?" ans "[a-zA-Z0-4]"
	answer="${ans^^}"
	arr_size=$((${#CMDS[@]}-1))
	if [[ "${ans^^}" == "A"* ]]; then
		iType="Full"
	elif (( $answer >= 0 && $answer <= $arr_size )); then
		iType="$answer" 
	else
		echo "undefined!" && return 
	fi
	start_installing "$iType"
}

get_version() { echo "sfbs-install 1.0"; }

manual_sfossdk_setup(){
	#TODO need cleaning, goes into effect AFTER chroot setup has been run... should fix that... Also, FP4 is nog showing when in HABUILD for some reason?
	
	sfb_log "Setting up the manual setup scripts"
	echo "export ANDROID_ROOT=\"\$HOME/hadk\"
export VENDOR=\"fairphone\"
export DEVICE=\"FP4\"
export PORT_ARCH=\"aarch64\"" > $HOME/.hadk.env
	
	echo "function hadk() { source \$HOME/.hadk.env; echo \"Env setup for \$DEVICE\"; }
export PS1=\"HABUILD_SDK [\${DEVICE}] \$PS1\"
hadk" > $HOME/.mersdkubu.profile
	
	
	if ! grep -Fxq "#__sfossdk" ~/.bashrc; then
	echo "#__sfossdk
export PLATFORM_SDK_ROOT=/srv/sailfishos
alias sfossdk=\$PLATFORM_SDK_ROOT/sdks/sfossdk/sdk-chroot
ln -s /parentroot\$PLATFORM_SDK_ROOT/sdks/sfossdk/home/sfos/.scratchbox2 /home/sfos/.scratchbox2 &>/dev/null
alias enter_habuild=\"ubu-chroot -r /parentroot/srv/sailfishos/sdks/ubuntu\"
if [[ \$SAILFISH_SDK ]]; then
  PS1=\"PlatformSDK \$PS1\"
  [ -d /etc/bash_completion.d ] && for i in /etc/bash_completion.d/*;do . \$i;done
  
  function hadk() { source \$HOME/.hadk.env;
  echo \"Env setup for \$DEVICE\"; }
  hadk
fi" >> ~/.bashrc
	
	fi
	sfb_log " sourcing ~/.bashrc...
	You can now setup the project manually after running sfossdk in the \$HOME directory."
	. ~/.bashrc
}

main(){
	sfb_log "Starting the sfbootstrap-script..."
	
	[  "$GET_VERSION" ] && rc get_version
	[  "$INSTALL_PACKAGES" ] && rc install_packages
	[  "$ENABLE_MANUAL_SETUP" ] && rc manual_sfossdk_setup
	[  "$INSTALL" ] && setup_installer;
}
main
