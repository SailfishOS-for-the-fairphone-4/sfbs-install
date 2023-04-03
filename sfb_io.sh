#!/bin/sh

BLUE="\e[01;96m" 
RED="\e[01;91m"
ORANGE="\e[01;33m" 
GREEN="\e[01;32m" 
YELLOW="\e[01;33m" 
RESET="\e[0m" 
DIM="\e[2m"

SFB_YESNO_REGEX="^([yY].*|[nN].*|)$"

sfb_log() 	{ printf  "${BLUE}>>${RESET} $1\n"; }
sfb_install()	{ echo -e "${ORANGE}INSTALL: $*${RESET}"; }
sfb_succes()	{ echo -e "${GREEN}SUCCES: $*${RESET}"; }
sfb_warn() 	{ echo -e "${YELLOW}WARN: $*${RESET}" 1>&2; }
sfb_error() 	{ echo -e "${RED}ERROR: $*${RESET}" 1>&2; exit ${2:-1}; }

return_control(){ "$@" || return ; }
silent()	{ return_control "$@"&>/dev/null; }

sfb_prompt() {
	local msg="$1" var="$2" match_regex="$3" prefill_ans="$4" loop=true
	while $loop; do
		if [ "$prefill_ans" ]; then
			sfb_log "$1 $prefill_ans ${DIM}(prefilled answer)${RESET}"
			eval "$var=$prefill_ans"
		else
			read -erp "$(printf "${BLUE}>>${RESET}") $1 " $var
		fi
		if [ "$match_regex" ]; then
			if [[ "${!var}" =~ $match_regex ]]; then
				loop=false
			else
				echo -e "${RED}Invalid input, didn't match expected regex '$match_regex'!${RESET}"
				if [ "$prefill_ans" ]; then
					sfb_exit
				fi
			fi
		else
			loop=false
		fi
	done
}
