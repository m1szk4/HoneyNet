.PHONY: help deploy up down restart logs test-isolation test-rules health-check backup clean stats

.DEFAULT_GOAL := help

help: ## Pokazuje dostępne komendy
	@echo "╔════════════════════════════════════════════════╗"
	@echo "║     IoT Honeynet - Dostępne Komendy           ║"
	@echo "╚════════════════════════════════════════════════╝"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""

# ==========================================
# DEPLOYMENT
# ==========================================

deploy: ## Pełne wdrożenie honeynetu (Ansible + Docker)
	@echo "🚀 Rozpoczynam deployment..."
	@cd ansible && ansible-playbook -i inventory/hosts.ini playbooks/00-hardening.yml
	@cd ansible && ansible-playbook -i inventory/hosts.ini playbooks/01-docker-install.yml
	@cd ansible && ansible-playbook -i inventory/hosts.ini playbooks/02-deploy-honeypots.yml
	@echo "✅ Deployment zakończony!"
	@$(MAKE) health-check

up: ## Uruchomienie wszystkich kontenerów
	@echo "🔄 Uruchamiam kontenery..."
	docker-compose up -d
	@sleep 15
	@echo "✅ Kontenery uruchomione!"
	@$(MAKE) health-check

down: ## Zatrzymanie wszystkich kontenerów
	@echo "⏸️  Zatrzymuję kontenery..."
	docker-compose down
	@echo "✅ Kontenery zatrzymane!"

restart: down up ## Restart wszystkich kontenerów

# ==========================================
# MONITORING
# ==========================================

logs: ## Wyświetlenie logów (tail -f)
	docker-compose logs -f --tail=100

logs-cowrie: ## Logi tylko z Cowrie
	docker-compose logs -f --tail=100 cowrie

logs-suricata: ## Logi tylko z Suricata
	docker-compose logs -f --tail=100 suricata

health-check: ## Sprawdzenie stanu systemu
	@echo "🏥 Health check..."
	@./scripts/monitoring/health_check.sh

stats: ## Generowanie statystyk datasetu
	@echo "📊 Generuję statystyki..."
	@python3 scripts/analysis/generate_stats.py

# ==========================================
# TESTING
# ==========================================

test-isolation: ## Test izolacji DMZ (KRYTYCZNY!)
	@echo "🔒 Testuję izolację sieciową..."
	@python3 tests/test_isolation.py

test-rules: ## Walidacja reguł IDS
	@echo "🎯 Testuję reguły Suricata..."
	@python3 tests/test_rules.py

test-all: test-isolation test-rules ## Wszystkie testy

# ==========================================
# MAINTENANCE
# ==========================================

backup: ## Backup konfiguracji i danych
	@echo "💾 Tworzę backup..."
	@./scripts/deployment/backup.sh
	@echo "✅ Backup utworzony w backups/"

clean: ## Czyszczenie logów starszych niż 30 dni
	@echo "🧹 Czyszczę stare logi..."
	@find data/ -name "*.log" -mtime +30 -delete 2>/dev/null || true
	@find data/ -name "*.pcap" -mtime +30 -delete 2>/dev/null || true
	@echo "✅ Czyszczenie zakończone"

update: ## Aktualizacja obrazów Docker
	@echo "⬆️  Aktualizuję obrazy..."
	docker-compose pull
	@$(MAKE) restart

# ==========================================
# DATA PROCESSING
# ==========================================

anonymize: ## Anonimizacja zebranych danych
	@echo "🔐 Anonimi zuję dane..."
	@python3 scripts/etl/anonymize.py
	@echo "✅ Anonimizacja zakończona"

export: ## Eksport danych do Parquet
	@echo "📤 Eksportuję dane..."
	@python3 scripts/etl/export_parquet.py
	@echo "✅ Dane wyeksportowane do data/exports/"

# ==========================================
# UTILITIES
# ==========================================

shell-cowrie: ## Shell do kontenera Cowrie
	docker exec -it cowrie /bin/bash

shell-clickhouse: ## Shell do ClickHouse
	docker exec -it clickhouse clickhouse-client

shell-grafana: ## Shell do Grafana
	docker exec -it grafana /bin/bash

ps: ## Lista uruchomionych kontenerów
	docker-compose ps

prune: ## Czyszczenie nieużywanych zasobów Docker
	@echo "🗑️  Czyszczę Docker..."
	docker system prune -f
	@echo "✅ Wyczyszczono"