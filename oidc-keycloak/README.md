# OIDC Authentication with AWS Cognito

## Prerequisites

A Kubernetes cluster (e.g., kind, minikube, Docker Desktop, etc.) with kubectl configured to access it.

## Installation

Run `install.sh`, which will install a local kind cluster, Envoy Gateway, and the demo application.
Note: If you already did the installation in the oidc-cognito tutorial, you can skip this step.

```
./install.sh
```

Note: Backend API is not enabled by default when installing the Envoy Gateway. We need to enable it by running the following command:

```
./enable-backend.sh
```

Install Keycloak:

```
kubectl apply -f keycloak.yaml
```

Wait for Keycloak to be ready:

```
kubectl wait --for=condition=Initialized pod -l job-name=setup-keycloak
```

Create an HTTPRoute, Backend, BackendTLSPolicy, and SecurityPolicy to route traffic to the application and enforce OIDC authentication:

```
kubectl apply -f securitypolicy.yaml
```

## Test OIDC Authentication

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
