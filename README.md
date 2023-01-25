# Splashtop ZTNA Provision Tool

This project provides a tool that can provision an isolated cloud-based network POC environment for IT admin or devops engineer to evaluate zero trust network access solutions. 

## Architecture 

This tool is implemented by using Hashicorp Terraform. It provisions AWS EC2 medium instance, a Kubernetes (kind cluster) on top of the EC2 instance, and multiple network services as well as k8s pods on top of Kubernetes cluster:

| Service  |  Protocol    | Network Address in K8s               | Login |
|----------|--------------|-------------------------------|-------|
|Remote Desktop| RDP| ztenv-myrdp.default.svc.cluster.local:3389|ubuntu/ubuntu|
|VNC| VNC| ztenv-myvnc.default.svc.cluster.local:5900|headless|
|SSH| SSH| ztenv-myssh.default.svc.cluster.local:22|root/root|
|Samba File Share| SMB| ztenv-mysmb.default.svc.cluster.local:10445|ztsmb/password|
|NFS File Share| NFSv3| ztenv-mynfs.default.svc.cluster.local:2049||
|Video Streaming| RTSP| ztenv-myrtsp.default.svc.cluster.local:8554||

After provision the private network with the above services, it also deploys: 
* A ZTNA connector as Linux service to connect the AWS EC2 instance to Splashtop ZTNA solution
* A ZTNA connector as helm chart to connect all network services running on k8s to ZTNA solution

## Deployment 
Before deploy, you will need to install Hashicorp Terraform.

Here are the steps wrt how to deploy this POC project:

1. Create connector within Splashtop portal.  Logging in the portal, goto Deployment/Connector, click "Add Connector",  choose "Service Mode", fill in the connector meta data, click next, choose "Helm", there is section shows the helm command to install the connector, copy the value after "-n" parameter as the name of the connector and copy the "token" value as the connector access token. Leave the connector deployment page open.
2. Run the terminal app, use "git pull" to pull the lastest code of this project, then run following command
```bash
% cd terraform
% terraform init
% terraform apply
```
The tool will prompt for the input in order to deploy the POC. You will need to provide :
- var.deployment_name, give a name to your deployment, the name will also be the tag of your AWS EC2 instance
- var.kind_connector_name, the connector name you copy from the above step
- var.kind_connector_token, the token you copied from above step (remove the double quotes)


```bash
% terraform apply

var.deployment_name
  ZTW deployment name, which is used for AWS label 

  Enter a value: ztna_poc

var.kind_connector_name
  ZTW connector name for the kind cluster

  Enter a value: 

var.kind_connector_token
  ZTW connector token for the kind cluster

  Enter a value: 

var.vm_connector_name
  ZTW connector name for the VM. This is optional for demo.

  Enter a value: 

var.vm_connector_token
  ZTW connector token for the VM. This is optional for demo.

  Enter a value: 
```
## Create ZTNA Application

1. After terraform provision the POC successfully, the connector deployment page in the splashtop portal will show the connector is connected.

2. Create a testing app. In the portal, go to Applications/Applications, click "Create An Application", choose the RDP type and fill in "Host" as "ztenv-myrdp.default.svc.cluster.local" and "Port" as "3389". Save the application.
3. Test the browser based RDP access. In the portal, launch the application by clicking the icon of the newly created RDP application in Applications/Applications.











