#!/bin/bash

echo "=== DIAGNÓSTICO TRAEFIK ==="
echo "Data: $(date)"
echo ""

echo "1. Verificando se o Docker está rodando..."
if ! docker info >/dev/null 2>&1; then
    echo "❌ Docker não está rodando!"
    exit 1
else
    echo "✅ Docker está rodando"
fi
echo ""

echo "2. Verificando containers em execução..."
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""

echo "3. Verificando especificamente o container Traefik..."
if docker ps | grep -q traefik; then
    echo "✅ Container Traefik está rodando"
    docker ps | grep traefik
else
    echo "❌ Container Traefik NÃO está rodando"
    echo "Tentando verificar se existe mas está parado..."
    docker ps -a | grep traefik
fi
echo ""

echo "4. Verificando logs do Traefik (últimas 20 linhas)..."
if docker ps | grep -q traefik; then
    docker logs --tail 20 traefik
else
    echo "❌ Não é possível verificar logs - container não está rodando"
fi
echo ""

echo "5. Verificando rede Docker 'coolify'..."
if docker network ls | grep -q coolify; then
    echo "✅ Rede 'coolify' existe"
    docker network inspect coolify --format '{{.Name}}: {{len .Containers}} containers conectados'
else
    echo "❌ Rede 'coolify' NÃO existe"
fi
echo ""

echo "6. Verificando arquivos de configuração do Traefik..."
if [ -f "/opt/coolify/traefik/traefik.yml" ]; then
    echo "✅ Arquivo traefik.yml existe"
    echo "Conteúdo:"
    cat /opt/coolify/traefik/traefik.yml
else
    echo "❌ Arquivo traefik.yml NÃO existe"
fi
echo ""

echo "7. Verificando configurações dinâmicas..."
if [ -d "/opt/coolify/traefik/dynamic" ]; then
    echo "✅ Diretório dynamic existe"
    echo "Arquivos encontrados:"
    ls -la /opt/coolify/traefik/dynamic/
    echo ""
    echo "Conteúdo dos arquivos:"
    for file in /opt/coolify/traefik/dynamic/*.yml; do
        if [ -f "$file" ]; then
            echo "--- $file ---"
            cat "$file"
            echo ""
        fi
    done
else
    echo "❌ Diretório dynamic NÃO existe"
fi
echo ""

echo "8. Verificando portas em uso..."
echo "Portas 80, 443 e 8080:"
netstat -tlnp | grep -E ':80 |:443 |:8080 ' || echo "Nenhuma das portas está em uso"
echo ""

echo "9. Verificando se os serviços backend/frontend estão rodando..."
echo "Containers que não são o Traefik:"
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -v traefik
echo ""

echo "10. Testando conectividade interna..."
if docker ps | grep -q traefik; then
    echo "Testando se o Traefik responde internamente:"
    docker exec traefik wget -qO- http://localhost:8080/api/rawdata 2>/dev/null | head -20 || echo "❌ Traefik não responde na porta 8080"
else
    echo "❌ Não é possível testar - container Traefik não está rodando"
fi
echo ""

echo "=== FIM DO DIAGNÓSTICO ==="