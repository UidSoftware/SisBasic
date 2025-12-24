#!/bin/bash

# ===================================
# DEPLOY SCRIPT UNIVERSAL - Flask Projects
# ===================================
# Usa esse script em qualquer projeto Flask
# Detecta automaticamente se tem Docker, banco, etc
# ===================================

set -e

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configs
PROJECT_NAME=$(basename "$PWD")
VENV_DIR="venv"
PYTHON_CMD="python3"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      🚀 DEPLOY SCRIPT - ${PROJECT_NAME}${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# ===================================
# FUNÇÕES AUXILIARES
# ===================================

print_step() {
    echo -e "\n${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}$1${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

check_command() {
    if command -v "$1" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# ===================================
# 1. DETECTA AMBIENTE
# ===================================
print_step "📋 DETECTANDO AMBIENTE"

# Verifica Python
if check_command python3; then
    PYTHON_CMD="python3"
    print_success "Python3 encontrado"
elif check_command python; then
    PYTHON_CMD="python"
    print_success "Python encontrado"
else
    print_error "Python não encontrado!"
    exit 1
fi

PYTHON_VERSION=$($PYTHON_CMD --version)
print_info "Versão: $PYTHON_VERSION"

# Verifica se tem Docker
HAS_DOCKER=false
if [ -f "docker-compose.yml" ] || [ -f "Dockerfile" ]; then
    if check_command docker && check_command docker-compose; then
        HAS_DOCKER=true
        print_success "Docker detectado"
    else
        print_warning "Arquivos Docker encontrados, mas Docker não instalado"
    fi
fi

# Verifica se tem banco de dados
HAS_DATABASE=false
if grep -q "SQLAlchemy\|psycopg2\|pymongo" requirements.txt 2>/dev/null; then
    HAS_DATABASE=true
    print_info "Projeto usa banco de dados"
fi

# ===================================
# 2. ESCOLHE MODO DE DEPLOY
# ===================================
print_step "🎯 ESCOLHA O MODO DE DEPLOY"

echo ""
echo "1) 🐍 Local (Python + venv)"
echo "2) 🐳 Docker (docker-compose)"
echo "3) 🚀 Produção (Deploy em VPS)"
echo ""
read -p "Escolha uma opção [1-3]: " DEPLOY_MODE

# ===================================
# MODO 1: LOCAL (DESENVOLVIMENTO)
# ===================================
if [ "$DEPLOY_MODE" = "1" ]; then
    print_step "🐍 DEPLOY LOCAL"
    
    # Cria ambiente virtual
    if [ ! -d "$VENV_DIR" ]; then
        print_info "Criando ambiente virtual..."
        $PYTHON_CMD -m venv $VENV_DIR
        print_success "Ambiente virtual criado"
    else
        print_info "Ambiente virtual já existe"
    fi
    
    # Ativa ambiente virtual
    print_info "Ativando ambiente virtual..."
    source $VENV_DIR/bin/activate 2>/dev/null || source $VENV_DIR/Scripts/activate 2>/dev/null
    
    # Atualiza pip
    print_info "Atualizando pip..."
    pip install --upgrade pip -q
    
    # Instala dependências
    if [ -f "requirements.txt" ]; then
        print_info "Instalando dependências..."
        pip install -r requirements.txt
        print_success "Dependências instaladas"
    else
        print_warning "requirements.txt não encontrado"
    fi
    
    # Configura .env
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            print_info "Criando .env a partir do .env.example..."
            cp .env.example .env
            
            # Gera SECRET_KEY
            SECRET_KEY=$($PYTHON_CMD -c "import secrets; print(secrets.token_hex(32))")
            sed -i.bak "s/GERE_UMA_CHAVE_SECRETA/$SECRET_KEY/" .env 2>/dev/null || \
            sed -i '' "s/GERE_UMA_CHAVE_SECRETA/$SECRET_KEY/" .env 2>/dev/null
            
            print_success ".env criado"
            print_warning "EDITE o arquivo .env antes de continuar!"
            echo ""
            read -p "Pressione ENTER após editar o .env..."
        else
            print_warning ".env não encontrado"
        fi
    fi
    
    # Cria diretórios necessários
    mkdir -p logs data uploads 2>/dev/null
    
    # Inicializa banco de dados (se necessário)
    if [ "$HAS_DATABASE" = true ]; then
        print_info "Verificando banco de dados..."
        
        if [ -f "init_db.py" ]; then
            print_info "Executando init_db.py..."
            $PYTHON_CMD init_db.py
        elif [ -f "migrate.py" ]; then
            print_info "Executando migrate.py..."
            $PYTHON_CMD migrate.py
        else
            print_info "Criando tabelas (se necessário)..."
            $PYTHON_CMD -c "
try:
    from app import db
    db.create_all()
    print('Tabelas criadas com sucesso!')
except Exception as e:
    print(f'Nota: {e}')
" 2>/dev/null || print_info "Script de banco não encontrado"
        fi
    fi
    
    # Inicia aplicação
    print_step "✅ DEPLOY LOCAL CONCLUÍDO"
    print_success "Ambiente pronto!"
    echo ""
    print_info "Para iniciar a aplicação:"
    echo -e "  ${GREEN}source $VENV_DIR/bin/activate${NC}"
    echo -e "  ${GREEN}python app.py${NC}"
    echo ""
    
    read -p "Deseja iniciar a aplicação agora? (s/n): " START_NOW
    if [ "$START_NOW" = "s" ] || [ "$START_NOW" = "S" ]; then
        print_info "Iniciando aplicação..."
        $PYTHON_CMD app.py
    fi

# ===================================
# MODO 2: DOCKER (DESENVOLVIMENTO/PRODUÇÃO)
# ===================================
elif [ "$DEPLOY_MODE" = "2" ]; then
    print_step "🐳 DEPLOY COM DOCKER"
    
    if [ "$HAS_DOCKER" = false ]; then
        print_error "Docker/Docker Compose não encontrados!"
        print_info "Instale com: curl -fsSL https://get.docker.com | sh"
        exit 1
    fi
    
    # Configura .env
    if [ ! -f ".env" ]; then
        if [ -f ".env.example" ]; then
            print_info "Criando .env..."
            cp .env.example .env
            
            SECRET_KEY=$($PYTHON_CMD -c "import secrets; print(secrets.token_hex(32))")
            sed -i.bak "s/GERE_UMA_CHAVE_SECRETA/$SECRET_KEY/" .env 2>/dev/null || \
            sed -i '' "s/GERE_UMA_CHAVE_SECRETA/$SECRET_KEY/" .env 2>/dev/null
            
            print_success ".env criado"
            print_warning "EDITE o .env se necessário!"
            read -p "Pressione ENTER para continuar..."
        fi
    fi
    
    # Cria diretórios
    mkdir -p logs data nginx/ssl 2>/dev/null
    
    # Para containers antigos
    print_info "Parando containers antigos..."
    docker-compose down 2>/dev/null || true
    
    # Build
    print_info "Buildando imagens Docker..."
    docker-compose build --no-cache
    
    if [ $? -ne 0 ]; then
        print_error "Erro no build!"
        exit 1
    fi
    
    # Sobe containers
    print_info "Subindo containers..."
    docker-compose up -d
    
    if [ $? -ne 0 ]; then
        print_error "Erro ao subir containers!"
        exit 1
    fi
    
    # Aguarda containers
    print_info "Aguardando containers ficarem prontos..."
    sleep 10
    
    # Verifica saúde
    print_info "Verificando status..."
    docker-compose ps
    
    # Testa aplicação
    print_info "Testando aplicação..."
    sleep 5
    
    if curl -f http://localhost:5000/ > /dev/null 2>&1; then
        print_success "Aplicação está respondendo!"
    else
        print_warning "Aplicação pode não estar pronta ainda"
        print_info "Verifique logs: docker-compose logs -f app"
    fi
    
    # Resultado
    print_step "✅ DEPLOY DOCKER CONCLUÍDO"
    echo ""
    print_success "Aplicação rodando!"
    echo ""
    print_info "Acessos:"
    echo "  • Aplicação: http://localhost:5000"
    echo "  • Nginx:     http://localhost:80 (se configurado)"
    echo ""
    print_info "Comandos úteis:"
    echo "  • Ver logs:     docker-compose logs -f app"
    echo "  • Parar:        docker-compose stop"
    echo "  • Reiniciar:    docker-compose restart"
    echo "  • Remover:      docker-compose down"
    echo "  • Status:       docker-compose ps"
    echo ""

# ===================================
# MODO 3: PRODUÇÃO (VPS)
# ===================================
elif [ "$DEPLOY_MODE" = "3" ]; then
    print_step "🚀 DEPLOY EM PRODUÇÃO"
    
    print_warning "Este modo fará deploy em um servidor de produção!"
    read -p "Tem certeza? (s/n): " CONFIRM
    
    if [ "$CONFIRM" != "s" ] && [ "$CONFIRM" != "S" ]; then
        print_info "Deploy cancelado"
        exit 0
    fi
    
    # Verifica se tem Docker
    if [ "$HAS_DOCKER" = false ]; then
        print_error "Docker é necessário para deploy em produção!"
        exit 1
    fi
    
    # Configurações de produção
    print_info "Configurando ambiente de produção..."
    
    # Força FLASK_ENV=production
    if [ -f ".env" ]; then
        sed -i.bak 's/FLASK_ENV=development/FLASK_ENV=production/' .env 2>/dev/null || \
        sed -i '' 's/FLASK_ENV=development/FLASK_ENV=production/' .env 2>/dev/null
        sed -i.bak 's/DEBUG=True/DEBUG=False/' .env 2>/dev/null || \
        sed -i '' 's/DEBUG=True/DEBUG=False/' .env 2>/dev/null
        print_success "Configurações de produção aplicadas"
    fi
    
    # Cria diretórios
    mkdir -p logs data nginx/ssl backups 2>/dev/null
    
    # Build e deploy
    print_info "Buildando para produção..."
    docker-compose -f docker-compose.yml build --no-cache
    
    print_info "Subindo em modo produção..."
    docker-compose -f docker-compose.yml up -d
    
    # Aguarda e verifica
    sleep 15
    
    print_info "Verificando aplicação..."
    if curl -f http://localhost:5000/ > /dev/null 2>&1; then
        print_success "Aplicação está online!"
    else
        print_error "Aplicação não está respondendo!"
        print_info "Verifique logs: docker-compose logs app"
        exit 1
    fi
    
    # Configurar SSL
    print_step "🔐 CONFIGURAÇÃO SSL"
    read -p "Deseja configurar SSL/HTTPS? (s/n): " SETUP_SSL
    
    if [ "$SETUP_SSL" = "s" ] || [ "$SETUP_SSL" = "S" ]; then
        read -p "Digite seu domínio (ex: app.com): " DOMAIN
        read -p "Digite seu email: " EMAIL
        
        print_info "Gerando certificado SSL..."
        docker run -it --rm \
            -v $(pwd)/nginx/ssl:/etc/letsencrypt \
            -p 80:80 \
            certbot/certbot certonly \
            --standalone \
            -d $DOMAIN \
            --email $EMAIL \
            --agree-tos \
            --no-eff-email
        
        if [ $? -eq 0 ]; then
            print_success "Certificado SSL gerado!"
            print_info "Configure o nginx.conf para usar HTTPS"
            print_info "Reinicie: docker-compose restart nginx"
        else
            print_error "Erro ao gerar certificado SSL"
        fi
    fi
    
    # Backup automático
    print_step "💾 CONFIGURAÇÃO DE BACKUP"
    read -p "Deseja configurar backup automático? (s/n): " SETUP_BACKUP
    
    if [ "$SETUP_BACKUP" = "s" ] || [ "$SETUP_BACKUP" = "S" ]; then
        cat > backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="./backups"
DATE=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Backup do banco de dados
if [ -f ".env" ]; then
    source .env
    if [ ! -z "$DATABASE_URL" ]; then
        echo "Fazendo backup do banco..."
        docker-compose exec -T postgres pg_dump -U $POSTGRES_USER $POSTGRES_DB | gzip > $BACKUP_DIR/db_$DATE.sql.gz
    fi
fi

# Backup dos dados
tar -czf $BACKUP_DIR/data_$DATE.tar.gz data/ 2>/dev/null

# Remove backups antigos (mantém 7 dias)
find $BACKUP_DIR -name "*.gz" -mtime +7 -delete

echo "Backup realizado: $DATE"
EOF
        
        chmod +x backup.sh
        
        # Adiciona ao cron
        print_info "Adicionando backup ao cron (diário às 3h)..."
        (crontab -l 2>/dev/null; echo "0 3 * * * cd $(pwd) && ./backup.sh >> logs/backup.log 2>&1") | crontab -
        
        print_success "Backup automático configurado!"
    fi
    
    # Resultado final
    print_step "✅ DEPLOY EM PRODUÇÃO CONCLUÍDO"
    echo ""
    print_success "Aplicação está rodando em produção!"
    echo ""
    print_info "Checklist de segurança:"
    echo "  [ ] Firewall configurado (ufw)"
    echo "  [ ] SSL/HTTPS ativado"
    echo "  [ ] Backup automático rodando"
    echo "  [ ] Logs sendo monitorados"
    echo "  [ ] Senhas fortes no .env"
    echo "  [ ] Database em servidor separado"
    echo ""
    print_info "Monitoramento:"
    echo "  • Logs:   docker-compose logs -f"
    echo "  • Status: docker-compose ps"
    echo "  • Stats:  docker stats"
    echo ""

else
    print_error "Opção inválida!"
    exit 1
fi

# ===================================
# FIM
# ===================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ✅ DEPLOY FINALIZADO!               ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""