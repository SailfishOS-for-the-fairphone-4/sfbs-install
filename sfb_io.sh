#!/bin/sh

BLUE="\e[01;96m" 
RED="\e[01;91m"
ORANGE="\e[01;33m" 
GREEN="\e[01;32m" 
YELLOW="\e[01;33m" 
RESET="\e[0m" 
DIM="\e[2m"

SFB_YESNO_REGEX="^([yY].*|[nN].*|)$"


# formatted string, desired color for formats
sfb_printer()	{ 
	[[ ! -z "$2" ]] && string=$(sed "s/{/\\$2/g; s/}/\\$RESET/g" <<< $1)
	[[ -z $string ]] && string="$1"
	echo -e $(sed "s/{//g; s/}//g" <<< $string) $3
}

sfb_printf()	{ sfb_printer "$1" $2 ; }
sfb_log() 	{ sfb_printer "{>>} $1" ${BLUE}; }
sfb_install()	{ sfb_printer "{INSTALL: }$*" ${ORANGE}; }
sfb_succes()	{ sfb_printer "{SUCCES: }$*" ${GREEN}; }
sfb_warn() 	{ sfb_printer "{WARN: }$*" ${YELLOW} 1>&2; }
sfb_error() 	{ sfb_printer "{ERROR: }$*" ${RED} 1>&2; exit ${2:-1}; }

return_control(){ "$@" || return ; }
silent()	{ return_control "$@"&>/dev/null; }
sfb_dbg() { [[ $SFB_DEBUG -eq 1 ]] && echo -e "${DIM}[DEBUG] $(caller 0 | awk '{printf "%s:%d",$2,$1}'): $1${RESET}" 1>&2; }

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
					sfb_error "Exiting..."
				fi
			fi
		else
			loop=false
		fi
	done
}
