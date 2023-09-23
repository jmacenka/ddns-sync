# DNS Updater for Cloudflare

This project automates the DNS record updates on Cloudflare with the current public IPv4 and IPv6 of the host machine. This is especially useful when the host is assigned a dynamic IP by the ISP. The DNS update script is run as a systemd service every 30 seconds through a systemd timer.

## Structure

- `ansible/`: Contains Ansible playbook and templates for setting up the environment.
- `scripts/`: Holds the bash script for updating the DNS records on Cloudflare.
- `inventory.yml`: Contains the list of hosts where the DNS updater service will be deployed.
- `deploy-ddns-service.sh`: Script to execute the Ansible playbook.
- `credentials.yml`: Ansible vault file containing sensitive data like API keys and domains (This file is not included in the repository due to its sensitive nature).

## Pre-requisites

- Ubuntu machine
- Ansible
- Cloudflare account with a domain added

## Setup

1. Clone the repository to your local machine.
   ```sh
   git clone https://github.com/username/project_name.git
   cd project_name
