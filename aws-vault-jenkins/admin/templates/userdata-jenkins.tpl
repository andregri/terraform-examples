#!/usr/bin/env bash
set -x
exec > >(tee /var/log/tf-user-data.log|logger -t user-data ) 2>&1

logger() {
  DT=$(date '+%Y/%m/%d %H:%M:%S')
  echo "$DT $0: $1"
}

logger "Running Vault Server"

##--------------------------------------------------------------------
## Variables

# Get Private IP address
#HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/hostname)
PRIVATE_IP=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)
#PUBLIC_IP=$(curl http://169.254.169.254/latest/meta-data/public-ipv4)

AWS_REGION="${tpl_aws_region}"
KMS_KEY="${tpl_kms_key}"

# Detect package management system.
YUM=$(which yum 2>/dev/null)
APT_GET=$(which apt-get 2>/dev/null)

# Raft node ID
NODE_ID="${tpl_node_id}"

##--------------------------------------------------------------------
## Functions

user_ubuntu() {
  # UBUNTU user setup
  if ! getent group $${USER_GROUP} >/dev/null
  then
    sudo addgroup --system $${USER_GROUP} >/dev/null
  fi

  if ! getent passwd $${USER_NAME} >/dev/null
  then
    sudo adduser \
      --system \
      --disabled-login \
      --ingroup $${USER_GROUP} \
      --home $${USER_HOME} \
      --no-create-home \
      --gecos "$${USER_COMMENT}" \
      --shell /bin/false \
      $${USER_NAME}  >/dev/null
  fi
}

##--------------------------------------------------------------------
## Install Base Prerequisites

logger "Setting timezone to UTC"
sudo timedatectl set-timezone UTC

if [[ ! -z $${APT_GET} ]]; then
  logger "Debian/Ubuntu system detected"
  logger "Performing updates and installing prerequisites"
  sudo apt-get -qq -y update
  sudo apt-get install -qq -y wget unzip dnsutils ruby rubygems ntp jq
  sudo systemctl start ntp.service
  sudo systemctl enable ntp.service
  logger "Disable reverse dns lookup in SSH"
  sudo sh -c 'echo "\nUseDNS no" >> /etc/ssh/sshd_config'
  sudo service ssh restart
else
  logger "Prerequisites not installed due to OS detection failure"
  exit 1;
fi

##--------------------------------------------------------------------
## Install AWS-Specific Prerequisites

if [[ ! -z $${APT_GET} ]]; then
  logger "Debian/Ubuntu system detected"
  logger "Performing updates and installing prerequisites"
  sudo apt-get -qq -y update
  sudo apt-get install -qq -y awscli
else
  logger "AWS Prerequisites not installed due to OS detection failure"
  exit 1;
fi

##--------------------------------------------------------------------
## Configure Jenkins user

USER_NAME="jenkins"
USER_COMMENT="Jenkins user"
USER_GROUP="jenkins"
USER_HOME="/srv/jenkins"

if [[ ! -z $${APT_GET} ]]; then
  logger "Setting up user $${USER_NAME} for Debian/Ubuntu"
  user_ubuntu
else
  logger "$${USER_NAME} user not created due to OS detection failure"
  exit 1;
fi

##--------------------------------------------------------------------
## Install Java and Jenkins
sudo apt update
sudo apt install openjdk-11-jre -y
wget -q -O - https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb http://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install jenkins -y
sudo systemctl enable jenkins
sudo systemctl start jenkins

##--------------------------------------------------------------------
## Install Vault

#logger "Downloading Vault"
#curl -o /tmp/vault.zip $${VAULT_ZIP}
#
#logger "Installing Vault"
#sudo unzip -o /tmp/vault.zip -d /usr/local/bin/
#sudo chmod 0755 /usr/local/bin/vault
#sudo chown vault:vault /usr/local/bin/vault
#sudo mkdir -pm 0755 /etc/vault.d
#sudo mkdir -pm 0755 /etc/ssl/vault
#
#logger "/usr/local/bin/vault --version: $(/usr/local/bin/vault --version)"