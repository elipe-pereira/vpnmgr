#!/bin/bash
ROOT_SERVER="default"
DEBUG="y"
EASY_RSA="${VPNMGR_BASEPATH}/app/lib/easy-rsa"
CLIENT_NAME=

echo -n "Informe o nome do certificado raiz: "
read -r value

if [ -n "${value}" ];then
	ROOT_SERVER=${value}

	if [ ${DEBUG} == "y" ];then
		echo "${ROOT_SERVER}"
	fi	
fi

test -d "${EASY_RSA}/${ROOT_SERVER}" || exit 1

source "${EASY_RSA}"/"${ROOT_SERVER}"/vars-"${ROOT_SERVER}"

echo -n "Informe o nome do certificado: "
read -r value

if [ -n "${value}" ];then
	CLIENT_NAME=${value}

	if [ "${DEBUG}" == "y" ];then
		echo "${CLIENT_NAME}"
	fi
fi

"${EASY_RSA}"/build-key "${CLIENT_NAME}"
