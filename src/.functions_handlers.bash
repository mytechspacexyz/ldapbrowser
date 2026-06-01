# Commands handlers functions

# version command handler
cmd_version() {

	log_debug "${FUNCNAME[0]} is called"

	[[ -f ${BASHAPP_DIR}/.version ]] && cat "${BASHAPP_DIR}"/.version || echo "unknown version of the ${BASHAPP_NAME} application"
}

# describe command handler
cmd_describe() {
	
	log_debug "${FUNCNAME[0]} is called"

	[[ -f ${BASHAPP_DIR}/.description ]] && cat "${BASHAPP_DIR}"/.description || echo "There is no description for the ${BASHAPP_NAME} application"
}

# help command handler
cmd_help () {

	log_debug "${FUNCNAME[0]} is called"

	[[ -f ${BASHAPP_DIR}/.help ]] && cat "${BASHAPP_DIR}"/.help || echo "currently there is no help available for the ${BASHAPP_NAME} application."
}

# setup command handler
cmd_setup() {
	
	log_debug "${FUNCNAME[0]} is called"

	echo
	
	while [[ "${#LDAP_SERVER_HOSTNAMES[@]}" -eq 0 || \
			 -z "$LDAP_DIRECTORY_TYPE" || \
			 -z "$LDAP_BIND_ACCOUNT" || \
			 -z "$LDAP_BIND_PASSWORD" || \
			 -z "$LDAP_SUFFIX" || \
			 -z "$LDAP_BASE_DN" || \
			 -z "$LDAP_USERS_DN" || \
			 -z "$CACERT" ]]
	do

		log_debug "function: ${FUNCNAME[0]}, while loop"

	    # Check and prompt for each variable individually
	    if [[ "${#LDAP_SERVER_HOSTNAMES[@]}" -eq 0 ]]
		then

			log_debug "function: ${FUNCNAME[0]}, if #1"
			
			local HOSTS
			local PROMPT="Enter LDAP server(s) hostname(s) with ports separated with spaces (ld01.int.ccc.xyz:1389 ld02.int.ccc.xyz:1389): "
	        read -r -e -p "$PROMPT" HOSTS
			LDAP_SERVER_HOSTNAMES=($HOSTS)

			log_debug "function: ${FUNCNAME[0]}, array LDAP_SERVER_HOSTNAMES=${LDAP_SERVER_HOSTNAMES[*]}"

	    fi
	
	    if [[ -z "$LDAP_DIRECTORY_TYPE" ]]
		then

			log_debug "function: ${FUNCNAME[0]}, if #2"

	        read -r -e -p "Enter LDAP directory type (case sensitive: IPA,AD,OPENLDAP,FOXPASS,JUMPCLOUD) [Default: IPA]: " LDAP_DIRECTORY_TYPE
			LDAP_DIRECTORY_TYPE=${LDAP_DIRECTORY_TYPE:-"IPA"}

			log_debug "function: ${FUNCNAME[0]}, LDAP_DIRECTORY_TYPE=${LDAP_DIRECTORY_TYPE}"	

	    fi
	
	    if [[ -z "$LDAP_BIND_ACCOUNT" ]]
		then

			log_debug "function: ${FUNCNAME[0]}, if #3"

	        read -r -e -p "Enter LDAP bind account (just the bind username): " LDAP_BIND_ACCOUNT

			log_debug "function: ${FUNCNAME[0]}, LDAP_BIND_ACCOUNT=${LDAP_BIND_ACCOUNT}"

	    fi
	    
	    if [[ -z "$LDAP_BIND_PASSWORD" ]]
		then

			log_debug "function: ${FUNCNAME[0]}, if #4"

			local PWD
	        read -r -s -p "Enter LDAP bind password: " PWD
			LDAP_BIND_PASSWORD=$(echo -n "$PWD" | base64)
	        echo

			log_debug "function: ${FUNCNAME[0]}, LDAP_BIND_PASSWORD=${LDAP_BIND_PASSWORD}"

	    fi
	
	    if [[ -z "$LDAP_SUFFIX" ]]
		then

			log_debug "function: ${FUNCNAME[0]}, if #5"

			# getting it from the DC FQDN:
	        read -r -e -p "Enter LDAP suffix (example: dc=int,dc=dom,dc=xyz) [Default: will be generated from LDAP_SERVER_HOSTNAMES first host]: " LDAP_SUFFIX
			if [[ -z "$LDAP_SUFFIX" ]]
			then
				# FQDN without a port
				FQDN="${LDAP_SERVER_HOSTNAMES[0]%:*}"
				# Domain
				DOMAIN="${FQDN#*.}"
				# converting to the ldap suffix format
				# dc=int,dc=dom,dc=xyz
				LDAP_SUFFIX="dc=${DOMAIN//./,dc=}"
			fi

			log_debug "function: ${FUNCNAME[0]}, LDAP_SUFFIX=${LDAP_SUFFIX}"	

	    fi
	
	    if [[ -z "$LDAP_BASE_DN" ]]
		then

			log_debug "function: ${FUNCNAME[0]}, if #6"

			# autopopulate from the LDAP_SUFFIX if not entered
	        read -r -e -p "Enter LDAP base DN [Default: LDAP_SUFFIX]: " LDAP_BASE_DN
			LDAP_BASE_DN=${LDAP_BASE_DN:-"$LDAP_SUFFIX"}

			log_debug "function: ${FUNCNAME[0]}, LDAP_BASE_DN=${LDAP_BASE_DN}"

	    fi
	
	    if [[ -z "$LDAP_USERS_DN" ]]
		then

			log_debug "function: ${FUNCNAME[0]}, if #7"

			echo
			echo "Enter LDAP users DN"
			echo "for AD (can be different) [Default: CN=users]: CN=users"
			echo "for IPA [Default]: cn=users,cn=accounts"
			echo "for OPENLDAP (can be different) [Default: ou=people]: ou=users or ou=Users or ou=People or ou=people"
			echo "for JUMPCLOUD [Default]: ou=Users"
			echo "for FOXPASS [Default]: ou=people"
			echo
	        read -r -e -p "LDAP users DN [Enter: default for the ${LDAP_DIRECTORY_TYPE} LDAP]: " LDAP_USERS_DN
			if [[ "${LDAP_DIRECTORY_TYPE}" == "AD" ]]
			then
				LDAP_USERS_DN=${LDAP_USERS_DN:-"CN=users"}
			elif [[ "${LDAP_DIRECTORY_TYPE}" == "IPA" ]]
			then
				LDAP_USERS_DN=${LDAP_USERS_DN:-"cn=users,cn=accounts"}
			elif [[ "${LDAP_DIRECTORY_TYPE}" == "OPENLDAP" ]]
			then
				LDAP_USERS_DN=${LDAP_USERS_DN:-"ou=people"}
			elif [[ "${LDAP_DIRECTORY_TYPE}" == "JUMPCLOUD" ]]
			then
				LDAP_USERS_DN=${LDAP_USERS_DN:-"ou=Users"}
			elif [[ "${LDAP_DIRECTORY_TYPE}" == "FOXPASS" ]]
			then
				LDAP_USERS_DN=${LDAP_USERS_DN:-"ou=people"}
			else
				# other LDAP Directories types or general default
				LDAP_USERS_DN=${LDAP_USERS_DN:-"ou=Users"}
			fi

			log_debug "function: ${FUNCNAME[0]}, LDAP_DIRECTORY_TYPE=${LDAP_DIRECTORY_TYPE}"
			log_debug "function: ${FUNCNAME[0]}, LDAP_USERS_DN=${LDAP_USERS_DN}"

	    fi
	
	    if [[ -z "$CACERT" ]]
		then

			log_debug "function: ${FUNCNAME[0]}, if #8"

	        read -r -e -p "Enter the full path to CA certificate LDAP server(s) certificate(s) signed with): " CACERT

			log_debug "function: ${FUNCNAME[0]}, CACERT=${CACERT}"

			cp "${CACERT}" "${BASHAPP_DIR}/${BASHAPP_CONFDIR}" || { log_error "function: ${FUNCNAME[0]}, error copying the ${CACERT} into the ${BASHAPP_DIR}/${BASHAPP_CONFDIR}"; exit 1; }
			CACERT=$(basename "${CACERT}")
			echo "${CACERT}"
	    fi

	done

	log_debug "function: ${FUNCNAME[0]}, generating the ${BASHAPP_DIR}/${BASHAPP_CONFDIR}/.configvars file"

	# if we get here then all the required variables are entered and generated
	# writing them to the .configvars
	cat <<- CONFIGVARS > "${BASHAPP_DIR}/${BASHAPP_CONFDIR}/.configvars"
	export LDAP_SERVER_HOSTNAME=""
	export LDAP_SERVER_HOSTNAMES=(
	$(
	for h in "${LDAP_SERVER_HOSTNAMES[@]}"
	do
		echo -n "                              "
		echo "\"$h\" " 
	done
	)
	                             )
	export LDAP_DIRECTORY_TYPE="$LDAP_DIRECTORY_TYPE"
	export LDAP_BIND_ACCOUNT="$LDAP_BIND_ACCOUNT"
	$(
	if [[ "$LDAP_DIRECTORY_TYPE" == "IPA" || "$LDAP_DIRECTORY_TYPE" == "JUMPCLOUD" || "$LDAP_DIRECTORY_TYPE" == "FOXPASS" ]]
	then
		echo "export LDAP_BIND_ACCOUNT_ATTR=\"uid\""
	elif [[ "$LDAP_DIRECTORY_TYPE" == "AD" || "$LDAP_DIRECTORY_TYPE" == "OPENLDAP" ]]
	then
		echo "export LDAP_BIND_ACCOUNT_ATTR=\"cn\""
	else
		echo "export LDAP_BIND_ACCOUNT_ATTR=\"uid\""
	fi
	)
	export LDAP_BIND_PASSWORD="$LDAP_BIND_PASSWORD"
	export LDAP_SUFFIX="$LDAP_SUFFIX"
	export LDAP_BASE_DN="$LDAP_BASE_DN"
	export LDAP_USERS_DN="$LDAP_USERS_DN"
	export LDAP_CURRENT_DN=\${LDAP_BASE_DN}
	export LDAP_SELECTED_DN=\${LDAP_CURRENT_DN}
	export LDAP_SNAPSHOTS_DIR="\${BASHAPP_DIR}/data"
	export LDAP_SNAPSHOTS_FILE="\${LDAP_SNAPSHOTS_DIR}/ldapbrowser-snapshots"
	export CACERT="\${BASHAPP_DIR}/\${BASHAPP_CONFDIR}/$CACERT"
	CONFIGVARS

	# creating the symlink to the .configvars if it doesn't exist:
	
	log_debug "function: ${FUNCNAME[0]}, creating the symlink .configvars to the ${BASHAPP_CONFDIR}/.configvars"

	# cd'ing into the bash application dir
	# if failed (rare if ever can happen) exit with error message into the log
	cd "${BASHAPP_DIR}" || { log_error "function: ${FUNCNAME[0]}, error cding into the ${BASHAPP_DIR}"; exit 1; }
	[[ ! -L .configvars ]] && ln -s "${BASHAPP_CONFDIR}/.configvars" .configvars
	chmod 600 "${BASHAPP_CONFDIR}/.configvars"

	echo "setup has been completed successfully."	

}

# debug command handler
cmd_debug() {

	log_debug "${FUNCNAME[0]} is called"

	local ONOFF="$1"

	if [[ -z "${ONOFF}" ]]
	then

		log_debug "function: ${FUNCNAME[0]}, if #1"

		echo -e "Incorrect or missing argument to the debug command.\nUse '${BASHAPP_NAME} help' for usage information"
		log_error "function: ${FUNCNAME[0]}, incorrect or missing argument to the debug command"
		exit 1
	else
		if [[ "${ONOFF}" == "on" ]]
		then
			sed -i 's/^export DEBUGAPP=.*/export DEBUGAPP=1/' "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/.common_configvars
			log_info "function: ${FUNCNAME[0]}, debug mode on"
			echo "debug mode on"
		elif [[ "${ONOFF}" == "off" ]]
		then
			sed -i 's/^export DEBUGAPP=.*/export DEBUGAPP=0/' "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/.common_configvars
			log_info "function: ${FUNCNAME[0]}, debug mode off"
			echo "debug mode off"
		else
			echo "Incorrect 'debug' command argument '${ONOFF}'."
			echo "Can be only 'on' or 'off'."
			echo "Use '${BASHAPP_NAME} help' for usage information"
			log_error "function: ${FUNCNAME[0]}, incorrect 'debug' command argument '${ONOFF}'"
		fi
	fi

}

# themes command handler
cmd_themes() {

	log_debug "${FUNCNAME[0]} is called"

	local THEME
	THEME=$(
		fzf --cycle \
			--border=rounded \
			--border-label=" Themes available " \
			--header "Choose please a theme for the ${BASHAPP_NAME}:" \
			--layout reverse <<-THMS
								dark
								light
								solarized-dark
								solarized-light
								nord
								gruvbox
								tokyo-night
								monokai
								catppuccin
								rose-pine
								one-dark
								everforest
								night-owl
								synthwave
								THMS
	)

	fzf_exit_code=$?
	[[ "$fzf_exit_code" -eq 130 ]] && return		# Ctrl-C or Esc
	[[ -z "${THEME}" ]] && return

	log_debug "function: ${FUNCNAME[0]}, selected theme: ${THEME}"

	case "${THEME}" in
		dark)
			sed -i 's/^export FZF_SET_SCHEME=.*/export FZF_SET_SCHEME="${FZF_DARK_SCHEME}"/' "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/.common_configvars
			echo "${THEME} theme selected"
			;;
		light)
			sed -i 's/^export FZF_SET_SCHEME=.*/export FZF_SET_SCHEME="${FZF_LIGHT_SCHEME}"/' "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/.common_configvars
			echo "${THEME} theme selected"
			;;
		solarized-dark)
			sed -i 's/^export FZF_SET_SCHEME=.*/export FZF_SET_SCHEME="${FZF_SOLARIZED_DARK_SCHEME}"/' "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/.common_configvars
			echo "${THEME} theme selected"
			;;
		solarized-light)
			sed -i 's/^export FZF_SET_SCHEME=.*/export FZF_SET_SCHEME="${FZF_SOLARIZED_LIGHT_SCHEME}"/' "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/.common_configvars
			echo "${THEME} theme selected"
			;;
		nord)
			sed -i 's/^export FZF_SET_SCHEME=.*/export FZF_SET_SCHEME="${FZF_NORD_SCHEME}"/' "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/.common_configvars
			echo "${THEME} theme selected"
			;;
		gruvbox)
			sed -i 's/^export FZF_SET_SCHEME=.*/export FZF_SET_SCHEME="${FZF_GRUVBOX_SCHEME}"/' "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/.common_configvars
			echo "${THEME} theme selected"
			;;
		tokio-night)
			sed -i 's/^export FZF_SET_SCHEME=.*/export FZF_SET_SCHEME="${FZF_TOKIO_NIGHT_SCHEME}"/' "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/.common_configvars
			echo "${THEME} theme selected"
			;;
		monokai)
			sed -i 's/^export FZF_SET_SCHEME=.*/export FZF_SET_SCHEME="${FZF_MONOKAI_SCHEME}"/' "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/.common_configvars
			echo "${THEME} theme selected"
			;;
		catppuccin)
			sed -i 's/^export FZF_SET_SCHEME=.*/export FZF_SET_SCHEME="${FZF_CATPPUCCIN_SCHEME}"/' "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/.common_configvars
			echo "${THEME} theme selected"
			;;
		rose-pine)
			sed -i 's/^export FZF_SET_SCHEME=.*/export FZF_SET_SCHEME="${FZF_ROSE_PINE_SCHEME}"/' "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/.common_configvars
			echo "${THEME} theme selected"
			;;
		one-dark)
			sed -i 's/^export FZF_SET_SCHEME=.*/export FZF_SET_SCHEME="${FZF_ONE_DARK_SCHEME}"/' "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/.common_configvars
			echo "${THEME} theme selected"
			;;
		everforest)
			sed -i 's/^export FZF_SET_SCHEME=.*/export FZF_SET_SCHEME="${FZF_EVERFOREST_SCHEME}"/' "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/.common_configvars
			echo "${THEME} theme selected"
			;;
		night-owl)
			sed -i 's/^export FZF_SET_SCHEME=.*/export FZF_SET_SCHEME="${FZF_NIGHT_OWL_SCHEME}"/' "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/.common_configvars
			echo "${THEME} theme selected"
			;;
		synthwave)
			sed -i 's/^export FZF_SET_SCHEME=.*/export FZF_SET_SCHEME="${FZF_SYNTHWAVE_SCHEME}"/' "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/.common_configvars
			echo "${THEME} theme selected"
			;;
		*)
			log_error "function: ${FUNCNAME[0]}, unknown theme: ${THEME}"
			;;
	esac

}

# fzf preview key binding handler (ctrl+p)
# used in ctrl+s binding as well
cmd_ldapdn_info() {

	log_debug "${FUNCNAME[0]} is called"

	if [[ "$1" != ".." ]]
	then

		log_debug "function: ${FUNCNAME[0]}, if #1"

		# handle spaces " " and colons ":" in a DN
		LDAP_VIEWED_DN="$1"
		LDAP_VIEWED_DN=${LDAP_VIEWED_DN// /%20}
		LDAP_VIEWED_DN=${LDAP_VIEWED_DN//:/%3A}

		log_debug "function: ${FUNCNAME[0]}, LDAP_VIEWED_DN=${LDAP_VIEWED_DN}"

		# show the DN attributes
		LDAP_VIEWED_DN_ATTRIBUTES=$(curl ${CURL_OPTS} ${CACERT} "ldap://${LDAP_SERVER_HOSTNAME}/${LDAP_VIEWED_DN}??base?(objectClass=*)" -u "${LDAP_BIND_ACCOUNT_ATTR}=${LDAP_BIND_ACCOUNT},${LDAP_USERS_DN},${LDAP_SUFFIX}:$(echo "${LDAP_BIND_PASSWORD}" | base64 -d)" | sed '/^$/d')
		echo "${LDAP_VIEWED_DN_ATTRIBUTES}"

		log_debug "function: ${FUNCNAME[0]}, LDAP_VIEWED_DN_ATTRIBUTES=${LDAP_VIEWED_DN_ATTRIBUTES}"

	fi
}
export -f cmd_ldapdn_info

# list command handler
cmd_list() {

	log_debug "${FUNCNAME[0]} is called"

	while true
	do

		log_debug "function: ${FUNCNAME[0]}, while loop"

		# alternative to sed replacements:
		LDAP_CURRENT_DN=${LDAP_CURRENT_DN// /%20}
		LDAP_CURRENT_DN=${LDAP_CURRENT_DN//:/%3A}

		log_debug "function: ${FUNCNAME[0]}, LDAP_CURRENT_DN=${LDAP_CURRENT_DN}"

		# getting the current dn children:
        CHILDREN=$(curl ${CURL_OPTS} ${CACERT} "ldap://${LDAP_SERVER_HOSTNAME}/${LDAP_CURRENT_DN}?dn,rdn?one?(objectClass=*)" \
				-u "${LDAP_BIND_ACCOUNT_ATTR}=${LDAP_BIND_ACCOUNT},${LDAP_USERS_DN},${LDAP_SUFFIX}:$(echo "${LDAP_BIND_PASSWORD}" \
				| base64 -d)" | sed '/^$/d')

		log_debug "function: ${FUNCNAME[0]}, CHILDREN=\n${CHILDREN}"

        if [[ -n "$CHILDREN" ]]
		then

			log_debug "function: ${FUNCNAME[0]}, if #1"			


			log_debug "function: ${FUNCNAME[0]}, LDAP_SNAPSHOTS_FILE=${LDAP_SNAPSHOTS_FILE}"

			# case of dn with children:
			LDAP_SELECTED_DN=$( (echo ".."; echo "$CHILDREN" | awk '{print substr($0, index($0, ":")+2)}' | sed 's/^[[:space:]]*//') | fzf --reverse --cycle --preview-window=right:50% --preview 'cmd_ldapdn_info {}' --preview-window=hidden --bind 'ctrl-p:toggle-preview' --bind 'ctrl-s:execute-silent(echo -e "\nsnapshotting on $(date "+%Y-%m-%d %H:%M:%S"):\n" >> "${LDAP_SNAPSHOTS_FILE}"; cmd_ldapdn_info {} >> "${LDAP_SNAPSHOTS_FILE}")' --border=rounded --border-label="Select an LDAP DN under ${LDAP_CURRENT_DN}:" --border-label-pos=center --header "Actions for LDAP objects | ctrl-p: view LDAP object details | ctrl-s: snapshot LDAP object details to the snapshot file" )

			# checking Ctrl+C inside the fzf:
			fzf_exit_code=$?
    		[[ "$fzf_exit_code" -eq 130 ]] && break

			log_debug "function: ${FUNCNAME[0]}, LDAP_SELECTED_DN=${LDAP_SELECTED_DN}"

            if [[ "${LDAP_SELECTED_DN}" == ".." && "${LDAP_CURRENT_DN}" != "${LDAP_BASE_DN}" ]]
			then

				log_debug "function: ${FUNCNAME[0]}, if #2"

                # Get the parent DN by removing the first component, for example:
                # "cn=users,ou=people,dc=int,dc=dom,dc=xyz" becomes "ou=people,dc=int,dc=dom,dc=xyz"
				LDAP_CURRENT_DN="${LDAP_CURRENT_DN#*,}"

				log_debug "function: ${FUNCNAME[0]}, LDAP_CURRENT_DN=${LDAP_CURRENT_DN}"

			elif [[ "${LDAP_SELECTED_DN}" == ".." && "${LDAP_CURRENT_DN}" == "${LDAP_BASE_DN}" ]]
			then
                LDAP_CURRENT_DN="${LDAP_CURRENT_DN}"

				log_debug "function: ${FUNCNAME[0]}, LDAP_CURRENT_DN=${LDAP_CURRENT_DN}"

            else
                # If a child DN was selected, update the current DN
                LDAP_CURRENT_DN="${LDAP_SELECTED_DN}"

				log_debug "function: ${FUNCNAME[0]}, LDAP_CURRENT_DN=${LDAP_CURRENT_DN}"

            fi
        else

			# case of dn with no children:

			# reverting back to be readable in the TUI:
			# %20 => " "
			# %3A => ":"
			LDAP_CURRENT_DN=${LDAP_CURRENT_DN//%20/ }
			LDAP_CURRENT_DN=${LDAP_CURRENT_DN//%3A/:}
			LDAP_SELECTED_DN=$( (echo ".."; echo "${LDAP_CURRENT_DN}" | sed 's/^[[:space:]]*//') | fzf --reverse --cycle --preview-window=right:50% --preview 'cmd_ldapdn_info {}' --preview-window=hidden --bind 'ctrl-p:toggle-preview' --bind 'ctrl-s:execute-silent(echo -e "\nsnapshotting on $(date "+%Y-%m-%d %H:%M:%S"):\n" >> "${LDAP_SNAPSHOTS_FILE}"; cmd_ldapdn_info {} >> "${LDAP_SNAPSHOTS_FILE}")' --border=rounded --border-label="Select an LDAP DN under ${LDAP_CURRENT_DN}" --border-label-pos=center --header "Actions for LDAP objects | ctrl-p: view LDAP object details | ctrl-s: snapshot LDAP object details to the snapshot file" )

			# checking Ctrl+C inside the fzf:
			fzf_exit_code=$?
    		[[ "$fzf_exit_code" -eq 130 ]] && break

			log_debug "function: ${FUNCNAME[0]}, LDAP_CURRENT_DN=${LDAP_CURRENT_DN}"
			log_debug "function: ${FUNCNAME[0]}, LDAP_SELECTED_DN=${LDAP_SELECTED_DN}"

			if [[ "${LDAP_SELECTED_DN}" == ".." ]]
			then
				LDAP_CURRENT_DN="${LDAP_CURRENT_DN#*,}"

				log_debug "function: ${FUNCNAME[0]}, LDAP_CURRENT_DN=${LDAP_CURRENT_DN}"

			fi
        fi
	done
}

# unknown command handler
cmd_unknown() {

	log_debug "${FUNCNAME[0]} is called"

	log_error "Unknown command: $1"
	log_error "Use '$BASHAPP_NAME help' for usage information"
	echo "Unknown command: $1"
	echo "Use '$BASHAPP_NAME help' for usage information"
}
