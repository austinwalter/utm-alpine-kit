#!/bin/bash

set -euo pipefail

NL=$'\n' # Newline

# Arguments
VM_NAME="Current (Alpine)"
VM_IP=""
SSH_KEY="id_ed25519_vm"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"
VM_IP="192.168.64.98"

# Removed the old VM with the same name
source ./scripts/destroy-vm.sh "$VM_NAME"

# Exports $VM_IP with ip address for the new cloned VM 
source ./scripts/clone-vm.sh "$VM_NAME" --ssh "$SSH_KEY"

echo "${NL}VM IP: $VM_IP${NL}"

trap 'trap - ERR;return' ERR
source ./scripts/provision-for-testing.sh \
  --name "$VM_NAME" \
  --ip "$VM_IP" \
  --ssh "$SSH_KEY"
