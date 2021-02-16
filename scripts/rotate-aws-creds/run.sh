#!/bin/bash
set -euo pipefail

ENVIRONMENT=${1:-}
CLUSTER_ID=${2:-}
if [[ ${ENVIRONMENT} == "" || ${CLUSTER_ID} == "" ]]; then
    echo "Usage: $0 <environment> <cluster id> "
    exit 1
fi

CLUSTER_ID=$(ocm list clusters --managed --columns id,external_id | grep "${CLUSTER_ID}" | awk '{print $1}')
if [[ "${CLUSTER_ID}" == "" ]]; then
    echo "Cluster ID ${CLUSTER_ID} could not be found"
    exit 1
fi

SHARD_NAME=$(ocm get "/api/clusters_mgmt/v1/clusters/${CLUSTER_ID}/provision_shard" | jq -r '.aws_account_operator_config.server' | cut -d '.' -f2)

if [[ "${SHARD_NAME}" == "hive-stage" || "${SHARD_NAME}" == "hive-production" ]]; then
    exec "$(dirname "$0")/v3.sh" "${ENVIRONMENT}" "${CLUSTER_ID}"
else
    exec "$(dirname "$0")/sharded.sh" "${CLUSTER_ID}" "${SHARD_NAME}"
fi
