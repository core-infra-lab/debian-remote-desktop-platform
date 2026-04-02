# ================================
# 🧩 CONFIGURATION AUTOMATIQUE
# ================================

# Charger le fichier .env s’il existe
ifneq (,$(wildcard .env))
	include .env
	export $(shell sed 's/=.*//' .env)
endif

ENV_FILE = .env
# Détection automatique d’IP si non définie dans .env
HOST_IP ?= $(shell ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n 1)

# Valeurs par défaut (si absentes du .env)
VM_IP ?= $(HOST_IP)
VNC_PORT ?= 5901
GUAC_PORT ?= 8081
SSH_PORT ?= 4242
VM_USER = radandri
CONNECTION_NAME ?= New VNC Connection
CONNECTION_HOST ?= vnc-desktop
CONNECTION_PORT ?= 5901
CONNECTION_PASSWORD ?= $(VNC_PASSWORD)
CONNECTION_PROTOCOL ?= vnc
CONNECTION_CLIPBOARD_ENCODING ?= UTF-8
CONNECTION_COLOR_DEPTH ?= 24
GUAC_ADMIN_ENTITY_ID ?= 1

# ================================
# ⚙️ COMMANDES PRINCIPALES
# ================================

help:
	@echo ""
	@echo "===== 🧭 Makefile Guacamole + VNC Manager ====="
	@echo "Available commands:"
	@echo "  make up           -> Démarre les conteneurs Guacamole"
	@echo "  make down         -> Stoppe et supprime les conteneurs"
	@echo "  make restart      -> Redémarre Guacamole proprement"
	@echo "  make status       -> Liste les conteneurs actifs"
	@echo "  make connect      -> Affiche l’URL Guacamole et info SSH"
	@echo "  make ssh          -> Se connecte à la VM en SSH"
	@echo "  make add-connection -> Crée ou met à jour une connexion Guacamole VNC"
	@echo "  make env          -> Affiche les variables d’environnement chargées"
	@echo "================================================"
	@echo ""

# ================================
# 🚀 DOCKER / GUACAMOLE
# ================================

install-guacamole:
	bash prepare.sh
	make up

up:
	@echo "📦 Démarrage des conteneurs Guacamole..."
	docker compose up -d
	@echo ""
	@echo "🌐 Accès Guacamole : http://$(HOST_IP):$(GUAC_PORT)/guacamole"
	@echo "🧩 Utilisateur par défaut : guacadmin / guacadmin"
	@echo ""

down:
	@echo "🛑 Arrêt et suppression des conteneurs..."
	docker compose down

restart: down up

status:
	@echo "📋 Liste des conteneurs actifs :"
	docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Ports}}\t{{.Status}}"

# ================================
# 🔐 CONNEXION VM / VNC
# ================================

ssh:
	@echo "🔑 Connexion SSH à la VM $(VM_IP) sur le port $(SSH_PORT)..."
	@ssh $(VM_USER)@$(VM_IP) -p $(SSH_PORT)

connect:
	@echo ""
	@echo "================== 🌍 INFORMATIONS =================="
	@echo "Guacamole :   http://$(HOST_IP):$(GUAC_PORT)/guacamole"
	@echo "VM SSH :      ssh $(VM_USER)@$(VM_IP) -p $(SSH_PORT)"
	@echo "VNC (docker): $(HOST_IP):$(VNC_PORT)"
	@echo "====================================================="
	@echo ""

# ================================
# 🧰 OUTILS / DEBUG
# ================================

env:
	@echo "===== 🌱 Variables d'environnement chargées ====="
	@echo "HOST_IP  = $(HOST_IP)"
	@echo "VM_IP    = $(VM_IP)"
	@echo "VNC_PORT = $(VNC_PORT)"
	@echo "GUAC_PORT= $(GUAC_PORT)"
	@echo "SSH_PORT = $(SSH_PORT)"
	@echo "==============================================="

update-env:
	@echo "🔄 Mise à jour du fichier $(ENV_FILE) avec HOST_IP=$(HOST_IP)"
	@if [ -f $(ENV_FILE) ]; then \
		sed -i "s/^HOST_IP=.*/HOST_IP=$(HOST_IP)/" $(ENV_FILE) || echo "HOST_IP=$(HOST_IP)" >> $(ENV_FILE); \
	else \
		echo "HOST_IP=$(HOST_IP)" > $(ENV_FILE); \
	fi

# Mets à jour .env puis lance tes conteneurs
run: update-env
	docker compose --env-file $(ENV_FILE) up -d

clean-docker:
	@echo "🧹 Suppression des conteneurs, volumes et images orphelins..."
	bash reset.sh
	docker compose down -v --remove-orphans
	docker system prune -f
	docker stop $(docker ps -aq) 2>/dev/null
	docker rm -f $(docker ps -aq) 2>/dev/null

# Update Guacamole DB to use host.docker.internal for hostname
set-guac-host:
	@echo "Setting guacamole connection hostname to host.docker.internal in DB..."
	@docker exec -i postgres_guacamole_compose psql -U guacamole_user -d guacamole_db -c "UPDATE guacamole_connection_parameter SET parameter_value='host.docker.internal' WHERE parameter_name='hostname' AND parameter_value='127.0.0.1';" || true
	@echo "Done. Restart guacd/guacamole if needed: make restart"

add-connection:
	@if [ -z "$(strip $(CONNECTION_NAME))" ] || [ -z "$(strip $(CONNECTION_HOST))" ] || [ -z "$(strip $(CONNECTION_PORT))" ] || [ -z "$(strip $(CONNECTION_PASSWORD))" ]; then echo "CONNECTION_NAME, CONNECTION_HOST, CONNECTION_PORT and CONNECTION_PASSWORD must be set"; exit 1; fi
	@echo "Creating/updating Guacamole connection: $(CONNECTION_NAME)"
	@CONN_NAME='$(CONNECTION_NAME)'; \
	CONN_HOST='$(CONNECTION_HOST)'; \
	CONN_PORT='$(CONNECTION_PORT)'; \
	CONN_PASSWORD='$(CONNECTION_PASSWORD)'; \
	CONN_PROTOCOL='$(CONNECTION_PROTOCOL)'; \
	CONN_CLIPBOARD='$(CONNECTION_CLIPBOARD_ENCODING)'; \
	CONN_DEPTH='$(CONNECTION_COLOR_DEPTH)'; \
	docker exec -i postgres_guacamole_compose psql -U guacamole_user -d guacamole_db -c \
	"WITH conn AS (INSERT INTO guacamole_connection (connection_name, protocol, parent_id) VALUES ('$$CONN_NAME', '$$CONN_PROTOCOL', NULL) ON CONFLICT (connection_name, parent_id) DO UPDATE SET protocol = EXCLUDED.protocol RETURNING connection_id) INSERT INTO guacamole_connection_parameter (connection_id, parameter_name, parameter_value) SELECT conn.connection_id, params.parameter_name, params.parameter_value FROM conn CROSS JOIN (VALUES ('hostname', '$$CONN_HOST'), ('port', '$$CONN_PORT'), ('password', '$$CONN_PASSWORD'), ('clipboard-encoding', '$$CONN_CLIPBOARD'), ('color-depth', '$$CONN_DEPTH')) AS params(parameter_name, parameter_value) ON CONFLICT (connection_id, parameter_name) DO UPDATE SET parameter_value = EXCLUDED.parameter_value;"
	@CONN_NAME='$(CONNECTION_NAME)'; \
	docker exec -i postgres_guacamole_compose psql -U guacamole_user -d guacamole_db -c \
	"INSERT INTO guacamole_connection_permission (entity_id, connection_id, permission) SELECT $(GUAC_ADMIN_ENTITY_ID), c.connection_id, perm::guacamole_object_permission_type FROM guacamole_connection c CROSS JOIN (VALUES ('READ'),('UPDATE'),('DELETE'),('ADMINISTER')) AS p(perm) WHERE c.connection_name = '$$CONN_NAME' ON CONFLICT DO NOTHING;"
	@echo "Done. Open Guacamole, refresh the page (Ctrl+F5), then select '$(CONNECTION_NAME)'."

