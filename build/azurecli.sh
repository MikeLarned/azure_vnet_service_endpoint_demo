#!/usr/bin/env bash
set -o errexit
set -o pipefail
set -o nounset

MS_KEYRING="/etc/apt/trusted.gpg.d/Microsoft.gpg"
MS_KEYSERVER="packages.microsoft.com"
MS_KEY="BC528686B50D79E339D3721CEB3E94ADBE1229CF"

sudo apt-get install apt-transport-https lsb-release software-properties-common -y

AZ_REPO=$(lsb_release -cs) 
echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $AZ_REPO main" | sudo tee /etc/apt/sources.list.d/azure-cli.list

sudo apt-key --keyring $MS_KEYRING adv --keyserver $MS_KEYSERVER --recv-keys $MS_KEY
sudo apt-get update
sudo apt-get install azure-cli