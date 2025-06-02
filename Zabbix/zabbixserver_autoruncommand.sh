#!/bin/bash

# Parâmetro 1 = IP do host passado pelo Zabbix server
HOST_IP="$1"

# Usuário SSH
SSH_USER="zabbix"

# Caminho para chave privada (caso use chave SSH) ou remova o -i se autenticar por senha
SSH_KEY="/caminho/para/chave"

# Exemplo, comando para subir a aplicação Freeswitch
COMMAND="/usr/local/freeswitch/bin/freeswitch -nonat -hp -nc"

# Opções de SSH que podem facilitar scripts automatizados
SSH_OPTIONS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

# Execução remota do comando via SSH pelo servidor zabbix
ssh $SSH_OPTIONS -i "$SSH_KEY" $SSH_USER@"$HOST_IP" "$COMMAND"

# Fim do script
exit 0