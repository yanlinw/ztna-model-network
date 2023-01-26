# Splashtop ZTNA POC Provisioning Tool

This open-source project offers a tool for creating an isolated cloud-based network POC environment for IT admins or DevOps engineers to test zero-trust network access solutions. 

## Architecture 

This tool, built with Hashicorp Terraform, sets up a single AWS EC2 medium instance, a Kubernetes cluster (using kind), and various network services and k8s pods on top of the Kubernetes cluster:

| Service  |  Protocol    | Network Address in K8s               | Login |
|----------|--------------|-------------------------------|-------|
|Remote Desktop| RDP| ztenv-myrdp.default.svc.cluster.local:3389|ubuntu/ubuntu|
|VNC| VNC| ztenv-myvnc.default.svc.cluster.local:5900|headless|
|SSH| SSH| ztenv-myssh.default.svc.cluster.local:22|root/root|
|Samba File Share| SMB| ztenv-mysmb.default.svc.cluster.local:10445|ztsmb/password|
|NFS File Share| NFSv3| ztenv-mynfs.default.svc.cluster.local:2049||
|Video Streaming| RTSP| ztenv-myrtsp.default.svc.cluster.local:8554||

Once the private network is provisioned with the services mentioned above, it also deploys:

* A ZTNA connector as a Linux service to link the AWS EC2 instance with the Splashtop ZTNA solution.
* A ZTNA connector as a helm chart to connect all network services running on k8s to the ZTNA solution."

## Deployment 
To deploy this POC project, you will first need to install Hashicorp Terraform. Also, AWS Command Line Interface (CLI) must be set up and configured on the local machine before the deployment. To set up the AWS CLI, you will need to have an AWS account and install the AWS CLI software on your local machine. Once the CLI is installed, you can configure it with your AWS credentials and begin using it to interact with AWS services, detail steps are [here](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html) . 

Follow these steps:

1. Create a connector within the Splashtop portal. Log in to the portal, go to Deployment/Connector, click "Add Connector", choose "Service Mode", fill in the connector meta data, click next, choose "Helm", there is section shows the helm command to install the connector, copy the value after "-n" parameter as the name of the connector and copy the "token" value as the connector access token. Keep the connector deployment page open.
2. Open a terminal, use "git pull" to download the latest code for this project, then run the following commands:


```bash
% cd terraform
% terraform init
% terraform apply
```
The tool will ask for input to deploy the POC. You will need to provide:

- var.deployment_name: The name for your deployment, this will also be used as the tag for your AWS EC2 instance.
- var.kind_connector_name: The connector name you copied from the previous step.
- var.kind_connector_token: The token you copied from the previous step, without the double quotes.


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

1. After Terraform has successfully provisioned the POC, the connector deployment page in the Splashtop portal will indicate that the connector is connected.

2. Create a test application. In the portal, navigate to Applications/Applications, click "Create An Application", select the RDP type, and enter "ztenv-myrdp.default.svc.cluster.local" as the "Host" and "3389" as the "Port". Save the application.

3. Test the browser-based RDP access. In the portal, launch the newly created RDP application by clicking the icon in Applications/Applications.

## Teardown the POC environments

To remove all AWS resources that you have created, you will need to run cli:

```bash
% terraform destroy
```









