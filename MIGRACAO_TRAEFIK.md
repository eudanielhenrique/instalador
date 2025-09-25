# Migração de Nginx+Certbot para Traefik (Coolify)

## Resumo das Mudanças

Este documento descreve as mudanças realizadas para migrar o sistema de proxy reverso de Nginx+Certbot para Traefik (Coolify).

## Arquivos Modificados

### 1. _system.sh
**Funções substituídas:**
- `system_certbot_install` → `system_traefik_install`
- `system_nginx_install` → `system_traefik_start`
- `system_nginx_restart` → `system_traefik_restart`
- `system_nginx_conf` → `system_traefik_conf`
- `system_certbot_setup` → `system_traefik_setup`

**Principais mudanças:**
- Criação de diretórios Traefik em `/opt/coolify/traefik/`
- Configuração de rede Docker `coolify`
- Arquivo de configuração `traefik.yml` com Let's Encrypt
- Middlewares para segurança e CORS
- Limpeza de instâncias agora remove arquivos Traefik

### 2. _backend.sh
**Funções substituídas:**
- `backend_nginx_setup` → `backend_traefik_setup`

**Principais mudanças:**
- Criação de arquivos de configuração dinâmica YAML para Traefik
- Configuração de roteamento baseado em host
- Configuração automática de TLS com Let's Encrypt
- Aplicação de middlewares de segurança

### 3. _frontend.sh
**Funções substituídas:**
- `frontend_nginx_setup` → `frontend_traefik_setup`

**Principais mudanças:**
- Criação de arquivos de configuração dinâmica YAML para Traefik
- Configuração de roteamento baseado em host
- Configuração automática de TLS com Let's Encrypt
- Aplicação de middlewares de segurança

### 4. install_primaria
**Chamadas de função atualizadas:**
- `system_nginx_install` → `system_traefik_install`
- `system_certbot_install` → `system_traefik_start`
- `backend_nginx_setup` → `backend_traefik_setup`
- `frontend_nginx_setup` → `frontend_traefik_setup`
- `system_nginx_conf` → `system_traefik_conf`
- `system_nginx_restart` → `system_traefik_restart`
- `system_certbot_setup` → `system_traefik_setup`

### 5. install_instancia
**Chamadas de função atualizadas:**
- `system_nginx_install` → `system_traefik_install`
- `system_certbot_install` → `system_traefik_start`
- `system_nginx_conf` → `system_traefik_conf`
- `backend_nginx_setup` → `backend_traefik_setup`
- `frontend_nginx_setup` → `frontend_traefik_setup`
- `system_nginx_restart` → `system_traefik_restart`
- `system_certbot_setup` → `system_traefik_setup`

## Estrutura de Arquivos Traefik

```
/opt/coolify/traefik/
├── traefik.yml                 # Configuração principal
├── dynamic/
│   ├── middlewares.yml         # Middlewares globais
│   ├── backend-{domain}.yml    # Configuração do backend
│   └── frontend-{domain}.yml   # Configuração do frontend
```

## Configurações Importantes

### Rede Docker
- Nome: `coolify`
- Tipo: bridge

### Portas Expostas
- 80 (HTTP)
- 443 (HTTPS)
- 8080 (Dashboard Traefik)

### Middlewares Configurados
- **security-headers**: Headers de segurança
- **cors-headers**: Configuração CORS
- **body-limit**: Limite de tamanho do corpo (100MB)

### Certificados SSL
- Provedor: Let's Encrypt
- Email: configurado via variável de ambiente
- Renovação automática

## Benefícios da Migração

1. **Configuração Dinâmica**: Traefik recarrega configurações automaticamente
2. **Integração Docker**: Melhor integração com containers
3. **Dashboard**: Interface web para monitoramento
4. **Certificados Automáticos**: Renovação automática via Let's Encrypt
5. **Middlewares**: Sistema flexível de middlewares
6. **Service Discovery**: Descoberta automática de serviços

## Comandos Úteis

### Verificar status do Traefik
```bash
docker ps | grep traefik
```

### Ver logs do Traefik
```bash
docker logs traefik
```

### Reiniciar Traefik
```bash
docker restart traefik
```

### Verificar configurações dinâmicas
```bash
ls -la /opt/coolify/traefik/dynamic/
```

## Notas de Manutenção

- As configurações dinâmicas são criadas automaticamente pelos scripts
- O Traefik monitora mudanças nos arquivos YAML e recarrega automaticamente
- Certificados SSL são renovados automaticamente
- O dashboard está disponível na porta 8080 (configurar acesso conforme necessário)