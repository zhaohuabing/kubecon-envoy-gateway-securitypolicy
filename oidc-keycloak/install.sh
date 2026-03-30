#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TMP_DIR=$(mktemp -d)
chmod 777 "${TMP_DIR}"
cd "${TMP_DIR}" || exit

# Install Envoy Gateway
helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.6.0 -n envoy-gateway-system --create-namespace

# Install the GatewayClass, Gateway, HTTPRoute and example app
kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v1.3.0/quickstart.yaml -n default

# Create an HTTPS port for the Gateway, as OIDC requires HTTPS
# Generate a self-signed certificate for the HTTPS port
openssl req -x509 -sha256 -nodes -days 365 -newkey rsa:2048 -subj '/O=example Inc./CN=example.com' -keyout example.com.key -out example.com.crt
openssl req -out www.example.com.csr -newkey rsa:2048 -nodes -keyout www.example.com.key -subj "/CN=www.example.com/O=example organization"
openssl x509 -req -days 365 -CA example.com.crt -CAkey example.com.key -set_serial 0 -in www.example.com.csr -out www.example.com.crt
kubectl create secret tls example-cert --key=www.example.com.key --cert=www.example.com.crt

# Patch the Gateway to add the HTTPS port
kubectl patch gateway eg --type=json --patch '
  - op: add
    path: /spec/listeners/-
    value:
      name: https
      protocol: HTTPS
      port: 443
      tls:
        mode: Terminate
        certificateRefs:
        - kind: Secret
          group: ""
          name: example-cert
  '

$SCRIPT_DIR/enable-backend.sh

kubectl apply -f $SCRIPT_DIR/keycloak.yaml
kubectl wait --for=condition=Initialized pod -l job-name=setup-keycloak
kubectl apply -f $SCRIPT_DIR/securitypolicy.yaml
