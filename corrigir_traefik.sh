#!/bin/bash

echo "=== SCRIPT DE CORREÇÃO TRAEFIK ==="
echo "Data: $(date)"
echo ""

# Função para verificar se comando foi executado com sucesso
check_success() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ Erro ao $1"
        exit 1
    fi
}

echo "1. Parando container Traefik se estiver rodando..."
docker stop traefik 2>/dev/null || echo "Container Traefik não estava rodando"
docker rm traefik 2>/dev/null || echo "Container Traefik não existia"
echo ""

echo "2. Criando rede Docker 'coolify' se não existir..."
if ! docker network ls | grep -q coolify; then
    docker network create coolify
    check_success "criar rede coolify"
else
    echo "✅ Rede coolify já existe"
fi
echo ""

echo "3. Criando diretórios do Traefik..."
mkdir -p /opt/coolify/traefik/dynamic
check_success "criar diretórios"
echo ""

echo "4. Criando arquivo traefik.yml..."
cat > /opt/coolify/traefik/traefik.yml << 'EOF'
api:
  dashboard: true
  insecure: true

entryPoints:
  web:
    address: ":80"
  websecure:
    address: ":443"

providers:
  file:
    directory: /etc/traefik/dynamic
    watch: true

certificatesResolvers:
  letsencrypt:
    acme:
      email: admin@example.com
      storage: /data/acme.json
      httpChallenge:
        entryPoint: web

global:
  checkNewVersion: false
  sendAnonymousUsage: false
EOF
check_success "criar traefik.yml"
echo ""

echo "5. Criando arquivo middlewares.yml..."
cat > /opt/coolify/traefik/dynamic/middlewares.yml << 'EOF'
http:
  middlewares:
    security-headers:
      headers:
        customRequestHeaders:
          X-Forwarded-Proto: "https"
        customResponseHeaders:
          X-Frame-Options: "DENY"
          X-Content-Type-Options: "nosniff"
          X-XSS-Protection: "1; mode=block"
          Strict-Transport-Security: "max-age=31536000; includeSubDomains"
          Referrer-Policy: "strict-origin-when-cross-origin"
    
    cors-headers:
      headers:
        accessControlAllowMethods:
          - GET
          - POST
          - PUT
          - DELETE
          - OPTIONS
        accessControlAllowHeaders:
          - "*"
        accessControlAllowOriginList:
          - "*"
        accessControlMaxAge: 100
        addVaryHeader: true
    
    body-limit:
      buffering:
        maxRequestBodyBytes: 50000000
        maxResponseBodyBytes: 50000000
EOF
check_success "criar middlewares.yml"
echo ""

echo "6. Iniciando container Traefik..."
docker run -d \
  --name traefik \
  --restart unless-stopped \
  -p 80:80 \
  -p 443:443 \
  -p 8080:8080 \
  -v /opt/coolify/traefik/traefik.yml:/etc/traefik/traefik.yml:ro \
  -v /opt/coolify/traefik/dynamic:/etc/traefik/dynamic:ro \
  -v /opt/coolify/traefik/data:/data \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --network coolify \
  traefik:v3.0

check_success "iniciar container Traefik"
echo ""

echo "7. Aguardando Traefik inicializar..."
sleep 10
echo ""

echo "8. Verificando se Traefik está rodando..."
if docker ps | grep -q traefik; then
    echo "✅ Traefik está rodando"
    docker ps | grep traefik
else
    echo "❌ Traefik não está rodando"
    echo "Logs do container:"
    docker logs traefik
    exit 1
fi
echo ""

echo "9. Testando dashboard do Traefik..."
if curl -s http://localhost:8080/api/rawdata >/dev/null; then
    echo "✅ Dashboard do Traefik está acessível"
else
    echo "❌ Dashboard do Traefik não está acessível"
fi
echo ""

echo "=== CORREÇÃO CONCLUÍDA ==="
echo "Próximos passos:"
echo "1. Execute novamente os scripts de instalação dos serviços"
echo "2. Verifique se os arquivos de configuração dinâmica foram criados"
echo "3. Acesse o dashboard em http://SEU_IP:8080"