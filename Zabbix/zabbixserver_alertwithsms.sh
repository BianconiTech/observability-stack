#!/bin/bash

# ==== CONFIGURAÇÃO ====
CLIENT_ID="xxx@xxxxxx.com"
CLIENT_SECRET="xxxxx"
API_BASE="https://api.xxxxx.com"
LOG_FILE="/var/log/zabbix/sendsmsxxxxx.log"
DB_CMD="mysql -N -e"  # Substitua conforme seu banco (ex: sqlite3, psql, etc.)

# ==== PARÂMETROS ====
ORIGEM="$1"
DESTINO="$1"
TEXTO="$2:$3"

if [[ -z "$ORIGEM" || -z "$2" || -z "$3" ]]; then
  echo "Uso: $0 <telefone> <parte1> <parte2>" >&2
  exit 2
fi

# ==== CONTROLE DE ENVIO ====
ABORT_SEND=$($DB_CMD "SELECT COUNT(*) FROM mensagens_enviadas WHERE timestamp > NOW() - INTERVAL 10 MINUTE;" 2>/dev/null | awk 'NR==1')

if [[ "$ABORT_SEND" =~ ^[0-9]+$ ]] && [[ "$ABORT_SEND" -gt 15 ]]; then
  echo "$(date '+%F %T') | ABORTADO: limite de $ABORT_SEND mensagens em 10 minutos." | tee -a "$LOG_FILE"
  exit 0
fi

# ==== OBTENDO ACCESS_TOKEN ====
response_token=$(curl -s -X POST "${API_BASE}/request_token" \
  --data-urlencode "client_id=${CLIENT_ID}" \
  --data-urlencode "client_secret=${CLIENT_SECRET}")

access_token=$(echo "$response_token" | jq -r '.access_token')

if [[ -z "$access_token" || "$access_token" == "null" ]]; then
  echo "$(date '+%F %T') | ERRO ao obter access_token: $response_token" | tee -a "$LOG_FILE"
  exit 1
fi

echo "$(date '+%F %T') | Access_token obtido com sucesso." | tee -a "$LOG_FILE"

# ==== ENVIO DO SMS ====
response_sms=$(curl -s -X POST "${API_BASE}/sms/send" \
  --data-urlencode "access_token=${access_token}" \
  --data-urlencode "origem=${ORIGEM}" \
  --data-urlencode "destino=${DESTINO}" \
  --data-urlencode "texto=${TEXTO}" \
  --data-urlencode "tipo=texto")

# ==== TRATAMENTO DE RESPOSTA ====
msg=$(echo "$response_sms" | jq -r '.msg // .message // "Mensagem não encontrada"')

echo "$(date '+%F %T') | Resposta API: ${msg}" | tee -a "$LOG_FILE"
echo "$(date '+%F %T') | RAW: $response_sms" >> "$LOG_FILE"

# ==== GRAVAÇÃO OPCIONAL NO BANCO (se necessário) ====
# $DB_CMD "INSERT INTO mensagens_enviadas (numero, texto) VALUES ('$DESTINO', '$TEXTO');"
