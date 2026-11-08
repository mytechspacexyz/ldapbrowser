# auxiliary functions

# file picker preview handler
_file_picker_preview() {

	log_debug "${FUNCNAME[0]} is called"

	local ITEMLINE="${1}"
	local CURRENTDIR="${2}"
	[[ -z "${ITEMLINE}" ]] && return

	local TARGET
	TARGET=$(cut -d$'\t' -f2- <<< "${ITEMLINE}")

	if [[ -d "${CURRENTDIR}/${TARGET}" ]]
	then

		ls -la --color=always "${CURRENTDIR}/${TARGET}"

	else

		file "${CURRENTDIR}/${TARGET}"

	fi

}
export -f _file_picker_preview

# file picker handler
_file_picker() {

	log_debug "${FUNCNAME[0]} is called"

	local STARTDIR
	STARTDIR="${1}"

	local MSG
	MSG="${2}"
	MSG="${MSG:-Select a file}"

	if [[ -z "${STARTDIR}" ]]
	then
		read -e -r -p "Starting directory to browse from [default: \$HOME]: " STARTDIR
		STARTDIR="${STARTDIR:-$HOME}"
	else

		log_debug "function: ${FUNCNAME[0]}, STARTDIR=${STARTDIR}" 

	fi
	
	[[ -d "${STARTDIR}" ]] || { log_error "function: ${FUNCNAME[0]}, starting folder ${STARTDIR} does not exist. exiting..."; return 1; }

	local CURRENTDIR="${STARTDIR}"
	SELECTEDFILE=""
	
	while true
	do

		log_debug "function: ${FUNCNAME[0]}, while loop"	

		local SELECTED
		SELECTED=$(
			(
				cd "${CURRENTDIR}" || return 1
				shopt -s dotglob
				echo -e "📁\t.."
				for item in *
				do
					[[ -e "${item}" ]] || continue
					if [[ -d "${item}" ]]
					then
						echo -e "📁\t${item}"
					else
						echo -e "📄\t${item}"
					fi
				done 2>/dev/null | sort
				shopt -u dotglob
			) | \
			fzf --reverse \
				--border=rounded \
				--border-label=" Browsing ${CURRENTDIR} " \
				--header "${MSG} | ctrl-p: file preview" \
				--preview "_file_picker_preview {} '${CURRENTDIR}'" \
				--preview-window=right:50%:wrap \
				--bind 'ctrl-p:toggle-preview'
		)
	
		[[ -z "${SELECTED}" ]] && break
	
		local ITEM
		ITEM=$(cut -d$'\t' -f2- <<< "${SELECTED}")
	
		if [[ -d "${CURRENTDIR}/${ITEM}" ]]
		then
			CURRENTDIR=$(cd "${CURRENTDIR}/${ITEM}" && pwd)
		else
			SELECTEDFILE="${CURRENTDIR}/${ITEM}"
			break
		fi
	done

}
