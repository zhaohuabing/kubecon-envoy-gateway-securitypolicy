#!/bin/bash

TMP_DIR=$(mktemp -d)
chmod 777 "${TMP_DIR}"
cd "${TMP_DIR}" || exit

# Check if both ENV_VAR1 and ENV_VAR2 are set
if [ -z "${CLIENT_ID}" ] || [ -z "${CLIENT_SECRET}" ] || [ -z "${ISSUER}" ]; then
  echo "CLIENT_ID, CLIENT_SECRET and ISSUER must be set as environment variables to run this script"
  exit 1
fi

# Install Envoy Gateway
helm install eg oci://docker.io/envoyproxy/gateway-helm --version v1.3.0 -n envoy-gateway-system --create-namespace

# Install the GatewayClass, Gateway, HTTPRoute and example app
kubectl apply -f https://github.com/envoyproxy/gateway/releases/download/v1.3.0/quickstart.yaml -n default

# Create an HTTPRoute
cat <<EOF | kubectl apply -f -
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: myapp
spec:
  parentRefs:
  - name: eg
  hostnames: ["www.example.com"]
  rules:
  - matches:
    - path:
        type: PathPrefix
        value: /myapp
    backendRefs:
    - name: backend
      port: 3000
EOF


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

# Create a secret with the client secret
kubectl create secret generic my-app-client-secret --from-literal=client-secret=${CLIENT_SECRET}

# Create a SecurityPolicy targeting the HTTPRoute
cat <<EOF | kubectl apply -f -
apiVersion: gateway.envoyproxy.io/v1alpha1
kind: SecurityPolicy
metadata:
  name: oidc-example
spec:
  targetRefs:
    - group: gateway.networking.k8s.io
      kind: HTTPRoute
      name: myapp
  oidc:
    provider:
      issuer: "${ISSUER}"
    clientID: "${CLIENT_ID}"
    clientSecret:
      name: "my-app-client-secret"
    redirectURL: "https://www.example.com/myapp/oauth2/callback"
    logoutPath: "/myapp/logout"
EOF

kubectl wait --for=condition=Ready pod -l gateway.envoyproxy.io/owning-gateway-name=eg -n envoy-gateway-system

export ENVOY_SERVICE=$(kubectl get svc -n envoy-gateway-system --selector=gateway.envoyproxy.io/owning-gateway-namespace=default,gateway.envoyproxy.io/owning-gateway-name=eg -o jsonpath='{.items[0].metadata.name}')
export KUBECONFIG=~/.kube/config
sudo env ENVOY_SERVICE=${ENVOY_SERVICE} KUBECONFIG=$KUBECONFIG kubectl -n envoy-gateway-system port-forward service/${ENVOY_SERVICE} 443:443 --address 0.0.0.0 &

# You should see a 302 redirect to the OIDC provider
ATTEMPTS=10
DELAY=1
for ((i=1; i<=ATTEMPTS; i++)); do
  RESPONSE_CODE=$(curl -o /dev/null -s -k -w "%{http_code}\n" "https://www.example.com/myapp/" --connect-to "www.example.com:443:127.0.0.1:443")
  echo "Attempt $i: Response Code = $RESPONSE_CODE"

  if [ "$RESPONSE_CODE" -eq 302 ]; then
    echo "Success! Received 302 response."
    exit 0
  fi

  if [ $i -lt $ATTEMPTS ]; then
    sleep $DELAY
  fi
done
