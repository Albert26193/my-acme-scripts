#!/bin/bash

# $1: none
# return: status
function get_list {
	local current_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

	local -a subname_list="$(ls -al ${current_path} | awk '{print $NF}' | grep ".*cool_ecc$" | cut -d"." -f 1 | grep -v "albert")"
	if [[ $? -ne 0 ]]; then
		return 1
	fi

	printf '%s' "${subname_list}"
	return 0
}

function put_into_acme_auto {
	local current_path="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
	local -a subname_list_arr
	mapfile -t subname_list_arr <<<"$(get_list)"

	for ele in "${subname_list_arr[@]}"; do
		bash "${current_path}/auto_acme.sh" "${ele}" &
	done
    
    jobs
    wait
	return 0
}

put_into_acme_auto
