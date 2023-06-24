#!/bin/bash
LOG_FILE=/var/log/userdata.log
echo "$(date) start of user data" >> $LOG_FILE

main_function() {
    yum install -y yum-utils
    yum-config-manager \
        --add-repo \
        https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y docker-ce docker-ce-cli containerd.io python3 git
    systemctl enable docker
    service docker start
    #waiting for docker daemon to start 
    while ! service docker status; do sleep 1; done
    curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    yum install epel-release -y
    yum install snapd -y
    ln -s /var/lib/snapd/snap /snap
    systemctl enable --now snapd.socket
    sleep 20
    snap install core
    snap install --classic certbot
    ln -s /snap/bin/certbot /usr/bin/certbot
    yum install nginx -y
    snap install helm --classic
    ln -s /var/lib/snapd/snap/bin/helm /usr/bin/helm

    curl -O https://s3.us-west-2.amazonaws.com/amazon-eks/1.24.7/2022-10-31/bin/linux/amd64/kubectl
    install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    ln -s /usr/local/bin/kubectl /usr/bin/kubectl
    kubectl version --client

    #install kind
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64
    chmod +x ./kind
    mv ./kind /usr/local/bin/kind
    ln -s /usr/local/bin/kind /usr/bin/kind

    #create kind config
    mkdir /home/centos/shared
    chmod -R 777 /home/centos/shared
    echo "kind: Cluster" > kind_ztna.yaml
    echo "apiVersion: kind.x-k8s.io/v1alpha4" >> kind_ztna.yaml
    echo "networking:" >> kind_ztna.yaml
    echo "  apiServerPort: 9443" >> kind_ztna.yaml
    echo "  apiServerAddress: 0.0.0.0" >> kind_ztna.yaml
    echo "nodes:" >> kind_ztna.yaml
    echo "- role: control-plane" >> kind_ztna.yaml
    echo "  extraMounts:" >> kind_ztna.yaml
    echo "  - hostPath: /home/centos/shared" >> kind_ztna.yaml
    echo "    containerPath: /shared" >> kind_ztna.yaml


    #create kind cluster
    kind create cluster --name ztna-demo --config kind_ztna.yaml
    kubectl cluster-info --context kind-ztna-demo
    mkdir -p /root/.kube/ && kind get kubeconfig --name ztna-demo > /root/.kube/config
    chmod go-r /root/.kube/config

    #helm repo add ztenv http://splashlock-assets.splashshield.ai/helm-chart/ztenvchart
    helm install ztenv /home/centos/ztenvchart --wait
    kubectl get pods -A -o wide
    
    #init vm connector

    export ZTW_CONNECTOR_TOKEN=${vm_connector_token}
    export ZTW_CONNECTOR=${vm_connector_name}
    if [ -n "$ZTW_CONNECTOR" ]; then
        if [ -n "$ZTW_CONNECTOR_TOKEN" ]; then
            curl -fsSL "https://ssw-artifacts.s3.us-west-2.amazonaws.com/connector/prod/setup.sh"  | sudo bash -s $ZTW_CONNECTOR 
            sudo $ZTW_CONNECTOR -install -configPath /etc/$ZTW_CONNECTOR -conf $ZTW_CONNECTOR_TOKEN
            sudo systemctl start $ZTW_CONNECTOR
        fi
    fi

    #init kind connector
    export K8S_CONNECTOR_TOKEN=${kind_connector_token}
    export K8S_CONNECTOR=${kind_connector_name} 
    if [ -n "$K8S_CONNECTOR" ]; then
        if [ -n "K8S_CONNECTOR_TOKEN" ]; then
            helm repo add ssw-connector https://ssw-artifacts.s3.us-west-2.amazonaws.com/helm-chart/ssw-connector --force-update 
            helm upgrade --install -n ssw-connector $K8S_CONNECTOR  ssw-connector/ssw-connector --set token=$K8S_CONNECTOR_TOKEN --create-namespace --wait
        fi
    fi    

}
main_function 2>&1 | tee -a $LOG_FILE
echo "WHO AM I: $(whoami) | CWD: $(pwd)"
echo "$(date) end of user data" >> $LOG_FILE