#!/bin/sh



usage() {
cat << EOF
Usage: $0 [OPTION] ..."
	-h, --help			You're reading it
	-p, --install-all-packages	Install all the needed packages
	-i, --install			Start the main build process
      	-v, --version			Get the current sfbs-install version
EOF
}

OPTIONS=$(getopt -o hpiv -l help,install-all-packages,do-not-install,version,install -- "$@")
CMDS=("init" "chroot setup" "sync" "build hal" "build packages")

unset INSTALL_PACKAGES FULL_INSTALL GET_VERSION INSTALL TARGET

# If there are no cmd args; get packages and fullbuild
if [[ $# -eq 0 && -z "$1" ]]; then
    INSTALL_PACKAGES=1
    INSTALL=1 
fi

eval set -- $OPTIONS
while true; do
    case "$1" in
      -h|--help) usage ;;
      -p|--install-all-packages) INSTALL_PACKAGES=1;;
      -i|--install)  INSTALL=1 ;;
      -v|--version) GET_VERSION=1 ;;
      --) shift ; break ;;
      *)         echo "Unknown option: $1" ; usage ;;
    esac
    shift
done

# Envoke Sudo lmao
sudo echo
[ $? -eq 1 ] && return

. sfb_io.sh
sfb_log "Starting the sfbootstrap-script..."


alias rc=return_control
INPUTPKGS="pkgs.rq"
SFB_ROOT_SH=sfbootstrap/sfbootstrap.sh


install_packages() {
	local NOFAIL ans=""
	
	sfb_log "Installing required packages..."
	while IFS= read -r pkg
	do
		sfb_install "$pkg"
		silent sudo apt-get install $pkg;
		[ $? != 0 ] && NOFAIL=0;
	done < "$INPUTPKGS"
	
	if [ ! -z "$NOFAIL" ]; then
		sfb_prompt "Some packages failed to install! upgrade apt and try again (Y/n)?" ans "$SFB_YESNO_REGEX"
		[[ "${ans^^}" != "Y"* ]] && return
		sfb_log "Upgrading apt. \n\t Please Wait..."
		rc silent sudo apt update && echo y | rc silent sudo apt upgrade
		install_packages
	else
		sfb_succes "All packages are succesfully installed!"	
	fi
}


start_installing(){
	[ -z "$1" ] && return

	for n in $(seq 0 $1); do
		sfb_log "Starting: ${CMDS[n]}!"
		rc $SFB_ROOT_SH ${CMDS[n]}
		sfb_log "Done executing ${CMDS[n]}"
	done
}

# README config and SSH.
git_check_ssh(){
	sfb_log "Checking GitHub-ssh-connection..."
	silent ssh -T git@github.com; [ $? -eq 1 ] || return 0
	sfb_succes "Git-ssh is successfully configured!"
	return 1
}

setup_installer(){
	local ans iType
	
	git_check_ssh; [ $? -eq 1 ] || return
	
	sfb_log "The next commands need te be run to complete the whole setup: "
	for i in "${!CMDS[@]}"; do
		echo -e "${GREEN}\t$i: ${CMDS[i]}${RESET}" 
	done
	
	sfb_prompt "Until Nth command do you want to run (all/(0-4))?" ans "[a-zA-Z0-4]"
	answer="${ans^^}"
	arr_size="${#CMDS[@]}"
	if [[ $answer -eq $((arr_size=arr_size-1)) || "${ans^^}" == "A"* ]]; then
		iType="$arr_size"
	elif (( $answer >= 0 && $answer <= 4 )); then
		iType="$answer" 
	else
		echo "undefined!" && return 
	fi
	start_installing "$iType"
}

main(){
	[  "$GET_VERSION" ] && rc get_version
	[  "$INSTALL_PACKAGES" ] && rc install_packages
	[  "$INSTALL" ] && setup_installer;
}

main
