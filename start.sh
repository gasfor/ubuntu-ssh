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

function __is_valid_ssh_user_home ()
{
	local -r home_directory="${1}"
	local -r user_directory='^\/(?!\/|bin|dev|etc|lib|lib64|lost+found|media|proc|root|sbin|srv|sys|tmp|usr).+$'
	local -r root_directory='^/root$'
	local -r user="${2:-"$(
		__get_ssh_user
	)"}"

	local safe_directory="${user_directory}"

	if [[ -z ${home_directory} ]]
	then
		return 1
	fi

	if [[ ${user} == root ]]
	then
		safe_directory="${root_directory}"
	fi

	if grep -qoP "${safe_directory}" <<< "${home_directory}"
	then
		return 0
	fi

	return 1
}

function __get_ssh_user_home ()
{
	local -r default_value="${1:-/home/%u}"
	local -r root_value="/root"
	local -r user="${2:-"$(
		__get_ssh_user
	)"}"

	local value="${SSH_USER_HOME}"

	if ! __is_valid_ssh_user_home "${value}"
	then
		if [[ ${user} == root ]]
		then
			value="${root_value}"
		else
			value="${default_value}"
		fi
	fi

	# Replace %u with SSH_USER
	value="${value//'%u'/${user}}"

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
	ssh_user_home="$(
		__get_ssh_user_home
	)"
	if [[ ${ssh_user} == root ]]
	then
		chsh \
			-s "${ssh_user_shell}" \
			"${ssh_user}" \
			&> /dev/null
	else
		# Create base directory for home
		if [[ -n ${ssh_user_home%/*} ]] \
			&& [[ ! -d ${ssh_user_home%/*} ]]
		then
			mkdir -pm 755 "${ssh_user_home%/*}"
		fi
		useradd -m \
			-d "${ssh_user_home}" \
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
