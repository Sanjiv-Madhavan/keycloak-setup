# Define variables
KEYCLOAK_VERSION=26.1.0
POSTGRES_USER=testuser
POSTGRES_PASSWORD=testpassword
POSTGRES_DB=keycloak
REALM=provider-app-realm
KEYCLOAK_USER=sanshunoisky
KEYCLOAK_PASSWORD=sanshunoisky
CLIENT_ID=sample-app
CLIENT_SECRET=XZ5vt3cpbey5npWd7ncO5uyWxmYZQRMt
KEYCLOAK_HOST=keycloak.local
SAMPLE_APP_HOST=sample-app.local

.PHONY: all install-keycloak deploy-postgres generate-secrets deploy-keycloak create-realm create-user create-client create-ingress deploy-sample-app port-forward

all: install-keycloak deploy-postgres generate-secrets deploy-keycloak create-realm create-user create-client create-ingress deploy-sample-app port-forward

install-keycloak:
	kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/$(KEYCLOAK_VERSION)/kubernetes/keycloaks.k8s.keycloak.org-v1.yml
	kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/$(KEYCLOAK_VERSION)/kubernetes/keycloakrealmimports.k8s.keycloak.org-v1.yml
	kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-k8s-resources/$(KEYCLOAK_VERSION)/kubernetes/kubernetes.yml

deploy-postgres:
	kubectl apply -f postgres-ephemeral.yaml


generate-secrets:
	openssl req -subj '/CN=$(KEYCLOAK_HOST)/O=Test Keycloak./C=US' -newkey rsa:2048 -nodes -keyout key.pem -x509 -days 365 -out certificate.pem
	kubectl create secret tls example-tls-secret --cert certificate.pem --key key.pem
	kubectl create secret generic keycloak-db-secret \
	--from-literal=username=$(POSTGRES_USER) \
	--from-literal=password=$(POSTGRES_PASSWORD)

deploy-keycloak:
	kubectl apply -f keycloak-deploy.yaml

create-realm:
	curl -X POST "http://$(KEYCLOAK_HOST)/auth/admin/realms" \
	-H "Content-Type: application/json" \
	-H "Authorization: Bearer $$(./get-admin-token.sh)" \
	-d '{"realm": "$(REALM)", "enabled": true}'

create-user:
	curl -X POST "http://$(KEYCLOAK_HOST)auth/admin/realms/$(REALM)/users" \
	-H "Content-Type: application/json" \
	-H "Authorization: Bearer $$(./get-admin-token.sh)" \
	-d '{"username": "$(KEYCLOAK_USER)", "enabled": true, "credentials": [{"type": "password", "value": "$(KEYCLOAK_PASSWORD)", "temporary": false}]}'

create-client:
	curl -X POST "http://$(KEYCLOAK_HOST)/auth/admin/realms/$(REALM)/clients" \
	-H "Content-Type: application/json" \
	-H "Authorization: Bearer $$(./get-admin-token.sh)" \
	-d '{"clientId": "$(CLIENT_ID)", "secret": "$(CLIENT_SECRET)", "redirectUris": ["http://$(SAMPLE_APP_HOST)/*"], "publicClient": false, "serviceAccountsEnabled": true}'

create-ingress:
	kubectl apply -f kc-ingress.yaml

deploy-sample-app:
	kubectl apply -f sample-app.yaml
	kubectl apply -f sample-app-ingress.yaml

port-forward:
	kubectl port-forward svc/example-kc-service 8080:8080