# Welcome to the Mozilla Hubs Community Edition Chart!

To start you need a kubernetes cluster. 
Your worker nodes should have these ports open:
* TCP: 80, 443, 4443, 5349
* UDP: 35000 - 60000


## Setup SSL Certs
We need a few ssl certs and cert manager allows us to automate the request but also the renewal of the certs. lets install it!
### Install cert-manager 
See https://cert-manager.io/docs/installation/helm/ for more information

```
    kubectl create ns security
    helm repo add jetstack https://charts.jetstack.io
    helm repo update
    helm install cert-manager jetstack/cert-manager \
     --namespace security \
     --set ingressShim.defaultIssuerName=letsencrypt-issuer \
     --set ingressShim.defaultIssuerKind=ClusterIssuer \
     --set installCRDs=true
```

### Create cluster-issuer.yaml for Let's Encrypt
```
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-issuer
spec:
  acme:
    # You must replace this email address with your own.
    # Let's Encrypt will use this to contact you about expiring
    # certificates, and issues related to your account.
    email: '{YOUR_EMAIL_ADDRESS}'
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      # Secret resource that will be used to store the account's private key.
      name: letsencrypt-issuer
    # Add a single challenge solver, HTTP01 using nginx
    solvers:
      - http01:
          ingress:
            class: haproxy
```

Then run
```
kubectl apply -f 'PATH_TO/cluster-issuer.yaml'
```

## Deployment
### Install this helm chart

Copy and paste the configs.data output of render_helm.sh into the values.yaml file
```
./render_helm.sh {YOUR_HUBS_DOMAIN} {ADMIN_EMAIL_ADDRESS}
```
> You need the default cert to allow cert manager to request certs. 
> It will create a new file `config.yaml` 

Modify the values.yaml with your domain and email, replace whats inside the string.
```
global:
  domain: &HUBS_DOMAIN "{YOUR_HUBS_DOMAIN}"
  adminEmail: &ADMINEMAIL "{ADMIN_EMAIL_ADDRESS}"
```

To finish up the install run:
```
git clone git@github.com:hubs-community/mozilla-hubs-ce-chart.git
cd mozilla-hubs-ce-chart

kubectl create ns {YOUR_NAMESPACE}

helm install moz . --namespace={YOUR_NAMESPACE} --debug --dry-run
```
> remove --dry-run to fully install

> [AWS Deployment Notes](./Readme.aws.md)

## Update this helm chart
Update what you need to, ie, values.yaml or template files. Remove --dry-run to upgrade
```
helm upgrade moz . --namespace={YOUR_NAMESPACE} --debug --dry-run
```

## Delete this helm chart
This will remove everything installed by this chart. Remove --dry-run to delete
```
helm delete moz --namespace={YOUR_NAMESPACE} --dry-run
```


