#!/bin/bash
# 
# system management

#######################################
# creates user
# Arguments:
#   None
#######################################
system_create_user() {
  print_banner
  printf "${WHITE} 💻 Agora, vamos criar o usuário para a instancia...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
  
  sudo apt update

  sleep 2

  sudo su - root <<EOF
# Cria o usuário 'deploy' com sua pasta home, shell padrão e o adiciona ao grupo 'sudo'.
useradd -m -s /bin/bash -G sudo deploy

# Define a senha para o usuário 'deploy' usando o valor da variável 'mysql_root_password'.
# Este método é mais confiável para scripts.
echo "deploy:${mysql_root_password}" | chpasswd
EOF

  sleep 2
}
#######################################
# clones repostories using git
# Arguments:
#   None
#######################################
system_git_clone() {
  print_banner
  printf "${WHITE} 💻 Fazendo download do código Whaticket...${GRAY_LIGHT}"
  printf "\n\n"


  sleep 2

  sudo su - deploy <<EOF
  git clone ${link_git} /home/deploy/${instancia_add}/
EOF

  sleep 2
}

#######################################
# updates system
# Arguments:
#   None
#######################################
system_update() {
  print_banner
  printf "${WHITE} 💻 Vamos atualizar o sistema Whaticket...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt -y update
  sudo apt-get install -y libxshmfence-dev libgbm-dev wget unzip fontconfig locales gconf-service libasound2 libatk1.0-0 libc6 libcairo2 libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgcc1 libgconf-2-4 libgdk-pixbuf2.0-0 libglib2.0-0 libgtk-3-0 libnspr4 libpango-1.0-0 libpangocairo-1.0-0 libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 libxss1 libxtst6 ca-certificates fonts-liberation libappindicator1 libnss3 lsb-release xdg-utils
EOF

  sleep 2
}



#######################################
# delete system
# Arguments:
#   None
#######################################
deletar_tudo() {
  print_banner
  printf "${WHITE} 💻 Vamos deletar o Whaticket...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  docker container rm redis-${empresa_delete} --force
  # Remove Traefik labels and configurations for the deleted instance
  docker network rm ${empresa_delete}-network 2>/dev/null || true
  rm -rf /opt/coolify/traefik/dynamic/${empresa_delete}-*.yml 2>/dev/null || true
  
  sleep 2

  sudo su - postgres
  dropuser ${empresa_delete}
  dropdb ${empresa_delete}
  exit
EOF

sleep 2

sudo su - deploy <<EOF
 rm -rf /home/deploy/${empresa_delete}
 pm2 delete ${empresa_delete}-frontend ${empresa_delete}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Remoção da Instancia/Empresa ${empresa_delete} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"


  sleep 2

}

#######################################
# bloquear system
# Arguments:
#   None
#######################################
configurar_bloqueio() {
  print_banner
  printf "${WHITE} 💻 Vamos bloquear o Whaticket...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - deploy <<EOF
 pm2 stop ${empresa_bloquear}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Bloqueio da Instancia/Empresa ${empresa_bloquear} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}


#######################################
# desbloquear system
# Arguments:
#   None
#######################################
configurar_desbloqueio() {
  print_banner
  printf "${WHITE} 💻 Vamos Desbloquear o Whaticket...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - deploy <<EOF
 pm2 start ${empresa_bloquear}-backend
 pm2 save
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Desbloqueio da Instancia/Empresa ${empresa_desbloquear} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}

#######################################
# alter dominio system
# Arguments:
#   None
#######################################
configurar_dominio() {
  print_banner
  printf "${WHITE} 💻 Vamos Alterar os Dominios do Whaticket...${GRAY_LIGHT}"
  printf "\n\n"

sleep 2

  sudo su - root <<EOF
  # Remove old Traefik configurations for domain change
  rm -rf /opt/coolify/traefik/dynamic/${empresa_dominio}-*.yml 2>/dev/null || true
EOF

sleep 2

  sudo su - deploy <<EOF
  cd && cd /home/deploy/${empresa_dominio}/frontend
  sed -i "1c\REACT_APP_BACKEND_URL=https://${alter_backend_url}" .env
  cd && cd /home/deploy/${empresa_dominio}/backend
  sed -i "2c\BACKEND_URL=https://${alter_backend_url}" .env
  sed -i "3c\FRONTEND_URL=https://${alter_frontend_url}" .env 
EOF

sleep 2
   
   backend_hostname=$(echo "${alter_backend_url/https:\/\/}")
   frontend_hostname=$(echo "${alter_frontend_url/https:\/\/}")

 sudo su - root <<EOF
  # Create Traefik dynamic configuration for backend
  mkdir -p /opt/coolify/traefik/dynamic
  cat > /opt/coolify/traefik/dynamic/${empresa_dominio}-backend.yml << 'END'
http:
  routers:
    ${empresa_dominio}-backend:
      rule: "Host(\`$backend_hostname\`)"
      service: "${empresa_dominio}-backend"
      tls:
        certResolver: "letsencrypt"
  services:
    ${empresa_dominio}-backend:
      loadBalancer:
        servers:
          - url: "http://127.0.0.1:${alter_backend_port}"
END

  # Create Traefik dynamic configuration for frontend
  cat > /opt/coolify/traefik/dynamic/${empresa_dominio}-frontend.yml << 'END'
http:
  routers:
    ${empresa_dominio}-frontend:
      rule: "Host(\`$frontend_hostname\`)"
      service: "${empresa_dominio}-frontend"
      tls:
        certResolver: "letsencrypt"
  services:
    ${empresa_dominio}-frontend:
      loadBalancer:
        servers:
          - url: "http://127.0.0.1:${alter_frontend_port}"
END

  # Restart Traefik to apply new configurations
  docker restart traefik 2>/dev/null || echo "Traefik container not found, configurations will be applied when Traefik starts"
EOF

  sleep 2

  print_banner
  printf "${WHITE} 💻 Alteração de dominio da Instancia/Empresa ${empresa_dominio} realizado com sucesso ...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2
}

#######################################
# installs node
# Arguments:
#   None
#######################################
system_node_install() {
  print_banner
  printf "${WHITE} 💻 Instalando nodejs...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  apt-get install -y nodejs
  sleep 2
  npm install -g npm@latest
  sleep 2
  sudo install -d /usr/share/postgresql-common/pgdg
  sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc
  . /etc/os-release
  sudo sh -c "echo 'deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $VERSION_CODENAME-pgdg main' > /etc/apt/sources.list.d/pgdg.list"
  sudo apt update
  sudo apt -y install postgresql
  sleep 2
  sudo timedatectl set-timezone America/Sao_Paulo
  
EOF

  sleep 2
}
#######################################
# installs docker
# Arguments:
#   None
#######################################
system_docker_install() {
  print_banner
  printf "${WHITE} 💻 Verificando e instalando Docker...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  # Verifica se o Docker já está instalado
  if command -v docker &>/dev/null; then
    echo -e "${GREEN} Docker já está instalado.${NC}"
  else
    echo -e "${WHITE} Instalando pré-requisitos e adicionando repositório Docker (método moderno)...${NC}"
    # O 'sudo' aqui é usado fora do heredoc, mas cada comando dentro é 'sudo'ificado
    sudo apt update
    sudo apt install -y ca-certificates curl gnupg lsb-release

    # Adiciona a chave GPG oficial do Docker de forma segura
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    # Adiciona o repositório Docker para a versão correta do Ubuntu (dinâmico)
    echo -e \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    echo -e "${WHITE} Atualizando índices de pacotes e instalando Docker CE e componentes...${NC}"
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # Adiciona o usuário atual ao grupo 'docker' para rodar comandos sem sudo
    sudo usermod -aG docker "$USER"
    echo -e "${GREEN} Docker instalado com sucesso! Por favor, faça logout e login novamente para que as alterações do grupo 'docker' tenham efeito, ou execute 'newgrp docker'.${NC}"
  fi
  sleep 2 # Pequeno atraso após a instalação do Docker
}
#######################################
# Ask for file location containing
# multiple URL for streaming.
# Globals:
#   WHITE
#   GRAY_LIGHT
#   BATCH_DIR
#   PROJECT_ROOT
# Arguments:
#   None
#######################################
system_puppeteer_dependencies() {
  print_banner
  printf "${WHITE} 💻 Instalando puppeteer dependencies...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt-get install -y libxshmfence-dev \
                      libgbm-dev \
                      wget \
                      unzip \
                      fontconfig \
                      locales \
                      gconf-service \
                      libasound2 \
                      libatk1.0-0 \
                      libc6 \
                      libcairo2 \
                      libcups2 \
                      libdbus-1-3 \
                      libexpat1 \
                      libfontconfig1 \
                      libgcc1 \
                      libgconf-2-4 \
                      libgdk-pixbuf2.0-0 \
                      libglib2.0-0 \
                      libgtk-3-0 \
                      libnspr4 \
                      libpango-1.0-0 \
                      libpangocairo-1.0-0 \
                      libstdc++6 \
                      libx11-6 \
                      libx11-xcb1 \
                      libxcb1 \
                      libxcomposite1 \
                      libxcursor1 \
                      libxdamage1 \
                      libxext6 \
                      libxfixes3 \
                      libxi6 \
                      libxrandr2 \
                      libxrender1 \
                      libxss1 \
                      libxtst6 \
                      ca-certificates \
                      fonts-liberation \
                      libappindicator1 \
                      libnss3 \
                      lsb-release \
                      xdg-utils
EOF

  sleep 2
}

#######################################
# installs pm2
# Arguments:
#   None
#######################################
system_pm2_install() {
  print_banner
  printf "${WHITE} 💻 Instalando pm2...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  npm install -g pm2

EOF

  sleep 2
}

#######################################
# installs snapd
# Arguments:
#   None
#######################################
system_snapd_install() {
  print_banner
  printf "${WHITE} 💻 Instalando snapd...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  apt install -y snapd
  snap install core
  snap refresh core
EOF

  sleep 2
}

#######################################
# installs traefik (Coolify)
# Arguments:
#   None
#######################################
system_traefik_install() {
  print_banner
  printf "${WHITE} 💻 Instalando Traefik (Coolify)...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  # Create Traefik directories
  mkdir -p /opt/coolify/traefik/dynamic
  mkdir -p /opt/coolify/traefik/data
  
  # Create Traefik network
  docker network create traefik-network 2>/dev/null || true
  
  # Create Traefik configuration
  cat > /opt/coolify/traefik/traefik.yml << 'END'
api:
  dashboard: true
  insecure: false

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entrypoint:
          to: websecure
          scheme: https
  websecure:
    address: ":443"

providers:
  file:
    directory: /etc/traefik/dynamic
    watch: true

certificatesResolvers:
  letsencrypt:
    acme:
      email: ${deploy_email}
      storage: /data/acme.json
      httpChallenge:
        entryPoint: web
END

  # Set proper permissions
  chmod 600 /opt/coolify/traefik/data/acme.json 2>/dev/null || touch /opt/coolify/traefik/data/acme.json && chmod 600 /opt/coolify/traefik/data/acme.json
EOF

  sleep 2
}

#######################################
# starts traefik container
# Arguments:
#   None
#######################################
system_traefik_start() {
  print_banner
  printf "${WHITE} 💻 Iniciando container Traefik...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  # Start Traefik container
  docker run -d \
    --name traefik \
    --restart unless-stopped \
    --network traefik-network \
    -p 80:80 \
    -p 443:443 \
    -p 8080:8080 \
    -v /opt/coolify/traefik/traefik.yml:/etc/traefik/traefik.yml:ro \
    -v /opt/coolify/traefik/dynamic:/etc/traefik/dynamic:ro \
    -v /opt/coolify/traefik/data:/data \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    traefik:v3.0
EOF

  sleep 2
}

#######################################
# restarts traefik
# Arguments:
#   None
#######################################
system_traefik_restart() {
  print_banner
  printf "${WHITE} 💻 Reiniciando Traefik...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  sudo su - root <<EOF
  docker restart traefik 2>/dev/null || echo "Traefik container not found"
EOF

  sleep 2
}

#######################################
# setup for traefik middleware
# Arguments:
#   None
#######################################
system_traefik_conf() {
  print_banner
  printf "${WHITE} 💻 Configurando middlewares do Traefik...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

sudo su - root << EOF

cat > /opt/coolify/traefik/dynamic/middlewares.yml << 'END'
http:
  middlewares:
    default-headers:
      headers:
        frameDeny: true
        sslRedirect: true
        browserXssFilter: true
        contentTypeNosniff: true
        forceSTSHeader: true
        stsIncludeSubdomains: true
        stsPreload: true
        stsSeconds: 31536000
        customRequestHeaders:
          X-Forwarded-Proto: "https"
    
    secure-headers:
      headers:
        accessControlAllowMethods:
          - GET
          - OPTIONS
          - PUT
          - POST
          - DELETE
        accessControlMaxAge: 100
        hostsProxyHeaders:
          - "X-Forwarded-Host"
        referrerPolicy: "same-origin"
    
    body-limit:
      buffering:
        maxRequestBodyBytes: 104857600  # 100MB
END

EOF

  sleep 2
}

#######################################
# setup traefik and verify configuration
# Arguments:
#   None
#######################################
system_traefik_setup() {
  print_banner
  printf "${WHITE} 💻 Verificando configuração do Traefik...${GRAY_LIGHT}"
  printf "\n\n"

  sleep 2

  backend_domain=$(echo "${backend_url/https:\/\/}")
  frontend_domain=$(echo "${frontend_url/https:\/\/}")

  sudo su - root <<EOF
  # Verify Traefik is running
  if ! docker ps | grep -q traefik; then
    echo "Traefik container not running, starting it..."
    docker start traefik 2>/dev/null || echo "Failed to start Traefik container"
  fi
  
  # Check if domains are configured
  echo "Domains configured for SSL: $backend_domain, $frontend_domain"
  echo "Traefik will automatically generate SSL certificates via Let's Encrypt"
  
  # Verify configuration files exist
  ls -la /opt/coolify/traefik/dynamic/ || echo "Dynamic configuration directory not found"
EOF

  sleep 2
}
