#!/bin/bash
export PATH=$PATH:/usr/local/bin
sudo amazon-linux-extras install epel -y
sudo yum -y install epel-release # repository that provides 'daemonize'
sudo yum -y update
sudo yum -y install vim python pip python3 python3-pip iputils telnet bash-completion git

echo "Install Java JDK"
sudo yum remove java -y
sudo amazon-linux-extras install java-openjdk11 -y
sudo yum install java -y

echo "Install pipreqs"
pip install pipreqs

echo "Install Terraform"
wget https://releases.hashicorp.com/terraform/1.0.7/terraform_1.0.7_linux_amd64.zip
unzip terraform_1.0.7_linux_amd64.zip
sudo chmod +x ./terraform
sudo install -o root -g root -m 0755 terraform /usr/local/bin/terraform
rm -rf terraform terraform_1.0.7_linux_amd64.zip

echo "Install Kubernetes Tools"
#Install kubectl
sudo curl --silent --location -o /usr/local/bin/kubectl \
   https://amazon-eks.s3.us-west-2.amazonaws.com/1.21.2/2021-07-05/bin/linux/amd64/kubectl
sudo chmod +x /usr/local/bin/kubectl

#Update awscli
#sudo yum install awscli

#Enable kubectl bash_completion
echo 'source <(kubectl completion bash)' >>~/.bashrc
sudo kubectl completion bash >/etc/bash_completion.d/kubectl

#Install Helm
wget https://get.helm.sh/helm-v3.7.0-linux-amd64.tar.gz
tar xvzf helm-v3.7.0-linux-amd64.tar.gz
sudo mv linux-amd64/helm /usr/local/bin/helm
sudo chmod +x /usr/local/bin/helm

echo "Install Docker engine"
sudo yum install docker -y
#sudo usermod -a -G docker jenkins
#sudo service docker start
sudo systemctl enable docker

echo "Install Docker Compose"
sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

echo "Install Jenkins"
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io.key
sudo yum -y install jenkins
#sudo echo 'jenkins ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
sudo usermod -aG docker $USER
sudo usermod -aG docker jenkins
sudo newgrp docker
sudo systemctl start docker
sudo systemctl start jenkins
sudo systemctl enable jenkins

sudo systemctl daemon-reload
