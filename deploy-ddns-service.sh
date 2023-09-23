#!/bin/bash

# Check if Ansible is installed
if ! command -v ansible-playbook &> /dev/null
then
    echo "Ansible could not be found. Please install Ansible and try again."
    exit 1
fi

# Execute the Ansible playbook
ansible-playbook --inventory inventory.yml --ask-vault-pass ansible/setup.yml
