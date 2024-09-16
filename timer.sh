#!/bin/bash

# $1: none
# return: status
function get_list {
	local current_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

	local -a subname_list="$(ls -al "${current_path}/.." | awk '{print $NF}' | grep ".*cool_ecc$" | cut -d"." -f 1 | grep -v "albert")"
	if [[ $? -ne 0 ]]; then
		return 1
	fi

	printf '%s' "${subname_list}"
	return 0
}

function put_into_acme_auto {
	local current_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	local log_path="${current_path}/my_acme.log"

	printf "\n%s\n" "----------------------------" >>"${log_path}"
	printf "\n%s\n" "BEGIN TIME: $(date)" >>"${log_path}"
	printf "\n%s\n" "----------------------------" >>"${log_path}"

	local -a subname_list_arr
	mapfile -t subname_list_arr <<<"$(get_list)"

	for ele in "${subname_list_arr[@]}"; do
		local job_id=$(jobs | tail -n 1 | awk '{print $1}')
		# being multi sub shell
		{
			printf "%s\n" "JOB ID: $job_id"
			printf "%s\n" "CURRENT MODULE:$ele"
			bash "${current_path}/auto_acme.sh" "${ele}"
		} | flock "${log_path}" tee -a "${log_path}" &
	done

	# jobs >>"${log_path}"
	wait
	printf "\n%s\n" "----------------------------" >>"${log_path}"
	printf "\n%s\n" "END TIME: $(date)" >>"${log_path}"
	printf "\n%s\n" "----------------------------" >>"${log_path}"
	return 0
}

put_into_acme_auto 2>&1 >/dev/null
