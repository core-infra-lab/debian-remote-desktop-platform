# ================================
# POINT D'ENTREE
# ================================
#
# Les deux modes d'installation sont separes dans deux Makefiles:
# - Makefile.full-docker : Guacamole + VNC entierement en Docker
# - Makefile.host        : Guacamole en Docker + VNC sur l'hote/VM

.DEFAULT_GOAL := help

FULL_DOCKER_MAKEFILE := Makefile.full-docker
HOST_MAKEFILE := Makefile.host

help:
	@echo ""
	@echo "===== Makefiles separes Guacamole + VNC ====="
	@echo ""
	@echo "Mode full Docker:"
	@echo "  make -f $(FULL_DOCKER_MAKEFILE) help"
	@echo "  make -f $(FULL_DOCKER_MAKEFILE) install"
	@echo "  make -f $(FULL_DOCKER_MAKEFILE) up"
	@echo "  make -f $(FULL_DOCKER_MAKEFILE) add-connection"
	@echo ""
	@echo "Mode host/VM:"
	@echo "  make -f $(HOST_MAKEFILE) help"
	@echo "  make -f $(HOST_MAKEFILE) install"
	@echo "  make -f $(HOST_MAKEFILE) up"
	@echo "  make -f $(HOST_MAKEFILE) add-connection"
	@echo ""
	@echo "Compatibilite avec les anciennes commandes:"
	@echo "  make up                  -> full Docker"
	@echo "  make up-host             -> host/VM"
	@echo "  make add-connection-docker -> full Docker"
	@echo "  make add-connection-host -> host/VM"
	@echo "============================================="
	@echo ""

full-docker:
	@$(MAKE) -f $(FULL_DOCKER_MAKEFILE) help

host:
	@$(MAKE) -f $(HOST_MAKEFILE) help

# Compatibilite: les anciennes cibles deleguent vers le Makefile explicite.
install-guacamole install up up-full-docker re down restart status connect env update-env run clean-docker add-connection add-connection-docker:
	@$(MAKE) -f $(FULL_DOCKER_MAKEFILE) $@

up-host setup-vnc-host restart-vnc-host status-vnc-host ssh set-guac-host add-connection-host:
	@$(MAKE) -f $(HOST_MAKEFILE) $@

.PHONY: help full-docker host install-guacamole install up up-full-docker re down restart status connect env update-env run clean-docker add-connection add-connection-docker up-host setup-vnc-host restart-vnc-host status-vnc-host ssh set-guac-host add-connection-host
