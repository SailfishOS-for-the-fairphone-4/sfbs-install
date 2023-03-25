#!/bin/sh


source utils.sh

usage() {
cat << EOF
Usage: $0 [OPTION] ..."
	-h, --help			You're reading it
	-p, --install-all-packages	Install all the needed packages
	-D, --do-not-install		Don't do anything?
      	-v, --version			Get the current version
EOF
}

OPTIONS=$(getopt -o hpDvi -l help,install-all-packages,do-not-install,version,install -- "$@")

if [ $? -ne 0 ]; then
    echo "getopt error"
#    exit 1
fi

eval set -- $OPTIONS
while true; do
    case "$1" in
      -h|--help) usage ;;
      -p|--install-all-packages) install_packages;;
      -v|--version) get_version ;;
      -i|--install) start_install ;;
      --)        shift ; break ;;
    esac
    shift
done
