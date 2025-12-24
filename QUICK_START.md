# 🚀 Quick Start - Template Flask Universal

Guia rápido para usar os scripts de automação em qualquer projeto Flask.

---

## 📦 Arquivos do Template

| Arquivo | Descrição | Quando usar |
|---------|-----------|-------------|
| **create-flask-project.sh** | Cria novo projeto do zero | Sempre que iniciar projeto novo |
| **deploy.sh** | Deploy automático (3 modos) | Deploy local, Docker ou Produção |
| **Makefile** | Comandos automatizados | Desenvolvimento e manutenção |
| **TEMPLATE_BASE.md** | Documentação da estrutura | Referência |

---

## 🎯 Cenários de Uso

### **Cenário 1: Criar Projeto Novo do Zero**

```bash
# Torna o script executável
chmod +x create-flask-project.sh

# Cria novo projeto
./create-flask-project.sh meu-projeto

# Entra no projeto
cd meu-projeto

# Setup inicial
make setup

# Roda aplicação
make run
```

✅ **Resultado:** Projeto Flask completo e funcionando!

---

### **Cenário 2: Deploy Local (Desenvolvimento)**

```bash
# No diretório do projeto
chmod +x deploy.sh
./deploy.sh

# Escolha: 1 (Local)

# Acesse: http://localhost:5000
```

**O script faz:**
- ✅ Cria venv
- ✅ Instala dependências
- ✅ Cria .env
- ✅ Inicializa banco (se tiver)
- ✅ Roda aplicação

---

### **Cenário 3: Deploy com Docker**

```bash
# No diretório do projeto
./deploy.sh

# Escolha: 2 (Docker)

# Acesse: http://localhost:5000
```

**O script faz:**
- ✅ Valida Docker
- ✅ Cria .env
- ✅ Build das imagens
- ✅ Sobe containers
- ✅ Health checks

---

### **Cenário 4: Deploy em Produção (VPS)**

```bash
# No VPS
git clone https://github.com/seu-user/projeto.git
cd projeto

./deploy.sh

# Escolha: 3 (Produção)

# Opcionalmente configura SSL
```

**O script faz:**
- ✅ Configura ambiente produção
- ✅ Build e deploy Docker
- ✅ Configuração SSL (opcional)
- ✅ Backup automático (opcional)
- ✅ Health checks

---

## 🔧 Usando o Makefile

### **Comandos Mais Usados:**

```bash
# Ver todos comandos
make help

# Desenvolvimento
make setup      # Setup completo
make run        # Roda aplicação
make dev        # Roda em modo debug

# Testes
make test       # Roda testes
make lint       # Verifica código

# Docker
make docker-up     # Sobe containers
make docker-down   # Para containers
make docker-logs   # Ver logs

# Limpeza
make clean      # Remove temporários
make clean-all  # Remove tudo (venv + cache)

# Info
make info       # Informações do projeto
make check      # Verifica instalação
```

---

## 📋 Fluxo Completo de Novo Projeto

```bash
# 1. Cria projeto
./create-flask-project.sh meu-saas
cd meu-saas

# 2. Inicializa Git remote
git remote add origin https://github.com/user/meu-saas.git
git push -u origin main

# 3. Setup local
make setup
cp .env.example .env
nano .env  # Edite configurações

# 4. Desenvolve
make run
# Desenvolve suas features...

# 5. Testa
make test
make lint

# 6. Deploy desenvolvimento
./deploy.sh  # Opção 2 (Docker)

# 7. Deploy produção (quando pronto)
# No VPS:
git clone https://github.com/user/meu-saas.git
cd meu-saas
./deploy.sh  # Opção 3 (Produção)
```

---

## 🎨 Personalizando o Template

### **Adicionar Banco de Dados:**

1. Descomente em `requirements.txt`:
```txt
Flask-SQLAlchemy==3.1.1
psycopg2-binary==2.9.9
```

2. Instale:
```bash
make install
```

3. Configure `app.py`:
```python
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

def create_app(config_name='default'):
    app = Flask(__name__)
    app.config.from_object(config[config_name])
    
    db.init_app(app)
    
    with app.app_context():
        db.create_all()
    
    return app
```

4. Inicialize:
```bash
make db-init
```

---

### **Adicionar Autenticação:**

1. Descomente em `requirements.txt`:
```txt
Flask-Login==0.6.3
Flask-Bcrypt==1.0.1
```

2. Instale:
```bash
make install
```

3. Configure em `app.py`

---

### **Adicionar Testes:**

1. Crie `tests/test_app.py`:
```python
import pytest
from app import create_app

@pytest.fixture
def client():
    app = create_app('testing')
    with app.test_client() as client:
        yield client

def test_home(client):
    response = client.get('/')
    assert response.status_code == 200
```

2. Rode:
```bash
make test
```

---

## 🐳 Estrutura Docker (Quando Necessário)

### **Criar Dockerfile:**

```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "app:create_app()"]
```

### **Criar docker-compose.yml:**

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "5000:5000"
    volumes:
      - ./data:/app/data
    env_file:
      - .env
```

### **Deploy:**

```bash
make docker-build
make docker-up
```

---

## 🔐 Segurança - Checklist

Antes de colocar em produção:

- [ ] SECRET_KEY gerada aleatoriamente
- [ ] DEBUG=False em produção
- [ ] .env não commitado no Git
- [ ] Senhas fortes no banco
- [ ] SSL/HTTPS configurado
- [ ] Firewall configurado
- [ ] Backup automático
- [ ] Validação de inputs
- [ ] Rate limiting
- [ ] CORS configurado (se API)

---

## 📊 Monitoramento

### **Logs em Desenvolvimento:**
```bash
# Local
tail -f logs/app.log

# Docker
make docker-logs
```

### **Logs em Produção:**
```bash
# Via Docker
docker-compose logs -f app

# Via sistema
tail -f /var/log/syslog | grep flask
```

---

## 🐛 Troubleshooting

### **Problema: "Permission denied" no deploy.sh**
```bash
chmod +x deploy.sh
chmod +x create-flask-project.sh
```

### **Problema: "venv não encontrado"**
```bash
make venv
source venv/bin/activate
```

### **Problema: "Port 5000 already in use"**
```bash
# Mata processo na porta 5000
lsof -ti:5000 | xargs kill -9

# Ou muda porta no .env
echo "PORT=8000" >> .env
```

### **Problema: Docker não sobe**
```bash
# Verifica se Docker está rodando
sudo systemctl start docker

# Rebuild completo
make docker-clean
make docker-build
make docker-up
```

---

## 🎯 Melhores Práticas

1. **Sempre use .env para configurações**
2. **Commite .env.example, nunca .env**
3. **Use make para comandos comuns**
4. **Teste antes de fazer deploy**
5. **Mantenha requirements.txt atualizado**
6. **Use Git branches (main, dev, feature/xxx)**
7. **Documente mudanças no README**
8. **Faça commits pequenos e frequentes**
9. **Use mensagens de commit claras**
10. **Configure CI/CD quando possível**

---

## 📚 Recursos

- [Flask Docs](https://flask.palletsprojects.com/)
- [Docker Docs](https://docs.docker.com/)
- [Python Best Practices](https://docs.python-guide.org/)
- [12 Factor App](https://12factor.net/)

---

## 💡 Dicas

### **Desenvolvimento Rápido:**
```bash
# Terminal 1: Backend
make dev

# Terminal 2: Testes automáticos
make test-watch  # (adicione ao Makefile se precisar)
```

### **Git Workflow:**
```bash
git checkout -b feature/nova-funcionalidade
# Desenvolve...
make test
git add .
git commit -m "Add: nova funcionalidade"
git push origin feature/nova-funcionalidade
# Abre PR no GitHub
```

### **Deploy Contínuo:**
```bash
# .github/workflows/deploy.yml
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - run: ./deploy.sh
```

---

**✅ Agora você tem tudo para criar e deployar projetos Flask profissionalmente! 🚀**