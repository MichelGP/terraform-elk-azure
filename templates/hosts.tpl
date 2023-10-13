[elasticsearch]
${elastic-ip}

[grafana]
${grafana-ip}

[logstash]
${logstash-ip}

[jumpbox]
${jumpbox-ip}

[all:vars]
ansible_user="michel"
ansible_ssh_private_key_file="./ssh.pem"
