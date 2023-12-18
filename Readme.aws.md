# AWS Note
If installed on aws, open ec2 -> load balancer -> select the new lb -> copy dns A record
Create alias A record with Route53 for each of the domain records for the hubs stack; stream,cors,assets,tld.

### EFS Persistent Volumes
We need to set up the EFS driver in the EKS control panel under addons. Search for EFS, click enable and follow along with the wizard to create an EFS filesystem. 

Once the EFS drive has come online, we will need to allow traffic from EKS by updating our EFS inbound security group.

1. Open up the EFS filesystem you just created click on networking note down the security group in us-east-1.
2. Go to EC2, open up the security group tab and search for the EFS security group.
3. Add an inbound rule to allow EKS’s node workers access to EFS. Add an inbound rule for all traffic and the source should be the EKS node workers security group. 
    > This group can be found in the EKS control panel under networking (Additional Security Groups).

Copy and paste its filesystemId to values.yaml file under aws

>You may need to create the needed security policy between EKS and EFS.

Run these commands to set up the needed Trust Policy and Role needed to access EFS from EKS.

Setup your cluster name
```
export cluster_name={YOUR_CLUSTER_NAME}
export role_name=AmazonEKS_EFS_CSI_DriverRole
```
Create an IAM Service Account for EFS-CSI-controller
```
eksctl create iamserviceaccount \
   --name efs-csi-controller-sa \
   --namespace kube-system \
   --cluster $cluster_name \
   --role-name $role_name \
   --profile hubs-ce \
   --role-only \
   --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy \
   --approve
```
Get and update the trust policy for this new role.

```
TRUST_POLICY=$(aws iam get-role --role-name $role_name --query 'Role.AssumeRolePolicyDocument' | \
   sed -e 's/efs-csi-controller-sa/efs-csi-*/' -e 's/StringEquals/StringLike/')

aws iam update-assume-role-policy --role-name $role_name --policy-document "$TRUST_POLICY"
```

Now we need to grab the OIDC id from the below command:
```
aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text 
```

The output should look like this: https://oidc.eks.us-east-1.amazonaws.com/id/0CXXXXXXXXXXXXXXXXXXXXX

Copy the id after the slash and add it to the default-aws-efs-csi-driver-trust-policy.json
Now create and attach the role with awscli:
```
aws iam create-role \
 --role-name AmazonEKS_EFS_CSI_DriverRole \
 --assume-role-policy-document file://"default-aws-efs-csi-driver-trust-policy.json"

aws iam attach-role-policy \
 --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy \
 --role-name AmazonEKS_EFS_CSI_DriverRole
```

Once upgraded, Reticulum and Postgres (pgsql) will use a static Persistent Volume Claims and Persistent Volumes with an EFS backend to share their storage directories across pods. Restarting the reticulum pod(s) should no longer cause data loss but can't guarantee that. Use at your own risk!

Now go update your values.yaml to enable EFS (values.aws.yaml), and upgrade helm and you are good to go!