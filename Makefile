# ================================
# POINT D'ENTREE
# ================================
#
# Les deux modes d'installation sont separes dans deux Makefiles:
# - Makefile.full-docker : Guacamole + VNC entierement en Docker
# - Makefile.host        : Guacamole en Docker + VNC sur l'hote/VM

ROOT_DIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
FULL_DOCKER_MAKEFILE := Makefile.full-docker
HOST_MAKEFILE := Makefile.host
POST_INSTALL_USER ?= radandri

install-host:
	if [ ! -f "$(ROOT_DIR)/.env" ]; then \
		cp "$(ROOT_DIR)/.env.host.example" "$(ROOT_DIR)/.env"; \
	fi
	@$(MAKE) -C "$(ROOT_DIR)" -f $(HOST_MAKEFILE) prepare
	@$(MAKE) -C "$(ROOT_DIR)" -f $(HOST_MAKEFILE) up
	@$(MAKE) -C "$(ROOT_DIR)" -f $(HOST_MAKEFILE) setup-vnc-host
	@$(MAKE) -C "$(ROOT_DIR)" -f $(HOST_MAKEFILE) restart-vnc-host
	@$(MAKE) -C "$(ROOT_DIR)" -f $(HOST_MAKEFILE) add-connection
	@if ! grep -q "^alias vnc=" ~/.zshrc; then \
		echo "alias vnc='make -f $(ROOT_DIR)/Makefile restart-vnc'" >> ~/.zshrc
	fi
	@if ! grep -q "^alias vnc=" ~/.bashrc; then \
		echo "alias vnc='make -f $(ROOT_DIR)/Makefile restart-vnc'" >> ~/.bashrc
	fi
	@if ! grep -q "^alias install-guac=" ~/.zshrc; then \
		echo "alias install-guac='make -f $(ROOT_DIR)/Makefile install-host'" >> ~/.zshrc
	fi
	@if ! grep -q "^alias install-guac=" ~/.bashrc; then \
		echo "alias install-guac='make -f $(ROOT_DIR)/Makefile install-host'" >> ~/.bashrc
	fi

restart-vnc:
	@$(MAKE) -C "$(ROOT_DIR)" -f $(HOST_MAKEFILE) restart-vnc-host

install-full-docker:
	if [ ! -f "$(ROOT_DIR)/.env" ]; then \
		cp "$(ROOT_DIR)/.env.full-docker.example" "$(ROOT_DIR)/.env"; \
	fi
	@$(MAKE) -C "$(ROOT_DIR)" -f $(FULL_DOCKER_MAKEFILE) prepare
	@$(MAKE) -C "$(ROOT_DIR)" -f $(FULL_DOCKER_MAKEFILE) up
	@$(MAKE) -C "$(ROOT_DIR)" -f $(FULL_DOCKER_MAKEFILE) add-connection
	@$(MAKE) -C "$(ROOT_DIR)" post-install

.PHONY: install-host restart-vnc install-full-docker post-install
