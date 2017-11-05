#!/bin/bash

HAPROXY_DIR="/usr/local/etc/haproxy"
TMP_HAPROXY="/tmp/haproxy"

TMP_FILE="${TMP_HAPROXY}/tmp.cfg"
TMP_TEMPLATE="${TMP_HAPROXY}/template.cfg"

TEMPLATE_FILE="/haproxy/template.cfg"
HAPROXY_CFG="${HAPROXY_DIR}/haproxy.cfg"

# mkdir to prevent not exists
mkdir -p ${HAPROXY_DIR}
mkdir -p ${TMP_HAPROXY}
rm -rf ${HAPROXY_DIR}/haproxy.cfg

# delete old haproxy.cfg and touch tmp.cfg
rm -rf ${HAPROXY_CFG}
rm -rf ${TMP_FILE}
touch ${TMP_FILE}

# copy template.cfg to tmp dir
cp ${TEMPLATE_FILE} ${TMP_TEMPLATE}

COUNTER=1
while [ ${COUNTER} -gt 0 ]
do
    haproxy_item=$(printenv haproxy_item${COUNTER})

    if [ -z "${haproxy_item}" ]
    then
        break;
    fi

    # echo haproxy_item to /tmp/haproxy/tmp.cfg
    echo "\${haproxy_item${COUNTER}}" >> ${TMP_FILE}

    let COUNTER+=1
done
echo "Success generate tmp.cfg!"

sed -i "/#CUSTOM/r ${TMP_FILE}" ${TMP_TEMPLATE}
echo "Success generate template.cfg"

touch ${HAPROXY_CFG}
envsubst < ${TMP_TEMPLATE} > ${HAPROXY_CFG}

echo "Success generate haproxy.cfg, file content is below:"
echo "----------------haproxy.cfg------------------"
cat ${HAPROXY_CFG}
echo "------------------ End ----------------------"
