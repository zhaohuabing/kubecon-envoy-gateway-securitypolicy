# kubecon-envoy-gateway-securitypolicy

This repository contains the code for the demo presented at KubeCon EU 2025. The demo showcases how to use the Envoy Gateway with SecurityPolicy to secure an application with OIDC authentication.

How it works:

1. The user sends a request to the Envoy Gateway without an ID Token.
1. The user is redirected to the Cognito login page to authenticate.
1. After successful authentication, the user is redirected to the Envoy Gateway with an Authorization Code.
1. Envoy exchanges the Authorization Code for an Access Token and ID Token.
1. The user request is proxied to the application.
