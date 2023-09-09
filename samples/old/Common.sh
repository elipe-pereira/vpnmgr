#!/usr/bin/env bash

load_conf(){
    source "${VPNMGR_BASEPATH}/conf/vpnmgr/openvpn/openvpn.conf"
}

ask_user (){
    echo -n  "${1}: "
    read  answer

    if [[ -n "${answer}" ]]; then
        eval ${2}=\"${answer}\"
        debug "${2}"
    fi
}

debug (){
    if [[ ${debug} == "y" ]];then
        echo
        echo "Variável: ${1}"
        echo "Valor Informado: ${!1}"
        echo
    fi
}

test_if_instance_exists(){
    base_instance_ca="${base_openvpn}"/server/"${instance_ca}"
    debug base_instance_ca

    if [[ -d "${base_instance_ca}" ]];then
        return 0
    else
        return 1
    fi
}

set_base_instance_ca (){
    base_instance_ca="${base_openvpn}"/server/"${instance_ca}"
    debug base_instance_ca
}