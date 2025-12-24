#!/bin/bash

# ===================================
# CREATE FLASK PROJECT
# ===================================
# Script para criar um novo projeto Flask
# com toda a estrutura base
# ===================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║      🚀 CREATE FLASK PROJECT                   ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════╝${NC}"
echo ""

# Nome do projeto
if [ -z "$1" ]; then
    read -p "Nome do projeto: " PROJECT_NAME
else
    PROJECT_NAME="$1"
fi

if [ -z "$PROJECT_NAME" ]; then
    echo -e "${RED}❌ Nome do projeto é obrigatório!${NC}"
    exit 1
fi

# Verifica se já existe
if [ -d "$PROJECT_NAME" ]; then
    echo -e "${RED}❌ Diretório $PROJECT_NAME já existe!${NC}"
    exit 1
fi

echo -e "${YELLOW}📁 Criando projeto: $PROJECT_NAME${NC}"
echo ""

# Cria estrutura de diretórios
mkdir -p "$PROJECT_NAME"/{templates,static/{css,js,img},tests,logs,data}

cd "$PROJECT_NAME"

# ===================================
# CRIA app.py
# ===================================
cat > app.py << 'EOF'
from flask import Flask, render_template
from config import config
import os

def create_app(config_name='default'):
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    
    @app.route('/')
    def index():
        return render_template('index.html', 
                             project_name=app.config.get('PROJECT_NAME', 'Flask App'))
    
    @app.route('/health')
    def health():
        return {'status': 'ok', 'message': 'Application is running'}, 200
    
    @app.errorhandler(404)
    def not_found(error):
        return render_template('404.html'), 404
    
    return app

if __name__ == '__main__':
    env = os.getenv('FLASK_ENV', 'development')
    app = create_app(env)
    
    host = os.getenv('HOST', '0.0.0.0')
    port = int(os.getenv('PORT', 5000))
    
    app.run(host=host, port=port, debug=app.config['DEBUG'])
EOF

# ===================================
# CRIA config.py
# ===================================
cat > config.py << 'EOF'
import os
from dotenv import load_dotenv

load_dotenv()

class Config:
    """Configurações base"""
    SECRET_KEY = os.getenv('SECRET_KEY', 'dev-secret-key-change-in-production')
    DEBUG = False
    TESTING = False
    
    # Project
    PROJECT_NAME = os.getenv('PROJECT_NAME', 'Flask App')
    
    # Database
    SQLALCHEMY_DATABASE_URI = os.getenv('DATABASE_URL', 'sqlite:///app.db')
    SQLALCHEMY_TRACK_MODIFICATIONS = False
    
    # Upload
    MAX_CONTENT_LENGTH = 16 * 1024 * 1024  # 16MB
    UPLOAD_FOLDER = 'uploads'
    ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'pdf'}
    
    # Session
    SESSION_TYPE = 'filesystem'
    PERMANENT_SESSION_LIFETIME = 3600  # 1 hora

class DevelopmentConfig(Config):
    """Configurações de desenvolvimento"""
    DEBUG = True
    
class ProductionConfig(Config):
    """Configurações de produção"""
    DEBUG = False
    TESTING = False
    
class TestingConfig(Config):
    """Configurações de testes"""
    TESTING = True
    SQLALCHEMY_DATABASE_URI = 'sqlite:///:memory:'

config = {
    'development': DevelopmentConfig,
    'production': ProductionConfig,
    'testing': TestingConfig,
    'default': DevelopmentConfig
}
EOF

# ===================================
# CRIA requirements.txt
# ===================================
cat > requirements.txt << 'EOF'
# Core
Flask==3.0.0
python-dotenv==1.0.0

# Database (descomente se usar)
# Flask-SQLAlchemy==3.1.1
# psycopg2-binary==2.9.9

# Auth (descomente se usar)
# Flask-Login==0.6.3
# Flask-Bcrypt==1.0.1

# Forms (descomente se usar)
# Flask-WTF==1.2.1
# email-validator==2.1.0

# Production Server
# gunicorn==21.2.0

# Development
# pytest==7.4.3
# black==23.12.1
# flake8==6.1.0
EOF

# ===================================
# CRIA .env.example
# ===================================
cat > .env.example << 'EOF'
# Flask
FLASK_ENV=development
SECRET_KEY=GERE_UMA_CHAVE_SECRETA
DEBUG=True

# Project
PROJECT_NAME=My Flask App

# Server
HOST=0.0.0.0
PORT=5000

# Database (se usar)
# DATABASE_URL=sqlite:///app.db
# ou
# DATABASE_URL=postgresql://user:password@localhost/dbname

# Email (se usar)
# MAIL_SERVER=smtp.gmail.com
# MAIL_PORT=587
# MAIL_USERNAME=seu-email@gmail.com
# MAIL_PASSWORD=sua-senha-app
EOF

# ===================================
# CRIA .gitignore
# ===================================
cat > .gitignore << 'EOF'
# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
venv/
env/
ENV/
.venv

# Flask
instance/
.webassets-cache

# Environment
.env
.env.local

# IDE
.vscode/
.idea/
*.swp
*.swo

# OS
.DS_Store
Thumbs.db

# Logs
*.log
logs/

# Database
*.db
*.sqlite3

# Uploads
uploads/
data/

# Tests
.pytest_cache/
.coverage
htmlcov/

# Build
dist/
build/
*.egg-info/
EOF

# ===================================
# CRIA templates/index.html
# ===================================
cat > templates/index.html << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ project_name }}</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <div class="container">
        <header>
            <h1>🚀 {{ project_name }}</h1>
            <p class="subtitle">Projeto Flask criado com sucesso!</p>
        </header>
        
        <main>
            <div class="card">
                <h2>✅ Tudo funcionando!</h2>
                <p>Seu projeto Flask está rodando corretamente.</p>
            </div>
            
            <div class="card">
                <h3>📚 Próximos Passos:</h3>
                <ol>
                    <li>Edite <code>app.py</code> para adicionar novas rotas</li>
                    <li>Customize o HTML em <code>templates/</code></li>
                    <li>Adicione estilos em <code>static/css/</code></li>
                    <li>Configure banco de dados se necessário</li>
                </ol>
            </div>
            
            <div class="card">
                <h3>🔧 Comandos Úteis:</h3>
                <ul>
                    <li><code>make run</code> - Inicia aplicação</li>
                    <li><code>make test</code> - Roda testes</li>
                    <li><code>make help</code> - Ver todos comandos</li>
                </ul>
            </div>
        </main>
        
        <footer>
            <p>Criado com ❤️ usando Flask</p>
        </footer>
    </div>
</body>
</html>
EOF

# ===================================
# CRIA templates/404.html
# ===================================
cat > templates/404.html << 'EOF'
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>404 - Página não encontrada</title>
    <link rel="stylesheet" href="{{ url_for('static', filename='css/style.css') }}">
</head>
<body>
    <div class="container">
        <div class="error-page">
            <h1>404</h1>
            <p>Página não encontrada</p>
            <a href="{{ url_for('index') }}" class="btn">Voltar para home</a>
        </div>
    </div>
</body>
</html>
EOF

# ===================================
# CRIA static/css/style.css
# ===================================
cat > static/css/style.css << 'EOF'
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
}

body {
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
    line-height: 1.6;
    color: #333;
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    min-height: 100vh;
    padding: 20px;
}

.container {
    max-width: 800px;
    margin: 0 auto;
    background: white;
    border-radius: 10px;
    box-shadow: 0 10px 40px rgba(0,0,0,0.2);
    overflow: hidden;
}

header {
    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
    color: white;
    padding: 40px 20px;
    text-align: center;
}

header h1 {
    font-size: 2.5rem;
    margin-bottom: 10px;
}

.subtitle {
    font-size: 1.1rem;
    opacity: 0.9;
}

main {
    padding: 40px 20px;
}

.card {
    background: #f8f9fa;
    border-radius: 8px;
    padding: 20px;
    margin-bottom: 20px;
    border-left: 4px solid #667eea;
}

.card h2, .card h3 {
    color: #667eea;
    margin-bottom: 15px;
}

.card ol, .card ul {
    margin-left: 20px;
}

.card li {
    margin: 10px 0;
}

code {
    background: #e9ecef;
    padding: 2px 6px;
    border-radius: 3px;
    font-family: 'Courier New', monospace;
}

footer {
    background: #f8f9fa;
    text-align: center;
    padding: 20px;
    color: #666;
}

.error-page {
    text-align: center;
    padding: 100px 20px;
}

.error-page h1 {
    font-size: 6rem;
    color: #667eea;
}

.btn {
    display: inline-block;
    background: #667eea;
    color: white;
    padding: 10px 30px;
    border-radius: 5px;
    text-decoration: none;
    margin-top: 20px;
    transition: background 0.3s;
}

.btn:hover {
    background: #764ba2;
}
EOF

# ===================================
# CRIA README.md
# ===================================
cat > README.md << EOF
# $PROJECT_NAME

Projeto Flask criado com template base.

## 🚀 Instalação

\`\`\`bash
# Clone o repositório
git clone https://github.com/usuario/$PROJECT_NAME.git
cd $PROJECT_NAME

# Instale dependências
make setup

# Configure ambiente
cp .env.example .env
# Edite o .env conforme necessário

# Execute
make run
\`\`\`

## 📖 Uso

Acesse: http://localhost:5000

## 🔧 Comandos

- \`make help\` - Ver todos comandos disponíveis
- \`make run\` - Rodar aplicação
- \`make test\` - Rodar testes
- \`make clean\` - Limpar arquivos temporários

## 📝 Estrutura

\`\`\`
$PROJECT_NAME/
├── app.py              # Aplicação principal
├── config.py           # Configurações
├── requirements.txt    # Dependências
├── templates/          # HTML templates
├── static/            # CSS, JS, imagens
├── tests/             # Testes
└── README.md          # Esta documentação
\`\`\`

## 🤝 Contribuindo

1. Fork o projeto
2. Crie sua branch (\`git checkout -b feature/MinhaFeature\`)
3. Commit suas mudanças (\`git commit -m 'Add: MinhaFeature'\`)
4. Push para a branch (\`git push origin feature/MinhaFeature\`)
5. Abra um Pull Request

## 📝 Licença

MIT
EOF

# ===================================
# CRIA Makefile
# ===================================
wget -q https://raw.githubusercontent.com/seu-user/templates/main/Makefile -O Makefile 2>/dev/null || \
echo "# Use o Makefile universal fornecido" > Makefile

# ===================================
# CRIA deploy.sh
# ===================================
wget -q https://raw.githubusercontent.com/seu-user/templates/main/deploy.sh -O deploy.sh 2>/dev/null || \
echo "#!/bin/bash\necho 'Deploy script - use o fornecido'" > deploy.sh
chmod +x deploy.sh

# ===================================
# Inicializa Git
# ===================================
git init > /dev/null 2>&1
git add .
git commit -m "Initial commit - Project structure" > /dev/null 2>&1

# ===================================
# RESULTADO
# ===================================
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        ✅ PROJETO CRIADO COM SUCESSO!          ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📁 Projeto:${NC} $PROJECT_NAME"
echo -e "${BLUE}📂 Local:${NC} $(pwd)"
echo ""
echo -e "${YELLOW}📋 Próximos passos:${NC}"
echo ""
echo -e "  ${GREEN}1.${NC} cd $PROJECT_NAME"
echo -e "  ${GREEN}2.${NC} make setup"
echo -e "  ${GREEN}3.${NC} cp .env.example .env"
echo -e "  ${GREEN}4.${NC} make run"
echo ""
echo -e "${YELLOW}💡 Comandos úteis:${NC}"
echo -e "  • ${GREEN}make help${NC}  - Ver todos comandos"
echo -e "  • ${GREEN}make run${NC}   - Rodar aplicação"
echo -e "  • ${GREEN}make test${NC}  - Rodar testes"
echo ""
echo -e "${GREEN}🎉 Bom desenvolvimento!${NC}"
echo ""