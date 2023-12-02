# Welcome to the Mozilla Hubs Community Edition Chart!

To start you need a kubernetes cluster with correct permissions setup.

## 1. Install cert-manager 
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
            class: nginx
```

### Then run
```
kubectl apply -f 'PATH_TO/cluster-issuer.yaml'
```

## 2. Install this helm chart

Copy and paste the configs.data output of render_helm.sh into the values.yaml file deleting .
```
./render_helm.sh {YOUR_HUBS_DOMAIN} {ADMIN_EMAIL_ADDRESS}
```
> you shouldn't need the default cert anymore but if you do the output is at the bottom of render_helm.sh output. You may turn on the default cert and replace the data if needed, your mileage may vary. 

Modify the values.yaml with your domain and email, replace whats inside the string.

```
global:
  domain: &HUBS_DOMAIN "{YOUR_HUBS_DOMAIN}"
  adminEmail: &ADMINEMAIL "{ADMIN_EMAIL_ADDRESS}"
```

Then to finish up the install run

```
    git clone git@github.com:hubs-community/mozilla-hubs-ce-chart.git
    cd mozilla-hubs-ce-chart
    kubectl create ns {YOUR_NAMESPACE}
    
    # update the values.yaml to have your domain and email + need keys
    # remove --dry-run to fully install
    
    helm install moz . --namespace={YOUR_NAMESPACE} --debug --dry-run
```

## Update this helm chart

```
    # update what you need to, ie, values.yaml or template files
    # remove --dry-run to upgrade

    helm upgrade moz . --namespace={YOUR_NAMESPACE} --debug --dry-run
```

## Delete this helm chart

```
    # This will remove everything installed by this chart
    # remove --dry-run to delete

    helm delete moz --namespace={YOUR_NAMESPACE} --dry-run
```

