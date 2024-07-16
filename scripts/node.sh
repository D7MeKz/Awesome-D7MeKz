#!/bin/sh

# Fetch nodes information in JSON format
NODES=$(kubectl get nodes -o json)

# Iterate over each node
echo "$NODES" | jq -c '.items[]' | while read -r SERVER; do
  # Extract the node name
  NAME=$(echo "$SERVER" | jq -r '.metadata.name')

  # Continue the loop if the node name is "master"
  if [ "$NAME" = "master" ]; then
    continue
  fi

  # Extract the IPIP Tunnel Address
  TUNNEL_ADDR=$(echo "$SERVER" | jq -r '.metadata.annotations["projectcalico.org/IPv4IPIPTunnelAddr"]')

  # Print the node name and the IPIP Tunnel Address if it exists
  if [ -n "$TUNNEL_ADDR" ]; then
    echo "$TUNNEL_ADDR"
  fi
done

