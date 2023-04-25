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

# Source I/O
. sfb_io.sh

# Add possibility to return whenever...
alias rc=return_control
DEPS=("git" "curl")
CMDS=("init" "chroot setup" "sync" "build hal" "build packages")


# Install all the "needed" packages in the DEPS array.
install_packages() {
	local NOFAIL ans=""
	
	sfb_log "Installing required packages..."
	for pkg in ${DEPS[@]}; do
		sfb_install "$pkg"
		silent sudo apt-get -y install $pkg;
		[ $? -ne 0 ] && NOFAIL=0
	done
	
	if [ ! -z "$NOFAIL" ]; then
		sfb_prompt "Some packages failed to install! upgrade apt and try again (Y/n)?" ans "$SFB_YESNO_REGEX"
		[[ "${ans^^}" != "Y"* ]] && return
		sfb_log "Upgrading apt... \n\t Please Wait..."
		silent sudo apt update && silent sudo apt -y upgrade
		install_packages
	else
		sfb_succes "All packages are succesfully installed!"	
	fi
}


start_installing(){
	local ans="" start=1 end=$1
	
	# base case
	[ -z "$1" ] && return
	
	sfb_printf "\tA: {Single}: ${CMDS[$(($1-1))]}" ${GREEN}
	sfb_printf "\tB: {Sequence}: ${CMDS[0]} -->  ${CMDS[$(($1-1))]}" ${GREEN} 
	sfb_prompt "Do you want the run \"Single\"(A) or \"Sequence\"(B) (A/B)?" ans "[a-bA-B]" $2
	[[ "${ans^^}" == "A"* ]] && start=$1
	
	for i in $(seq $start $end); do
		# index starts at 0, we need to decrement so the index matches with the chosen component
		running_cmd=${CMDS[$((i-1))]}
		
		sfb_log "Starting: $running_cmd..."
		sfbootstrap/sfbootstrap.sh $running_cmd
		[ $? -ne 0 ] && return
		sfb_log "Done executing $running_cmd!"
	done
}


setup_installer(){
	local ans="" cmd prefill_ans arr_size=${#CMDS[@]}

	sfb_log "The next commands need te be run to complete the whole setup: "
	for i in "${!CMDS[@]}"; do
		sfb_printf "\t$(($i+1)): {${CMDS[i]}}" ${GREEN}
	done

	sfb_prompt "What command do you want to run (all/(1-$arr_size))?" ans "[a-z1-$arr_size]"
	answer="${ans^^}"
	if [[ "$answer" == "A"* ]]; then
		cmd="$arr_size"
		# Prefill to do the full sequence if ans==A/a*
		prefill_ans="B"
	elif (( $answer > 0 && $answer <= $arr_size )); then
		cmd="$answer" 
	else
		sfb_error "Undefined!" 
	fi
	
	start_installing $cmd $prefill_ans 
}

get_version() { echo "sfbs-install 2.0"; }

manual_sfossdk_setup(){
	if [ ! -d $HOME/.hadk.env ]; then
		echo "export ANDROID_ROOT=\"\$HOME/hadk\"
			export VENDOR=\"fairphone\"
			export DEVICE=\"FP4\"
			export PORT_ARCH=\"aarch64\"" | tr -d '\t' > $HOME/.hadk.env 		
	fi
	if [ ! -d $HOME/.mersdkubu.profile ]; then
		echo "function hadk() { source \$HOME/.hadk.env; echo \"Env setup for \$DEVICE\"; }
			hadk
			export PS1=\"HABUILD_SDK [\${DEVICE}] \$PS1\"" | tr -d '\t' > $HOME/.mersdkubu.profile
	fi
	if ! grep -Fxq "#__sfossdk" ~/.bashrc; then
		echo "#__sfossdk
			export PLATFORM_SDK_ROOT=/srv/sailfishos
			alias sfossdk=\$PLATFORM_SDK_ROOT/sdks/sfossdk/sdk-chroot
			ln -s /parentroot\$PLATFORM_SDK_ROOT/sdks/sfossdk/home/sfos/.scratchbox2 /home/sfos/.scratchbox2 &>/dev/null
			alias habuild=\"ubu-chroot -r /parentroot/srv/sailfishos/sdks/ubuntu\"
			if [[ \$SAILFISH_SDK ]]; then
				PS1=\"PlatformSDK \$PS1\"
				[ -d /etc/bash_completion.d ] && for i in /etc/bash_completion.d/*;do  . \$i;done
							
				function hadk() { source \$HOME/.hadk.env;
				echo \"Env setup for \$DEVICE\"; }
				hadk
			fi" | tr -d '\t' >> ~/.bashrc
	fi
	
	sfb_log " sourcing ~/.bashrc...Run \"sfossdk\" to enter the manual environment."
	. ~/.bashrc
}


main(){
	# Envoke sudo password
	sudo printf "${BLUE}>>${RESET} Starting the sfbootstrap-script...\n"
	[ $? -ne 0 ] && return

	
	[  "$GET_VERSION" ] && rc get_version
	[  "$INSTALL_PACKAGES" ] && rc install_packages
	[  "$ENABLE_MANUAL_SETUP" ] && rc manual_sfossdk_setup
	[  "$INSTALL" ] && setup_installer;
}
main
