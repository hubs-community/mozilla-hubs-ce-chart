# AWS Note
If installed on aws, open ec2 -> load balancer -> select the new lb -> copy dns A record
Create alias A record with Route53 for each of the domain records for the hubs stack; stream,cors,assets,tld.

### EFS Persistent Volumes
Setup the efs driver in the eks control panel under addons. Search for EFS and follow along with the wizard to create an EFS filesystem. 

Once the EFS drive has come online, we will need to allow traffic from EKS by updating our EFS inbound security group.

1. Open up the EFS filesystem you just created click on networking note down the security group in us-east-1.
2. Go to EC2, open up the security group tab and search for the EFS security group. 
3. Add an inbound rule to allow EKS' node workers access to EFS. Add an inbound rule for all traffic and the source as should be the EKS node workers security group. This group can be found in EKS control panel under networking (Additional Security Groups).

Copy and paste its filesystem ID to values.yaml file under aws

>You may need to create the needed security policy between EKS and EFS.
```
export cluster_name={YOUR_CLUSTER_NAME}
export role_name=AmazonEKS_EFS_CSI_DriverRole
eksctl create iamserviceaccount \
   --name efs-csi-controller-sa \
   --namespace kube-system \
   --cluster $cluster_name \
   --role-name $role_name \
   --role-only \
   --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy \
   --approve
TRUST_POLICY=$(aws iam get-role --role-name $role_name --query 'Role.AssumeRolePolicyDocument' | \
   sed -e 's/efs-csi-controller-sa/efs-csi-*/' -e 's/StringEquals/StringLike/')

aws iam update-assume-role-policy --role-name $role_name --policy-document "$TRUST_POLICY" 

aws eks describe-cluster --name Hubs-ce --query "cluster.identity.oidc.issuer" --output text 

# You need the identifier at the end of this output, add it to your `default-aws-efs-csi-driver-trust-policy.json`

aws iam create-role \
 --role-name AmazonEKS_EFS_CSI_DriverRole \
 --assume-role-policy-document file://"default-aws-efs-csi-driver-trust-policy.json" \

aws iam attach-role-policy \
 --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEFSCSIDriverPolicy \
 --role-name AmazonEKS_EFS_CSI_DriverRole 
```

Now upgrade the values.yaml to enable efs and your good to go! (values.aws.yaml) 

Reticulum and Postgres will use a Static PVC/PV with an EFS backend to share their storage directories across pods. Restarting ret should no longer cause data longer, but can't guaranty that. Use at your own risk!