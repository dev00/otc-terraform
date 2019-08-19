# Introduction

## Overview
This script is meant to be used for testing e.g. ansible roles on multiple images. For this, instances are created and provisioned with a list of images. As the OpenTelekomCloud offers two APIs - a Huawai customized one and the Openstack native one, two providers are used as an example. Everything in the `os_terraform` folder uses the [Openstack](https://www.terraform.io/docs/providers/openstack/) provider while the `otc_terraform` folder is based on the [OpenTelekomCloud](https://www.terraform.io/docs/providers/opentelekomcloud/) provider.

While the APIs are mostly compatible, some features are already used in the Huawai API which are not implemented in the openstacksdk/gophercloud (the libraries used behind e.g. Ansible Openstack modules or Terraform Openstack modules). This can lead to mild confusion when mixing them, e.g. using Terraform with the OTC provider for infrastrucutre and later on the [Openstack](https://docs.ansible.com/ansible/latest/plugins/inventory/openstack.html) [Inventory Plugin for Ansible](https://docs.ansible.com/ansible/latest/plugins/inventory.html).
**Important** The `os_example` is the current upstream, as some parts of the otc example make it much harder to group the servers later on. As there are still some issues attaching floatingips with the openstack provider, the `os_example` will now use the OpenTelekomCloud provider for attaching said FloatingIPs to the bastion host.

##  Authenticating with different methods

### With username and password (OTC and Openstack provider)
For authenticating against the OTC, the following environment variables need to be set
```
OS_AUTH_URL=https://iam.eu-de.otc.t-systems.com:443/v3
OS_PROJECT_NAME=<your project, usually eu-de, or eu-de_subprojectname when using sub projects>
OS_USER_DOMAIN_NAME=<your Domain name, starting with OTC>
OS_IDENTITY_API_VERSION=3
OS_PASSWORD=<your login password>
OS_USERNAME=<your login name>
```

Do **not** enable 2FA, otherwhise the login will fail! Please ensure `OS_ACCESS_KEY` and `OS_SECRET_KEY` are not set when you want to use the OpenTelekomCloud providers, otherwhise Terraform will try to use them and possibly fail due to the fact that `OS_USER_DOMAIN_NAME` is set (see below for explaination).

### With AK/SK (OTC provider only)
Using AK/SK for logging in is possible as well. For a tutorial how to obtain AK/SK, please look [here](https://cloud.telekom.de/de/infrastruktur/open-telekom-cloud/tutorials/apis-opentelekomcloud) at **Let's talk about the Object Storage Service**.

Please set the following environment variables
```
OS_AUTH_URL=https://iam.eu-de.otc.t-systems.com:443/v3
OS_PROJECT_NAME=<your project, usually eu-de, or eu-de_subprojectname when using sub projects>
OS_IDENTITY_API_VERSION=3
OS_ACCESS_KEY=<your access key id>
OS_SECRET_KEY=<your secret key>
```

When using AK/SK authentication, please ensure `OS_USER_DOMAIN_NAME` (or `domain_name` in terraform) is **not** set, otherwise the login will fail, stating it couldn't find the IAM.
**This is a known bug and already reported [here](https://github.com/terraform-providers/terraform-provider-opentelekomcloud/issues/343)**

## Getting it up and running
The steps to get this running are rather simple, assuming you have terraform already installed. If not, take a look [here](https://learn.hashicorp.com/terraform/getting-started/install.html). After doing so, simply:
1. Clone this repo
2. Create a file `variables.tfvars` (in best cases outside the git folder, and link it afterwards right next to the `tf` files in `os_examples` and `otc_examples`), adding the following line: `public_key = <YOUR_PUBLIC_KEY>`, replacing the placeholder with your own SSH public key
3. Choose whether you want to use the Openstack Resource Provider (in that case, go to `os_examples`) or the OpenTelekomCloud Provider (then go to `otc_examples`)
4. Ensure the correct environment vars are set
5. Run `terraform init`, `terraform plan` and `terraform apply` - if you create the `variables.tfvars` it will start automatically, otherwise it will ask for your public key.
6. Do whatever you want with the newly provisioned infrastructure, maybe using the Ansible Inventory, which is per default created at `/tmp/ansible_inventory.ini` and utilizes a public reachable bastion host for connecting to the test instances.
8. Run `terraform destroy -var-file=variables.tfvars` to tear down everything you built before.

## Openstack provider specific setting
Due to some limitations of the Openstack native API, additional variables must considered. In our case the following ones:
- `external_network_id`: The ID of the external network the router will connect and which will be the routers default gateway. This can be obtained by issuing `openstack network list` and looking for the network called `admin_external_net`. The default value in this repository will be updated in case it changes, however when additional regions are supported by OTC or multiple external networks are available (and outgoing traffic should be sent into another external network), changing said value is required.

## Dirty hacks used
As this terraform script hides a lot of complexity not only interacting with the APIs, but also preparing the inventory for Ansible, a bunch of hacks is used.

### Bastion hosts
This is a setup meant to be used with a bastion host and TcpForwarding via SSH, so it's **mandatory** to set `AllowTcpForwarding yes` in your `sshd_conf`. This was added due to the fact the netcat based solution turned out to be rather unstable and extremly slow. If you cant resist, change the Ansible inventory template, but we do **not** recommend it!

### Key Authentication and Host Keys
To avoid fiddling around with private keys, we assume you use SSH Agent forwarding, and the private key is added to said Agent. This agent is then tunneled to the bastion host and from there tunneled further to the other instances. For working seamless this needed a bunch of extra arguments in the inventory file, take a look at the `ansible_inventory.tpl`.

### openstack provider bug at the network resource
When creating a network, the OTC sets `dns_domain` by default, even if it was not set by terraform. Running TF again it will try to unset this value as it was not defined in the terraform file. This will then break because the user is not allowed to set said value. This can be avoided by adding `dns_domain="eu-de.compute.internal."` to the vpc resource called *os_network_1* at `os_example/vpc/main` after the initial run.
This bug was already [reported](https://github.com/terraform-providers/terraform-provider-openstack/issues/836), fixed and is now waiting for merge and release.
