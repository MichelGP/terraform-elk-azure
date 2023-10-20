[elasticsearch]
${elastic-ip}

[grafana]
${grafana-ip}

[kafka]
${kafka-ip}

[all:vars]
ansible_user="michel"
ansible_ssh_private_key_file="./ssh.pem"