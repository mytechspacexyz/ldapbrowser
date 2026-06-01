#!/usr/bin/env bash

export BASHAPP_DIR=$(dirname "$(readlink -f "$0")")

[[ -f ${BASHAPP_DIR}/.common_configvars ]] && . "${BASHAPP_DIR}"/.common_configvars || echo "There is no .common_configvars file available in this package"
[[ -f ${BASHAPP_DIR}/.configvars ]] && . "${BASHAPP_DIR}"/.configvars || echo "There is no .configvars file available in this package"
[[ -f ${BASHAPP_DIR}/${BASHAPP_SRCDIR}/.functions.bash ]] && . "${BASHAPP_DIR}"/${BASHAPP_SRCDIR}/.functions.bash || echo "There is no .functions.bash file available in this package"

# Trap the SIGINT signal (Ctrl+C)
trap cleanup_and_exit INT

# Main bash application function
main() {

	log_info "${BASHAPP_NAME} is running."

	log_debug "${FUNCNAME[0]} is called"
	log_debug "with the arguments: $*"

	# checking for bash application dependencies
	check_for_app_deps

	check_ldap_support || {

		log_error "function: ${FUNCNAME[0]}, LDAP protocol is not supported in curl. Exiting..."

		echo "LDAP protocol is not supported in curl. Exiting..."
		return 1

	}

    if [[ $# -eq 0 ]]
	then
		log_debug "function: ${FUNCNAME[0]}, if #1"
        cmd_help
		log_info "${BASHAPP_NAME} has finished."
        return 0
    fi

	if [[ $# -gt 2 ]]
	then
		echo "Too many arguments entered. Please see the help below to run correctly."
		echo
		log_error "function: ${FUNCNAME[0]}, too many arguments entered"
		cmd_help
		log_info "${BASHAPP_NAME} has finished."
		return 1
	fi
    
    local command="$1"
    shift
    
	log_debug "function: ${FUNCNAME[0]}, case"
    case "$command" in
	   "setup")
			# setting bash application with required settings
			cmd_setup
			;;
		"debug")
			# turn debug mode on/off
			cmd_debug "$1"
            ;;
		"themes")
			cmd_themes
			;;
       "list")
			# checking bash application connectivity
			check_app_connectivity
			# if connectivity is ok then proceed to the list command handler
            cmd_list
            ;;
        "version")
            cmd_version
            ;;
		"describe")
			cmd_describe
			;;
        "help")
            cmd_help
            ;;
        *)
			cmd_unknown "$command"
			log_error "Unknown command '$command' for the $BASHAPP_NAME."
            return 1
            ;;
    esac

	log_info "${BASHAPP_NAME} has finished."
}

# Run main bash application function with all the arguments
main "$@"
