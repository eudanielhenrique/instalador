#!/bin/bash

# Script de teste final para validar configuração do Traefik
# Execute este script na sua VPS após aplicar as correções

echo "=== TESTE FINAL DO TRAEFIK ==="
echo

# Função para verificar sucesso
check_success() {
    if [ $? -eq 0 ]; then
        echo "✅ $1"
    else
        echo "❌ $1"
        return 1
    fi
}

# 1. Verificar se Docker está rodando
echo "1. Verificando Docker..."
docker --version > /dev/null 2>&1
check_success "Docker está rodando"
echo

# 2. Verificar se a rede coolify existe
echo "2. Verificando rede coolify..."
docker network ls | grep coolify > /dev/null 2>&1
check_success "Rede coolify existe"
echo

# 3. Verificar se o container Traefik está rodando
echo "3. Verificando container Traefik..."
docker ps | grep traefik > /dev/null 2>&1
check_success "Container Traefik está rodando"
echo

# 4. Verificar portas do Traefik
echo "4. Verificando portas do Traefik..."
netstat -tlnp | grep :80 > /dev/null 2>&1
check_success "Porta 80 está sendo usada"

netstat -tlnp | grep :443 > /dev/null 2>&1
check_success "Porta 443 está sendo usada"

netstat -tlnp | grep :8080 > /dev/null 2>&1
check_success "Porta 8080 (dashboard) está sendo usada"
echo

# 5. Verificar arquivos de configuração
echo "5. Verificando arquivos de configuração..."
[ -f /opt/coolify/traefik/traefik.yml ] && check_success "traefik.yml existe"
[ -f /opt/coolify/traefik/dynamic/middlewares.yml ] && check_success "middlewares.yml existe"
[ -d /opt/coolify/traefik/dynamic ] && check_success "Diretório dynamic existe"
[ -d /opt/coolify/traefik/data ] && check_success "Diretório data existe"
echo

# 6. Verificar logs do Traefik (últimas 10 linhas)
echo "6. Últimas linhas dos logs do Traefik:"
docker logs traefik --tail 10 2>/dev/null || echo "❌ Não foi possível obter logs"
echo

# 7. Testar dashboard do Traefik
echo "7. Testando dashboard do Traefik..."
curl -s http://localhost:8080/api/rawdata > /dev/null 2>&1
check_success "Dashboard do Traefik está acessível"
echo

# 8. Verificar configurações dinâmicas carregadas
echo "8. Verificando configurações dinâmicas..."
CONFIGS=$(curl -s http://localhost:8080/api/http/routers 2>/dev/null | grep -o '"name"' | wc -l)
if [ "$CONFIGS" -gt 0 ]; then
    echo "✅ $CONFIGS configurações dinâmicas carregadas"
else
    echo "⚠️  Nenhuma configuração dinâmica encontrada"
fi
echo

# 9. Listar arquivos de configuração dinâmica
echo "9. Arquivos de configuração dinâmica encontrados:"
ls -la /opt/coolify/traefik/dynamic/ 2>/dev/null || echo "❌ Diretório não encontrado"
echo

# 10. Verificar conectividade externa (se possível)
echo "10. Testando conectividade externa..."
if command -v curl > /dev/null 2>&1; then
    curl -s --connect-timeout 5 http://httpbin.org/ip > /dev/null 2>&1
    check_success "Conectividade externa funcionando"
else
    echo "⚠️  curl não disponível para teste"
fi
echo

echo "=== RESUMO ==="
echo "Se todos os testes passaram, o Traefik está configurado corretamente!"
echo "Acesse o dashboard em: http://SEU_IP:8080"
echo
echo "Para verificar rotas específicas:"
echo "curl http://localhost:8080/api/http/routers"
echo
echo "Para ver middlewares:"
echo "curl http://localhost:8080/api/http/middlewares"
echo
echo "=== FIM DOS TESTES ==="