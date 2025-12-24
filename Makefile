# ===================================
# MAKEFILE UNIVERSAL - Flask Projects
# ===================================
# Comandos úteis para qualquer projeto Flask
# ===================================

.PHONY: help install run test clean docker-build docker-up docker-down docker-logs backup

# Python
PYTHON := python3
PIP := $(PYTHON) -m pip
VENV := venv

# Cores para output
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

# ===================================
# HELP - Mostra comandos disponíveis
# ===================================
help:
	@echo ""
	@echo "$(BLUE)╔════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║        COMANDOS DISPONÍVEIS - Make             ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)📦 Instalação e Setup:$(NC)"
	@echo "  make install          - Instala dependências"
	@echo "  make setup            - Setup completo (venv + install + .env)"
	@echo "  make venv             - Cria ambiente virtual"
	@echo ""
	@echo "$(GREEN)🚀 Desenvolvimento:$(NC)"
	@echo "  make run              - Roda aplicação local"
	@echo "  make dev              - Roda em modo debug"
	@echo "  make shell            - Abre Python shell com contexto"
	@echo ""
	@echo "$(GREEN)🧪 Testes:$(NC)"
	@echo "  make test             - Roda todos os testes"
	@echo "  make test-cov         - Roda testes com coverage"
	@echo "  make lint             - Verifica código (flake8)"
	@echo "  make format           - Formata código (black)"
	@echo ""
	@echo "$(GREEN)🐳 Docker:$(NC)"
	@echo "  make docker-build     - Build das imagens"
	@echo "  make docker-up        - Sobe containers"
	@echo "  make docker-down      - Para containers"
	@echo "  make docker-restart   - Reinicia containers"
	@echo "  make docker-logs      - Ver logs"
	@echo "  make docker-shell     - Acessa shell do container"
	@echo ""
	@echo "$(GREEN)💾 Backup e Manutenção:$(NC)"
	@echo "  make backup           - Faz backup dos dados"
	@echo "  make clean            - Remove arquivos temporários"
	@echo "  make clean-all        - Remove tudo (venv + cache + logs)"
	@echo ""
	@echo "$(GREEN)🗄️ Database:$(NC)"
	@echo "  make db-init          - Inicializa banco de dados"
	@echo "  make db-migrate       - Roda migrations"
	@echo "  make db-reset         - Reseta banco (CUIDADO!)"
	@echo ""

# ===================================
# INSTALAÇÃO E SETUP
# ===================================
venv:
	@echo "$(YELLOW)📦 Criando ambiente virtual...$(NC)"
	$(PYTHON) -m venv $(VENV)
	@echo "$(GREEN)✅ Ambiente virtual criado!$(NC)"
	@echo "$(YELLOW)Active com: source $(VENV)/bin/activate$(NC)"

install:
	@echo "$(YELLOW)📦 Instalando dependências...$(NC)"
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt
	@echo "$(GREEN)✅ Dependências instaladas!$(NC)"

setup: venv
	@echo "$(YELLOW)⚙️  Configurando projeto...$(NC)"
	@. $(VENV)/bin/activate && $(PIP) install --upgrade pip
	@. $(VENV)/bin/activate && $(PIP) install -r requirements.txt
	@if [ ! -f .env ]; then \
		if [ -f .env.example ]; then \
			cp .env.example .env; \
			echo "$(GREEN)✅ .env criado - EDITE antes de usar!$(NC)"; \
		fi \
	fi
	@mkdir -p logs data uploads
	@echo "$(GREEN)✅ Setup completo!$(NC)"

# ===================================
# DESENVOLVIMENTO
# ===================================
run:
	@echo "$(YELLOW)🚀 Iniciando aplicação...$(NC)"
	$(PYTHON) app.py

dev:
	@echo "$(YELLOW)🐛 Iniciando em modo DEBUG...$(NC)"
	FLASK_ENV=development FLASK_DEBUG=1 $(PYTHON) app.py

shell:
	@echo "$(YELLOW)🐚 Abrindo Python shell...$(NC)"
	$(PYTHON) -i -c "from app import *"

# ===================================
# TESTES
# ===================================
test:
	@echo "$(YELLOW)🧪 Rodando testes...$(NC)"
	$(PYTHON) -m pytest tests/ -v

test-cov:
	@echo "$(YELLOW)🧪 Rodando testes com coverage...$(NC)"
	$(PYTHON) -m pytest tests/ --cov=. --cov-report=html --cov-report=term
	@echo "$(GREEN)✅ Report em: htmlcov/index.html$(NC)"

lint:
	@echo "$(YELLOW)🔍 Verificando código...$(NC)"
	$(PYTHON) -m flake8 . --exclude=$(VENV),migrations --max-line-length=120

format:
	@echo "$(YELLOW)✨ Formatando código...$(NC)"
	$(PYTHON) -m black . --exclude=$(VENV)
	@echo "$(GREEN)✅ Código formatado!$(NC)"

# ===================================
# DOCKER
# ===================================
docker-build:
	@echo "$(YELLOW)🔨 Buildando imagens Docker...$(NC)"
	docker-compose build --no-cache

docker-up:
	@echo "$(YELLOW)🚀 Subindo containers...$(NC)"
	docker-compose up -d
	@echo "$(GREEN)✅ Containers rodando!$(NC)"
	@docker-compose ps

docker-down:
	@echo "$(YELLOW)🛑 Parando containers...$(NC)"
	docker-compose down

docker-restart:
	@echo "$(YELLOW)🔄 Reiniciando containers...$(NC)"
	docker-compose restart

docker-logs:
	@echo "$(YELLOW)📋 Logs dos containers:$(NC)"
	docker-compose logs -f

docker-shell:
	@echo "$(YELLOW)🐚 Acessando shell do container...$(NC)"
	docker-compose exec app bash

docker-clean:
	@echo "$(YELLOW)🧹 Limpando Docker...$(NC)"
	docker-compose down -v
	docker system prune -f

# ===================================
# DATABASE
# ===================================
db-init:
	@echo "$(YELLOW)🗄️  Inicializando banco de dados...$(NC)"
	@if [ -f "init_db.py" ]; then \
		$(PYTHON) init_db.py; \
	else \
		$(PYTHON) -c "from app import db; db.create_all(); print('✅ Banco criado!')"; \
	fi

db-migrate:
	@echo "$(YELLOW)🗄️  Rodando migrations...$(NC)"
	$(PYTHON) -m flask db upgrade

db-reset:
	@echo "$(YELLOW)⚠️  ATENÇÃO: Isso vai DELETAR todos os dados!$(NC)"
	@read -p "Tem certeza? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		rm -f *.db; \
		$(PYTHON) -c "from app import db; db.drop_all(); db.create_all(); print('✅ Banco resetado!')"; \
	fi

# ===================================
# BACKUP
# ===================================
backup:
	@echo "$(YELLOW)💾 Fazendo backup...$(NC)"
	@mkdir -p backups
	@DATE=$$(date +%Y%m%d_%H%M%S); \
	tar -czf backups/backup_$$DATE.tar.gz data/ logs/ *.db 2>/dev/null || true
	@echo "$(GREEN)✅ Backup criado em backups/$(NC)"

# ===================================
# LIMPEZA
# ===================================
clean:
	@echo "$(YELLOW)🧹 Limpando arquivos temporários...$(NC)"
	find . -type d -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name '*.pyc' -delete 2>/dev/null || true
	find . -type f -name '*.pyo' -delete 2>/dev/null || true
	find . -type d -name '*.egg-info' -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name '.pytest_cache' -exec rm -rf {} + 2>/dev/null || true
	rm -rf .coverage htmlcov/ 2>/dev/null || true
	@echo "$(GREEN)✅ Limpeza concluída!$(NC)"

clean-all: clean
	@echo "$(YELLOW)🧹 Removendo TUDO (venv + logs + cache)...$(NC)"
	rm -rf $(VENV)
	rm -rf logs/*
	rm -rf *.log
	@echo "$(GREEN)✅ Limpeza total concluída!$(NC)"

# ===================================
# PRODUÇÃO
# ===================================
deploy:
	@echo "$(YELLOW)🚀 Executando deploy...$(NC)"
	@chmod +x deploy.sh
	@./deploy.sh

prod-build:
	@echo "$(YELLOW)🔨 Build para produção...$(NC)"
	docker-compose -f docker-compose.yml build --no-cache

prod-up:
	@echo "$(YELLOW)🚀 Deploy em produção...$(NC)"
	docker-compose -f docker-compose.yml up -d
	@echo "$(GREEN)✅ Aplicação em produção!$(NC)"

# ===================================
# UTILITÁRIOS
# ===================================
requirements:
	@echo "$(YELLOW)📝 Atualizando requirements.txt...$(NC)"
	$(PIP) freeze > requirements.txt
	@echo "$(GREEN)✅ requirements.txt atualizado!$(NC)"

check:
	@echo "$(YELLOW)🔍 Verificando instalação...$(NC)"
	@$(PYTHON) --version
	@$(PIP) --version
	@if [ -f ".env" ]; then echo "$(GREEN)✅ .env encontrado$(NC)"; else echo "$(YELLOW)⚠️  .env não encontrado$(NC)"; fi
	@if [ -f "requirements.txt" ]; then echo "$(GREEN)✅ requirements.txt encontrado$(NC)"; fi
	@echo "$(GREEN)✅ Verificação concluída!$(NC)"

info:
	@echo ""
	@echo "$(BLUE)╔════════════════════════════════════════════════╗$(NC)"
	@echo "$(BLUE)║            INFORMAÇÕES DO PROJETO              ║$(NC)"
	@echo "$(BLUE)╚════════════════════════════════════════════════╝$(NC)"
	@echo ""
	@echo "$(GREEN)📁 Projeto:$(NC) $$(basename $$(pwd))"
	@echo "$(GREEN)🐍 Python:$(NC) $$($(PYTHON) --version)"
	@echo "$(GREEN)📦 Venv:$(NC) $$(if [ -d $(VENV) ]; then echo 'Ativo'; else echo 'Não criado'; fi)"
	@echo "$(GREEN)🗄️  Database:$(NC) $$(if [ -f *.db ]; then echo 'SQLite'; else echo 'PostgreSQL/Externo'; fi)"
	@echo "$(GREEN)🐳 Docker:$(NC) $$(if [ -f docker-compose.yml ]; then echo 'Configurado'; else echo 'Não configurado'; fi)"
	@echo ""