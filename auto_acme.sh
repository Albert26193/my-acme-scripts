#!/bin/bash

acme.sh --set-default-ca --server letsencrypt

if [[ -z $1 ]]; then
	echo "no argument"
	exit 1
fi

declare -r site="$1"
declare -r acme_path="/home/albert/.acme.sh"
declare -r domain_name="albert.cool"
declare -r temp_install_path="${acme_path}/temp_ssl"
declare -r install_path="/etc/nginx/ssl"
declare -r full_url="$1.${domain_name}"
declare -i is_force=0

if [[ -n $2 && $2 == "--force" ]]; then
	is_force=1
	echo "Force renw it!"
fi

function acme_get {
	if [[ ${is_force} -eq 0 ]]; then
		bash "${acme_path}/acme.sh" --issue --dns dns_ali -d "${full_url}"
	else
		bash "${acme_path}/acme.sh" --issue --dns dns_ali -d "${full_url}" --force
	fi
}

function acme_install_cert {
	bash "${acme_path}/acme.sh" --install-cert -d "${full_url}" \
		--cert-file "${temp_install_path}/${full_url}.cer" \
		--key-file "${temp_install_path}/${full_url}.key" \
		--fullchain-file "${temp_install_path}/${site}.fullchain.cer" &&
		sudo cp ${temp_install_path}/* "${install_path}"
}

function acme_show_nginx_block {
	echo "server {
            listen 80;
            listen 443 ssl;
            listen [::]:443 ssl;
            server_name ${site}.albert.cool;

            ssl_certificate \"/etc/nginx/ssl/${site}.fullchain.cer\";
            ssl_certificate_key \"/etc/nginx/ssl/${site}.albert.cool.key\";

            if (\$scheme = http) {
                return 301 https://\$host\$request_uri;
            }

            location / {
                proxy_pass http://127.0.0.1:3002;
                #proxy_set_header Host \$host;
                proxy_set_header X-Real-IP \$remote_addr;
                proxy_set_header X-Forwarded-For \$remote_addr;
            }
    }"
}

acme_get &&
	acme_install_cert &&
	acme_show_nginx_block &&
	sudo systemctl restart nginx
