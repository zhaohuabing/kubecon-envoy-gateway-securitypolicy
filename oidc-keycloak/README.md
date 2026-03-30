# OIDC Authentication with AWS Cognito

## Prerequisites

A Kubernetes cluster (e.g., kind, minikube, Docker Desktop, etc.) with kubectl configured to access it.

## Installation

Run `install.sh`, which will install Envoy Gateway and the demo application.

```
./install.sh
```

## Test OIDC Authentication

Port-forward the Envoy Gateway service to your local machine so you can access it via HTTPS:

```
export ENVOY_SERVICE=$(kubectl get svc -n envoy-gateway-system --selector=gateway.envoyproxy.io/owning-gateway-namespace=default,gateway.envoyproxy.io/owning-gateway-name=eg -o jsonpath='{.items[0].metadata.name}')
export KUBECONFIG=~/.kube/config
sudo env ENVOY_SERVICE=${ENVOY_SERVICE} KUBECONFIG=$KUBECONFIG kubectl -n envoy-gateway-system port-forward service/${ENVOY_SERVICE} 443:443 --address 0.0.0.0 &
```

If you have not already done so, put www.example.com and in the /etc/hosts file in your test machine, so we can use this host name to access the gateway from a browser:

```
echo "127.0.0.1 www.example.com" | sudo tee -a /etc/hosts
```

You also need to put keycloak in the /etc/hosts file, so we can use this host name to access Keycloak from a browser after the user is redirected to the Keycloak login page:

```
echo "127.0.0.1 keycloak" | sudo tee -a /etc/hosts
```

Open a browser and navigate to `https://www.example.com/foo`. You will be redirected to the Keycloak login page. After successful authentication, you will be redirected back to the application.


Note: The `Backend` resource in this demo is not necessary because the Keycloak server is deployed in the same cluster and can be accessed through Kubernetes Service. In a real-world scenario, you would need to create a `Backend` resource to route traffic to the Keycloak server if it is deployed outside the cluster.
