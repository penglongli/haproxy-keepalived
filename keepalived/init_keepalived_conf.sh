#!/bin/bash
set -e

TEMPLATE="/keepalived/keepalived_template.conf"
TMP_TEMPLATE="/tmp/keepalived/tmp_keepalived_template.conf"
KEEPALIVED_FILE="/etc/keepalived/keepalived.conf"

# mkdir to prevent not exist
mkdir -p /tmp/keepalived/
mkdir -p /etc/keepalived/

# copy template to /tmp/keepalived/tmp_keepalived_template.conf
cp ${TEMPLATE} ${TMP_TEMPLATE}

envsubst < ${TMP_TEMPLATE} > ${KEEPALIVED_FILE}
echo "Success generate ${KEEPALIVED_FILE}"
echo "----------------------keepalived.conf----------------------"
cat ${KEEPALIVED_FILE}
echo "--------------------------- End ---------------------------"

