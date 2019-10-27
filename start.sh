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
	if [[ ${ssh_user} != root ]]
	then
		useradd -m \
			"${ssh_user}"
		printf -- \
					'%s:%s\n' \
					"${ssh_user}" \
					"${ssh_user_password}" \
				| chpasswd
	fi
	printf -- \
			'%s:%s\n' \
			"root" \
			"$(__get_password "${password_length}")" \
			| chpasswd
}

main "${@}"

/usr/sbin/sshd -D
