# OIDC Authentication with AWS Cognito

## Prerequisites

A Kubernetes cluster (e.g., kind, minikube, Docker Desktop, etc.) with kubectl configured to access it.

## Installation

Export the following environment variables:

```
export CLIENT_ID=6q0j7g8k7b6v2v7bxxxxxx           # Cognito App Client ID
export CLIENT_SECRET=j8r8d1a53akrp2qtcil14oio63v6di4t4bb91uxxxxxxxx  # Cognito App Client Secret
export ISSUER=https://cognito-idp.ap-southeast-2.amazonaws.com/ap-southeast-2_xxxxx # Cognito Issuer URL
```

Run `install.sh`, which will install Envoy Gateway and the demo application. This script will also create an HTTPRoute to route traffic to the application, and a SecurityPolicy to enforce OIDC authentication.

```
./install.sh
```

## Test OIDC Authentication

Put www.example.com in the /etc/hosts file in your test machine, so we can use this host name to access the gateway from a browser:

```
echo "127.0.0.1 www.example.com" | sudo tee -a /etc/hosts
```

Open a browser and navigate to `https://www.example.com/myapp`. You will be redirected to the Cognito login page. After successful authentication, you will be redirected back to the application.


## Authorization with JWT Claims

The Envoy Gateway can enforce authorization based on JWT claims. For example, you can restrict access to users with a specific email address or sub claim.

```yaml
  authorization:
    defaultAction: Deny
    rules:
    - action: Allow
      name: allow
      principal:
        jwt:
          provider: aws-cognito
          claims:
          - name: sub
            values: [89eed458-a031-70a2-f079-21ce7ccae5f0]
          - name: email
            values: [zhaohuabing@gmail.com]
```

Please refer to [oidc-jwt-auth-id-token.yaml](oidc-jwt-auth-id-token.yaml) for an example of how to enforce authorization based on JWT claims.
