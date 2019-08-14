[all]
%{ for server in instances}${server.name} ansible_host=${server.access_ip_v4} ansible_user=${server.all_metadata.login_user} ansible_ssh_common_args='-o ProxyCommand="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -vv ${bastion_user}@${bastion_ip} -p 22 -A nc -w 1 %h %p"' ansible_ssh_extra_args='-o StrictHostKeyChecking=no'
%{ endfor }
