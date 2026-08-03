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

	local SUBCMD="$1"
	
	echo

	if [[ -z "${SUBCMD}" ]]
	then

		if [[ -f "${BASHAPP_DIR}/${BASHAPP_CONFDIR}/.configvars" ]]
		then
			log_error "function: ${FUNCNAME[0]}, an active configuration already exists. Run 'ldapbrowser setup reset' first to reconfigure."
			echo "An active configuration already exists. Run 'ldapbrowser setup reset' first to reconfigure."
			exit 1
		fi
		
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
				
				LDAP_TLS_MODE=$(
					printf '%s\n' "starttls" "ldaps" | \
					fzf --reverse \
						--cycle \
						--border=rounded \
						--border-label="Select the LDAP TLS mode:" \
						--border-label-pos=center \
						--header "starttls: upgrade plain LDAP to TLS (port 389) | ldaps: implicit TLS from connection start (port 636)"
				)
			
				[[ -z "${LDAP_TLS_MODE}" ]] && \
					{ log_error "function: ${FUNCNAME[0]}, no TLS mode selected. Exiting ..."; \
						echo "No TLS mode selected. Exiting ..."; \
						exit 1; \
					}
			
				if [[ "${LDAP_TLS_MODE}" == "starttls" ]]
				then
					LDAP_URL_PREFIX="ldap://"
					CURL_OPTS="-s --ssl-reqd --connect-timeout 30 --cacert "
				elif [[ "${LDAP_TLS_MODE}" == "ldaps" ]]
				then
					LDAP_URL_PREFIX="ldaps://"
					CURL_OPTS="-s --connect-timeout 30 --cacert "
				fi
			
				log_debug "function: ${FUNCNAME[0]}, LDAP_TLS_MODE=${LDAP_TLS_MODE}"
				log_debug "function: ${FUNCNAME[0]}, LDAP_URL_PREFIX=${LDAP_URL_PREFIX}"
				log_debug "function: ${FUNCNAME[0]}, CURL_OPTS=${CURL_OPTS}"

				local HOSTS
				local PROMPT="Enter LDAP server(s) hostname(s) with ports separated with spaces (ld01.int.ccc.xyz:1389 ld02.int.ccc.xyz:1389): "
		        read -r -e -p "$PROMPT" HOSTS
				LDAP_SERVER_HOSTNAMES=($HOSTS)
	
				log_debug "function: ${FUNCNAME[0]}, array LDAP_SERVER_HOSTNAMES=${LDAP_SERVER_HOSTNAMES[*]}"
	
		    fi
		
		    if [[ -z "$LDAP_DIRECTORY_TYPE" ]]
			then
	
				log_debug "function: ${FUNCNAME[0]}, if #2"

				LDAP_DIRECTORY_TYPE=$(
					fzf --reverse \
						--cycle \
						--border=rounded \
						--border-label="LDAP directory types available" \
						--border-label-pos=center \
						--header "Select LDAP directory type [Default: IPA] | ctrl-h: help for LDAP directory type" \
            			--preview-window=right:50% \
            			--preview "cmd_setup_ldapdir_type_help {}" \
            			--preview-window=hidden \
						--bind 'ctrl-h:toggle-preview' \
						<<- LDAPDIRS
							AD
							IPA
							OPENLDAP
							389DS
							OPENDJ
							APACHEDS
							OKTA
							ONELOGIN
							JUMPCLOUD
							FOXPASS
						LDAPDIRS
				)

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
				echo "for 389DS (can be different) [Default: ou=people]: ou=users or ou=Users or ou=People or ou=people"
				echo "for OPENDJ (can be different) [Default: ou=People]: ou=users or ou=Users or ou=People or ou=people"
				echo "for APACHEDS (can be different) [Default: ou=users]: ou=users or ou=Users or ou=People or ou=people"
				echo "for OKTA [Default]: ou=users"
				echo "for ONELOGIN [Default]: ou=users"
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
				elif [[ "${LDAP_DIRECTORY_TYPE}" == "389DS" ]]
				then
					LDAP_USERS_DN=${LDAP_USERS_DN:-"ou=people"}
				elif [[ "${LDAP_DIRECTORY_TYPE}" == "OPENDJ" ]]
				then
					LDAP_USERS_DN=${LDAP_USERS_DN:-"ou=People"}
				elif [[ "${LDAP_DIRECTORY_TYPE}" == "APACHEDS" ]]
				then
					LDAP_USERS_DN=${LDAP_USERS_DN:-"ou=users"}
				elif [[ "${LDAP_DIRECTORY_TYPE}" == "OKTA" ]]
				then
					LDAP_USERS_DN=${LDAP_USERS_DN:-"ou=users"}
				elif [[ "${LDAP_DIRECTORY_TYPE}" == "ONELOGIN" ]]
				then
					LDAP_USERS_DN=${LDAP_USERS_DN:-"ou=users"}
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
		export LDAP_URL_PREFIX="${LDAP_URL_PREFIX}"
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
		if [[ "$LDAP_DIRECTORY_TYPE" == "IPA" || \
			  "$LDAP_DIRECTORY_TYPE" == "JUMPCLOUD" || \
			  "$LDAP_DIRECTORY_TYPE" == "FOXPASS" || \
			  "$LDAP_DIRECTORY_TYPE" == "OKTA" || \
			  "$LDAP_DIRECTORY_TYPE" == "APACHEDS" || \
			  "$LDAP_DIRECTORY_TYPE" == "OPENDJ" || \
			  "$LDAP_DIRECTORY_TYPE" == "389DS" ]]
		then
			echo "export LDAP_BIND_ACCOUNT_ATTR=\"uid\""
		elif [[ "$LDAP_DIRECTORY_TYPE" == "AD" || \
				"$LDAP_DIRECTORY_TYPE" == "OPENLDAP" || \
				"$LDAP_DIRECTORY_TYPE" == "ONELOGIN" ]]
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
		export CURL_OPTS="${CURL_OPTS}"
		CONFIGVARS
	
		# creating the symlink to the .configvars if it doesn't exist:
		
		log_debug "function: ${FUNCNAME[0]}, creating the symlink .configvars to the ${BASHAPP_CONFDIR}/.configvars"
	
		# cd'ing into the bash application dir
		# if failed (rare if ever can happen) exit with error message into the log
		cd "${BASHAPP_DIR}" || { log_error "function: ${FUNCNAME[0]}, error cding into the ${BASHAPP_DIR}"; exit 1; }
		[[ ! -L .configvars ]] && ln -s "${BASHAPP_CONFDIR}/.configvars" .configvars
		chmod 600 "${BASHAPP_CONFDIR}/.configvars"
	
		echo "setup has been completed successfully."	

	elif [[ "${SUBCMD}" == "reset" ]]
	then

		cmd_setup_reset

	elif [[ "${SUBCMD}" == "backup" ]]
	then

		cmd_setup_backup

	elif [[ "${SUBCMD}" == "restore" ]]
	then

		cmd_setup_restore

	else

		log_error "function: ${FUNCNAME[0]}, Unknown setup subcommand ${SUBCMD}"
		echo "Unknown setup subcommand ${SUBCMD}"
		exit 1

	fi

}

# setup ldap directory type help handler
cmd_setup_ldapdir_type_help() {

	log_debug "${FUNCNAME[0]} is called"

	local LDAPDIRTYPE
	LDAPDIRTYPE="${1}"

	[[ -z "${LDAPDIRTYPE}" ]] && return
	
	case "${LDAPDIRTYPE}" in
		AD)
			echo "Microsoft Active Directory"
			;;
		IPA)
			echo "FreeIPA Identity Management System"
			;;
		OPENLDAP)
			echo "OpenLDAP Directory"
			;;
		389DS)
			echo "389 Directory Server"
			;;
		OPENDJ)
			echo "Open Directory Server part of Open Identity Platform"
			;;
		APACHEDS)
			echo "Apache Directory Server"
			;;
		OKTA)
			echo "Okta LDAP Interface"
			;;
		ONELOGIN)
			echo "OneLogin VLDAP"
			;;
		JUMPCLOUD)
			echo "JumpCloud Cloud LDAP"
			;;
		FOXPASS)
			echo "Foxpass Cloud LDAP Directory"
			;;
		*)
			echo "Unknown LDAP directory type. No help available."
			;;
	esac

}
export -f cmd_setup_ldapdir_type_help

# setup reset subcommand handler
cmd_setup_reset() {

	log_debug "${FUNCNAME[0]} is called"

	if [[ ! -f "${BASHAPP_DIR}/${BASHAPP_CONFDIR}/.configvars" ]]
	then

		log_error "function: ${FUNCNAME[0]}, No active configuration exists to reset. Exiting ..."; \
		echo "No active configuration exists to reset. Exiting ..."
		exit 1

	else

		local CONFIRM
		read -r -e -p "This will permanently delete your current ldapbrowser configuration. Continue? [yes/NO]: " CONFIRM
		CONFIRM="${CONFIRM^^}"
		[[ "${CONFIRM}" != "YES" ]] && \
			{ log_debug "function: ${FUNCNAME[0]}, no reset has been done. skipping ..."; \
				echo "No reset has been done. skipping ..."
				return; \
			}		

		log_debug "function: ${FUNCNAME[0]}, resetting the active configuration"
		echo "Resetting the active configuration"
		echo
		unlink "${BASHAPP_DIR}"/.configvars
		rm -f "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/.configvars
		rm -f "${CACERT}"
		sleep 1
		echo "Configuration has been reset successfully."
		return 0

	fi

}

# setup backup subcommand handler
cmd_setup_backup() {

	log_debug "${FUNCNAME[0]} is called"

	if [[ ! -f "${BASHAPP_DIR}/${BASHAPP_CONFDIR}/.configvars" ]]
	then

		log_error "function: ${FUNCNAME[0]}, No active configuration exists to back up. Exiting ..."
		echo "No active configuration exists to back up. Exiting ..."
		exit 1

	else

		log_debug "function: ${FUNCNAME[0]}, backing up ..."

		# creating the backups folder in case it doesn't exist initially
		[[ -d "${BASHAPP_DIR}/${BASHAPP_CONFDIR}/backups" ]] || mkdir -p "${BASHAPP_DIR}/${BASHAPP_CONFDIR}/backups" 
		chmod 700 "${BASHAPP_DIR}/${BASHAPP_CONFDIR}/backups"
		
		tar -czf "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/backups/backup-$(date '+%Y-%m-%d-%H-%M-%S').tgz \
			-C "${BASHAPP_DIR}" \
			"${BASHAPP_CONFDIR}"/.configvars \
			"${CACERT#${BASHAPP_DIR}/}" && \
		{ log_debug "function: ${FUNCNAME[0]}, the configuration has been backed up successfully."; \
			echo "The configuration has been backed up successfully."; \
			chmod 600 "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/backups/*.tgz; return 0; } || \
		{ log_error "function: ${FUNCNAME[0]}, backup has failed."; \
			echo "Backup has failed."; \
			exit 1; }	

	fi

}

# setup restore subcommand handler
cmd_setup_restore() {

	log_debug "${FUNCNAME[0]} is called"

	if [[ -d "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/backups ]]
	then

		shopt -s nullglob
		BACKUPS=("${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/backups/*.tgz)
		shopt -u nullglob
		
		if [[ ${#BACKUPS[@]} -gt 0 ]]
		then
			
			log_debug "function: ${FUNCNAME[0]}, number of backups to restore from is ${#BACKUPS[@]}"

			SELECTED_BACKUP=$(
				printf '%s\n' "${BACKUPS[@]##*/}" | \
				fzf --reverse \
					--cycle \
					--border=rounded \
					--border-label="Select a configuration backup to restore:" \
					--border-label-pos=center \
					--preview 'cmd_backup_preview {}' \
					--preview-window=hidden \
					--bind 'ctrl-p:toggle-preview'
			)

            # handle empty selection
            [[ -z "${SELECTED_BACKUP}" ]] && \
                { log_debug "function: ${FUNCNAME[0]}, no backup selected. skipping ..."; \
                    echo "No backup selected. Skipping ..."; \
                    return 0; \
                }

            local CONFIRM
            read -r -e -p "This will overwrite your current configuration with '${SELECTED_BACKUP}'. Continue? [yes/NO]: " CONFIRM
            CONFIRM="${CONFIRM^^}"
            [[ "${CONFIRM}" != "YES" ]] && \
                { log_debug "function: ${FUNCNAME[0]}, no restore has been done. skipping ..."; \
                    echo "No restore has been done. skipping ..."; \
                    return 0; \
                }

            tar -xzf "${BASHAPP_DIR}/${BASHAPP_CONFDIR}"/backups/"${SELECTED_BACKUP}" \
                -C "${BASHAPP_DIR}" && \
            { cd "${BASHAPP_DIR}"; ln -sf "${BASHAPP_CONFDIR}"/.configvars .configvars; \
                log_debug "function: ${FUNCNAME[0]}, the configuration has been restored successfully."; \
                echo "The configuration has been restored successfully."; \
                return 0; } || \
            { log_error "function: ${FUNCNAME[0]}, restore has failed."; \
                echo "Restore has failed."; \
                exit 1; }

		else

			log_error "function: ${FUNCNAME[0]}, no backups have been found"
			echo "No backups have been found. Create a few to restore from."
			exit 1
		fi

	else

		log_error "function: ${FUNCNAME[0]}, no backups folder exists"
		echo "No backups folder exists. Create backups to restore from."
		exit 1

	fi

}

# a backup's contents preview handler
cmd_backup_preview() {

    log_debug "${FUNCNAME[0]} is called"

	echo "${1} contents:"
	echo "---------------------------------------------------------------"
	echo
    tar -tzf "${BASHAPP_DIR}/${BASHAPP_CONFDIR}/backups/$1"

}
export -f cmd_backup_preview

# completion command handler
cmd_completion() {

	log_debug "${FUNCNAME[0]} is called"

	cat <<- 'COMPLETION'
	_ldapbrowser_completion() {
	    local cur prev commands debugopts setupopts
	    cur="${COMP_WORDS[COMP_CWORD]}"
	    prev="${COMP_WORDS[COMP_CWORD-1]}"

	    commands="version describe setup completion debug themes list help"
	    debugopts="on off"
	    setupopts="reset backup restore"

	    case "${prev}" in
	        ldapbrowser)
	            COMPREPLY=($(compgen -W "${commands}" -- "${cur}"))
	            return 0
	            ;;
	        debug)
	            COMPREPLY=($(compgen -W "${debugopts}" -- "${cur}"))
	            return 0
	            ;;
	        setup)
	            COMPREPLY=($(compgen -W "${setupopts}" -- "${cur}"))
	            return 0
	            ;;
	        *)
	            ;;
	    esac
	}
	complete -F _ldapbrowser_completion ldapbrowser
	COMPLETION

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
		LDAP_VIEWED_DN_ATTRIBUTES=$(curl ${CURL_OPTS} ${CACERT} "${LDAP_URL_PREFIX}${LDAP_SERVER_HOSTNAME}/${LDAP_VIEWED_DN}??base?(objectClass=*)" -u "${LDAP_BIND_ACCOUNT_ATTR}=${LDAP_BIND_ACCOUNT},${LDAP_USERS_DN},${LDAP_SUFFIX}:$(echo "${LDAP_BIND_PASSWORD}" | base64 -d)" | sed '/^$/d')
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
        CHILDREN=$(curl ${CURL_OPTS} ${CACERT} "${LDAP_URL_PREFIX}${LDAP_SERVER_HOSTNAME}/${LDAP_CURRENT_DN}?dn,rdn?one?(objectClass=*)" \
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
