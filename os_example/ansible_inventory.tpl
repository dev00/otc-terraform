%{ for server in instances}${server.name} ansible_host=${server.access_ip_v4}
%{ endfor }