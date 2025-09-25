# Instalador Whaticket SaaS

```bash
sudo apt -y update && apt -y upgrade
```

FAZENDO DOWNLOAD DO INSTALADOR & INICIANDO A PRIMEIRA INSTALAÇÃO (USAR SOMENTE PARA PRIMEIRA INSTALAÇÃO):

```bash
sudo apt install -y git && git clone https://github.com/eudanielhenrique/instalador.git instalador && sudo chmod -R 777 instalador  && cd instalador  && sudo ./install_primaria
```

ACESSANDO DIRETORIO DO INSTALADOR & INICIANDO INSTALAÇÕES ADICIONAIS (USAR ESTE COMANDO PARA SEGUNDA OU MAIS INSTALAÇÃO:

```bash
cd instalador  && sudo ./install_instancia
```

## Requisitos

| --- | Mínimo | Recomendado |
| --- | --- | --- |
| Node JS | 20.x | 20.x |
| Ubuntu | 20.x | 22.x |
| Memória RAM | 4Gb | 8Gb |  
