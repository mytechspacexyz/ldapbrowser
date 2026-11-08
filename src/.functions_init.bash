# Various init functions

# init app's dirs function
init_dirs() {

	log_debug "${FUNCNAME[0]} is called"

	mkdir -p -m 700 "${BASHAPP_TMPDIR}" || \
		{ 
			log_error "function: ${FUNCNAME[0]}, failed to create temp directory ${BASHAPP_TMPDIR}";
			echo "Failed to create temp directory ${BASHAPP_TMPDIR}. Exiting...";
			exit 1; 
		}

	log_debug "function: ${FUNCNAME[0]}, ${BASHAPP_TMPDIR} created successfully"

}

# cleanup function when app exits
cleanup_and_exit() {

	local EXITSTATUS=$?
	local SIGNALNAME="${1:-EXIT}"

	log_debug "${FUNCNAME[0]} is called"
	log_debug "${FUNCNAME[0]} is called, signal=${SIGNALNAME}, status=${EXITSTATUS}, pid=$$, bashpid=${BASHPID}"

	# disarm the trap first so not to be called twice
	trap - EXIT INT TERM HUP

	# ignore further signals while cleaning up
	trap '' INT TERM HUP

	# a signal exits with its conventional code
	case "${SIGNALNAME}" in
		INT)  EXITSTATUS=130 ;;
		TERM) EXITSTATUS=143 ;;
		HUP)  EXITSTATUS=129 ;;
	esac

	log_debug "${FUNCNAME[0]}, deleting the bash app's temp folder ${BASHAPP_TMPDIR}"
	[[ -d "${BASHAPP_TMPDIR}" ]] && rm -rf "${BASHAPP_TMPDIR}"

	log_info "${FUNCNAME[0]}, ${BASHAPP_NAME} has finished, signal=${SIGNALNAME}, exit status=${EXITSTATUS}"

	exit "${EXITSTATUS}"

}

# check for app dependencies function
check_for_app_deps() {

	log_debug "${FUNCNAME[0]} is called"

	[[ ! -f "${BASHAPP_DIR}/.deps" ]] && \
		{
			log_error "There is no .deps file in the bash application folder.";
			echo "There is no .deps file in the bash application folder.";
			exit 1;
		}

	local OSID OSIDLIKE
	if [[ -f /etc/os-release ]]
	then
		source /etc/os-release
		OSID="${ID}"
		OSIDLIKE="${ID_LIKE}"
	elif [[ "$(uname -s)" == "Darwin" ]]
	then
		OSID="macos"
		OSIDLIKE=""
	else
		OSID="unknown"
		OSIDLIKE=""
	fi

	local DISTROCLASS
	case "${OSID}" in
		ubuntu|debian)						DISTROCLASS="debian"	;;
		fedora|rocky|almalinux|rhel|centos) DISTROCLASS="rhel"		;;
		arch|manjaro)						DISTROCLASS="arch"		;;
		opensuse*|sles)						DISTROCLASS="suse"		;;
		alpine)								DISTROCLASS="alpine"	;;
		macos)								DISTROCLASS="macos"		;;
		*)
			case "${OSIDLIKE}" in
				*debian*) 			DISTROCLASS="debian"	;;
				*rhel*|*fedora*)	DISTROCLASS="rhel"		;;
				*arch*)				DISTROCLASS="arch"		;;
				*suse*)				DISTROCLASS="suse"		;;
				*)					DISTROCLASS="unknown"	;;
			esac
			;;
	esac

	local PKGMGRCMD
	case "${DISTROCLASS}" in
		debian) PKGMGRCMD="sudo apt-get install -y"	;;
		rhel)   PKGMGRCMD="sudo dnf install -y"		;;
		arch)   PKGMGRCMD="sudo pacman -S"			;;
		suse)   PKGMGRCMD="sudo zypper install"		;;
		alpine) PKGMGRCMD="sudo apk add"			;;
		macos)  PKGMGRCMD="brew install"			;;
		*)      PKGMGRCMD=""						;;
	esac

	local -a MISSINGDEPS
	while IFS= read -r line
	do
		[[ -z "${line}" || "${line}" =~ ^# ]] && continue

		log_debug "function: ${FUNCNAME[0]}, checking dependency ${line}"

		if ! command -v "${line}" &> /dev/null; then
			MISSINGDEPS+=("${line}")
		fi
	done < "${BASHAPP_DIR}/.deps"

	if [[ "${#MISSINGDEPS[@]}" -gt 0 ]]
	then

		log_error "function: ${FUNCNAME[0]}, the following required dependencies are missing:"

		echo "The following required dependencies are missing:"
		echo

		local DEP
		for DEP in "${MISSINGDEPS[@]}"
		do

			log_error "function: ${FUNCNAME[0]}, ${DEP}"

			echo "${DEP}"

		done

		echo
		echo "You may need to install packages depending on your Linux/Unix distro class:"
		echo
		echo "Distro class detected: ${DISTROCLASS}"
		echo

		case "${DISTROCLASS}" in
			debian) echo "Debian/Ubuntu:   ${PKGMGRCMD} curl libxml2-utils fzf bsdextrautils coreutils tar sed grep gawk"	;;
			rhel)   echo "RHEL/Rocky/Alma: ${PKGMGRCMD} curl libxml2 fzf util-linux coreutils tar sed grep gawk"		;;
			arch)   echo "Arch/Manjaro:    ${PKGMGRCMD} curl libxml2 fzf util-linux coreutils tar sed grep gawk"		;;
			suse)   echo "OpenSUSE:        ${PKGMGRCMD} curl libxml2-tools util-linux coreutils tar sed grep gawk"		;;
			alpine) echo "Alpine:          ${PKGMGRCMD} curl libxml2-utils fzf util-linux coreutils tar sed grep gawk"		;;
			macos)  echo "macOS:           ${PKGMGRCMD} curl libxml2 fzf util-linux coreutils tar gnu-sed grep gawk"	;;
			*)
				echo "Unknown distro."
				echo "Please install manually: curl, xmllint, fzf, tar, sed, grep, awk, column, coreutils, "
				;;
		esac

		exit 1
	fi

	log_debug "function: ${FUNCNAME[0]}, all dependencies satisfied on detected OS: ${OSID} (family: ${DISTROCLASS})"

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
					"${LDAP_URL_PREFIX}${host}/${LDAP_CURRENT_DN}??base?(objectClass=*)" \
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
