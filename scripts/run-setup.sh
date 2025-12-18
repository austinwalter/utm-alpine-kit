#!/bin/bash

# https://gist.github.com/mohanpedala/1e2ff5661761d3abd0385e8223e16425
# http://redsymbol.net/articles/unofficial-bash-strict-mode
# https://mywiki.wooledge.org/BashFAQ/105
set -euo pipefail

# Config
NL=$'\n' # Newline

# Only actually exits the shell if the exit code is non-zero
exit() {
  local exit_code="${1-?}"
  test "$exit_code" -ne 0 && builtin exit "$exit_code"
  :
}

# Arguments
VM_NAME="Current (Alpine)"
VM_IP=""
SSH_KEY="id_ed25519_vm"
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=10"

# Removed the old VM with the same name
source ./scripts/destroy-vm.sh "$VM_NAME"

# Exports $VM_IP with ip address for the new cloned VM 
source ./scripts/clone-vm.sh "$VM_NAME" --ssh "$SSH_KEY"

echo "${NL}VM IP: $VM_IP${NL}"

trap 'trap - ERR;return' ERR
source ./scripts/provision-for-testing.sh \
  --name "$VM_NAME" \
  --ip "$VM_IP" \
  --ssh "$SSH_KEY" \
  --command "npm test"
#  --repo "git@github.com:example/app.git" \

ssh -A root@"$VM_IP" 'hostname; whoami'
ssh -A root@"$VM_IP" "$(< ./scripts/provision.sh)"
builtin exit 0
