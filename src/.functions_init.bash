# Various init functions

# cleanup function when app exits
cleanup_and_exit() {

	log_debug "${FUNCNAME[0]} is called"

	log_info "${BASHAPP_NAME} has finished."
    exit 0
}

# check for app dependencies function
check_for_app_deps() {

	log_debug "${FUNCNAME[0]} is called"

	if [[ -f ${BASHAPP_DIR}/.deps ]]
	then

		log_debug "function: ${FUNCNAME[0]}, if #1"

		while IFS= read -r line
		do

			log_debug "function: ${FUNCNAME[0]}, while loop"

    		if [[ -z "$line" || "$line" =~ ^# ]]
			then
				log_debug "function: ${FUNCNAME[0]}, if #2"
        		continue
    		fi
			
			if ! command -v "$line" &> /dev/null
			then

				log_debug "function: ${FUNCNAME[0]}, if #3"

				echo "'$line' is a required dependency but does not exist. Please install it or add to the PATH."
				log_error "'$line' is a required dependency but does not exist. Please install it or add to the PATH."
				exit 1
			fi

		done < "${BASHAPP_DIR}"/.deps
	else
		log_error "There is no .deps file in the bash application folder."
		echo "There is no .deps file in the bash application folder."
		exit 1
	fi
}

# check for LDAP protocol support
check_ldap_support() {

	log_debug "${FUNCNAME[0]} is called"

	curl -V 2>/dev/null | grep -qi '^Protocols:.*\<ldap\>' || return 1

	return 0

}

# check app connectivity function
check_app_connectivity() {

	log_debug "${FUNCNAME[0]} is called"

    if [[ "${#LDAP_SERVER_HOSTNAMES[@]}" -gt 0 && \
		  -n "${LDAP_BIND_ACCOUNT_ATTR}" && \
		  -n "${LDAP_BIND_ACCOUNT}" && \
		  -n "${LDAP_BIND_PASSWORD}" && \
		  -n "${CACERT}" ]]
    then

		log_debug "function: ${FUNCNAME[0]}, if #1"
		log_debug "function: ${FUNCNAME[0]}, LDAP_SERVER_HOSTNAMES = ${LDAP_SERVER_HOSTNAMES[*]}"
		log_debug "function: ${FUNCNAME[0]}, LDAP hosts number is ${#LDAP_SERVER_HOSTNAMES[@]}"
		log_debug "function: ${FUNCNAME[0]}, LDAP_DIRECTORY_TYPE = ${LDAP_DIRECTORY_TYPE}"
		log_debug "function: ${FUNCNAME[0]}, LDAP_BIND_ACCOUNT = ${LDAP_BIND_ACCOUNT}"
		# uncomment the below LDAP_BIND_PASSWORD lines debug log if absolutely needed!
		#log_debug "function: ${FUNCNAME[0]}, LDAP_BIND_PASSWORD = $(echo "${LDAP_BIND_PASSWORD}" | base64 -d)"
		log_debug "function: ${FUNCNAME[0]}, LDAP_SUFFIX = ${LDAP_SUFFIX}"
		log_debug "function: ${FUNCNAME[0]}, LDAP_BASE_DN = ${LDAP_BASE_DN}"
		log_debug "function: ${FUNCNAME[0]}, LDAP_CURRENT_DN = ${LDAP_CURRENT_DN}"
		log_debug "function: ${FUNCNAME[0]}, CURL_OPTS = ${CURL_OPTS}"
		log_debug "function: ${FUNCNAME[0]}, CACERT = ${CACERT}"

		for host in "${LDAP_SERVER_HOSTNAMES[@]}"
		do

			log_debug "function: ${FUNCNAME[0]}, for loop"
			log_debug "function: ${FUNCNAME[0]}, host = $host"

			if curl ${CURL_OPTS} ${CACERT} --fail \
					"ldap://${host}/${LDAP_CURRENT_DN}??base?(objectClass=*)" \
					-u "${LDAP_BIND_ACCOUNT_ATTR}=${LDAP_BIND_ACCOUNT},${LDAP_USERS_DN},${LDAP_SUFFIX}:$(echo "${LDAP_BIND_PASSWORD}" \
					| base64 -d)" >/dev/null 2>&1
			then

				log_debug "function: ${FUNCNAME[0]}, if #2"

				export LDAP_SERVER_HOSTNAME="$host"
				break
			fi
		done

		if [[ -z "${LDAP_SERVER_HOSTNAME}" ]]
		then

			log_debug "function: ${FUNCNAME[0]}, if #3"
			log_debug "function: ${FUNCNAME[0]}, LDAP_SERVER_HOSTNAME = ${LDAP_SERVER_HOSTNAME}"

			echo "The authentication, network connectivity error or some other error. \
				  Check the credentials and the network connectivity. Exiting..."
            log_error "The authentication, network connectivity error or some other error. Check the credentials and the network connectivity. Exiting..."
            exit 1
        fi
	else
        echo "Some essential vars are not set. Please reference the documentation and examples, and set them in the .configvars file in the app's folder."
        log_error "Some essential vars are not set. Please reference the documentation and examples, and set them in the .configvars file in the app's folder."
        exit 1
    fi
}
