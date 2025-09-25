# Correções Realizadas no Traefik

## Problema Identificado
Após a migração do Nginx+Certbot para Traefik, a aplicação apresentava erro "no available server", indicando problemas de configuração e roteamento.

## Problemas Encontrados e Correções

### 1. Inconsistência na Rede Docker
**Problema:** O código estava criando e usando redes diferentes:
- Criava: `traefik-network`
- Usava: `coolify`

**Correção:** Padronizado para usar sempre a rede `coolify`
- Arquivo: `lib/_system.sh`
- Função: `system_traefik_install()` e `system_traefik_start()`

### 2. Dashboard Traefik Inacessível
**Problema:** Dashboard configurado como `insecure: false`, dificultando debug

**Correção:** Alterado para `insecure: true` para facilitar diagnóstico
- Arquivo: `lib/_system.sh`
- Função: `system_traefik_install()`

### 3. Redirecionamento HTTP Problemático
**Problema:** Redirecionamento automático de HTTP para HTTPS causando loops

**Correção:** Removido redirecionamento automático do entrypoint web
- Arquivo: `lib/_system.sh`
- Função: `system_traefik_install()`

### 4. Middlewares Inexistentes
**Problema:** Backend e frontend referenciavam middlewares não definidos:
- `default-headers`
- `secure-headers`
- `body-limit`

**Correção:** 
- Criados middlewares corretos: `security-headers`, `cors-headers`, `body-limit`
- Arquivo: `lib/_system.sh` - adicionado `middlewares.yml`
- Arquivos: `lib/_backend.sh` e `lib/_frontend.sh` - atualizadas referências

### 5. Health Checks Problemáticos
**Problema:** Health checks configurados para endpoints que podem não existir

**Correção:** Removidos health checks desnecessários dos serviços
- Arquivos: `lib/_backend.sh` e `lib/_frontend.sh`

### 6. Configurações Globais Ausentes
**Problema:** Faltavam configurações para desabilitar verificações desnecessárias

**Correção:** Adicionadas configurações globais:
```yaml
global:
  checkNewVersion: false
  sendAnonymousUsage: false
```

## Arquivos Modificados

### lib/_system.sh
- Corrigida rede de `traefik-network` para `coolify`
- Dashboard alterado para `insecure: true`
- Removido redirecionamento HTTP automático
- Adicionado arquivo `middlewares.yml`
- Adicionadas configurações globais

### lib/_backend.sh
- Middlewares atualizados para `security-headers`, `cors-headers`, `body-limit`
- Removido health check problemático

### lib/_frontend.sh
- Middlewares atualizados para `security-headers`, `cors-headers`
- Removido health check problemático

### Scripts de Diagnóstico e Correção
- `diagnostico_traefik.sh` - Script para diagnosticar problemas
- `corrigir_traefik.sh` - Script para aplicar correções automaticamente
- `testar_traefik.sh` - Script para validar configuração final

## Middlewares Criados

### security-headers
- Headers de segurança (X-Frame-Options, X-Content-Type-Options, etc.)
- HSTS (Strict-Transport-Security)
- Referrer Policy

### cors-headers
- Configurações CORS para APIs
- Métodos permitidos: GET, POST, PUT, DELETE, OPTIONS
- Headers permitidos: todos (*)
- Origins permitidos: todos (*) - ajustar conforme necessário

### body-limit
- Limite de 50MB para request e response bodies

## Como Aplicar as Correções na VPS

1. **Fazer backup das configurações atuais:**
   ```bash
   cp -r /opt/coolify/traefik /opt/coolify/traefik.backup
   ```

2. **Executar script de correção:**
   ```bash
   ./corrigir_traefik.sh
   ```

3. **Validar configuração:**
   ```bash
   ./testar_traefik.sh
   ```

4. **Verificar dashboard:**
   - Acesse: `http://SEU_IP:8080`
   - Verifique se routers e middlewares estão carregados

## Comandos Úteis para Debug

```bash
# Ver logs do Traefik
docker logs traefik -f

# Verificar routers carregados
curl http://localhost:8080/api/http/routers

# Verificar middlewares carregados
curl http://localhost:8080/api/http/middlewares

# Verificar serviços
curl http://localhost:8080/api/http/services

# Reiniciar Traefik
docker restart traefik
```

## Próximos Passos

1. Testar acesso aos domínios configurados
2. Verificar geração de certificados SSL
3. Ajustar CORS origins conforme necessário
4. Monitorar logs para identificar outros problemas

## Observações Importantes

- O dashboard está configurado como `insecure: true` para facilitar debug
- Em produção, considere configurar autenticação para o dashboard
- Os middlewares CORS estão permissivos (*) - ajuste conforme suas necessidades de segurança
- Certifique-se de que os serviços backend/frontend estão rodando nas portas corretas