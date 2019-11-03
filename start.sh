#!/bin/bash

set -e

function __get_password ()
{
	local -r password_length="${1:-16}"

	local password="$(
		head -n 4096 /dev/urandom \
		| tr -cd '[:alnum:]' \
		| cut -c1-"${password_length}"
	)"

	printf -- '%s' "${password}"
}

function __is_valid_ssh_user ()
{
	local -r safe_user='^[a-z_][a-z0-9_-]{0,29}[$a-z0-9_]?$'
	local -r user="${1}"

	if [[ ${user} =~ ${safe_user} ]]
	then
		return 0
	fi

	return 1
}

function __get_ssh_user ()
{
	local -r default_value="${1:-app-admin}"

	local value="${SSH_USER}"

	if ! __is_valid_ssh_user "${value}"
	then
		value="${default_value}"
	fi

	printf -- '%s' "${value}"
}

function __get_ssh_user ()
{
	local -r default_value="${1:-app-admin}"

	local value="${SSH_USER}"

	if ! __is_valid_ssh_user "${value}"
	then
		value="${default_value}"
	fi

	printf -- '%s' "${value}"
}

function main ()
{
	local -r password_length="16"
	ssh_user_password="${SSH_USER_PASSWORD:-"$(
		__get_password "${password_length}"
	)"}"
	ssh_user="$(__get_ssh_user)"
	ssh_root_password="$(__get_password "${password_length}")"
	if [[ ${ssh_user} != root ]]; then
            if [ id -u $ssh_user >/dev/null 2>&1 ]; then
	    	echo "user name is exist, only output password"
	    else
                echo "user name is not exist, add user"
                echo "user home path:${WORKDIR}"
		useradd -m \
			"${ssh_user}"
		printf -- \
					'%s:%s\n' \
					"${ssh_user}" \
					"${ssh_user_password}" \
				| chpasswd
		echo -e "user name:${ssh_user} \n"
             fi
		echo -e "user password:${ssh_user_password} \n"
	fi
	printf -- \
			'%s:%s\n' \
			"root" \
			"${ssh_root_password}" \
			| chpasswd
	echo -e "root password:${ssh_root_password}"
}

main "${@}"

exec /usr/sbin/sshd -D
