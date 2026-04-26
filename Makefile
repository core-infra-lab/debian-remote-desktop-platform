# ================================
# POINT D'ENTREE
# ================================
#
# Les deux modes d'installation sont separes dans deux Makefiles:
# - Makefile.full-docker : Guacamole + VNC entierement en Docker
# - Makefile.host        : Guacamole en Docker + VNC sur l'hote/VM

FULL_DOCKER_MAKEFILE := Makefile.full-docker
HOST_MAKEFILE := Makefile.host
POST_INSTALL_USER ?= radandri

install-host:
	if [ ! -f .env ]; then \
		cp .env.host.example .env; \
	fi
	@$(MAKE) -f $(HOST_MAKEFILE) prepare
	@$(MAKE) -f $(HOST_MAKEFILE) up
	@$(MAKE) -f $(HOST_MAKEFILE) setup-vnc-host
	@$(MAKE) -f $(HOST_MAKEFILE) restart-vnc-host
	@$(MAKE) -f $(HOST_MAKEFILE) add-connection
	@$(MAKE) post-install

install-full-docker:
	if [ ! -f .env ]; then \
		cp .env.full-docker.example .env; \
	fi
	@$(MAKE) -f $(FULL_DOCKER_MAKEFILE) prepare
	@$(MAKE) -f $(FULL_DOCKER_MAKEFILE) up
	@$(MAKE) -f $(FULL_DOCKER_MAKEFILE) add-connection
	@$(MAKE) post-install

post-install:
	./post_install.sh $(POST_INSTALL_USER)

.PHONY: install-host install-full-docker post-install
