[testing]
%{ for server in instances}${server.name} ansible_host=${server.access_ip_v4} ansible_user=${server.all_metadata.login_user} ansible_ssh_common_args='-o ProxyCommand="ssh -W %h%p -q ${bastion_user}@${bastion_ip} -A -o StrictHostKeyChecking=no"' ansible_ssh_extra_args='-o StrictHostKeyChecking=no'
%{ endfor }

[bastion]
${bastion.name} ansible_host=${bastion_ip} ansible_user=${bastion_user} ansible_ssh_extra_args='-o StrictHostKeyChecking=no'
