#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

AZURE_STORAGE_ACCOUNT=""
AZURE_STORAGE_KEY=""
CONTAINER_NAME="endpointdemo"
BLOB_NAME=$(cat /proc/sys/kernel/random/uuid)
FILE="$BLOB_NAME.txt"

if [ -z "$1" ]
  then
    echo "Arg1: Account Name for Azure Blob Storage Required"
fi

if [ -z "$2" ]
  then
    echo "Arg2: Account Key for Azure Blob Storage Required"
fi

AZURE_STORAGE_ACCOUNT=$1
AZURE_STORAGE_KEY=$2

echo "$BLOB_NAME" > $FILE
az storage container create --name $CONTAINER_NAME --account-key "$AZURE_STORAGE_KEY" --account-name "$AZURE_STORAGE_ACCOUNT" --output none


echo ""
echo "[UPLOAD] => $FILE"
echo ""
az storage blob upload --container-name $CONTAINER_NAME --file $FILE --name $FILE --account-key "$AZURE_STORAGE_KEY" --account-name "$AZURE_STORAGE_ACCOUNT"
echo ""

echo "[LIST BLOBS]"
echo ""
az storage blob list --container-name $CONTAINER_NAME --output table --account-key "$AZURE_STORAGE_KEY" --account-name "$AZURE_STORAGE_ACCOUNT"
echo ""
