#!/usr/bin/env bash

create_ipsec_server(){
    set_defaults_ipsec

    while true;do
        set_conn
        if [[ -f "${conn_file}" ]];then
            echo "Instância já existe"
        else
            touch "${conn_file}"
            break
        fi
    done

    set_key_time_features
    set_left

    ask_user "Deseja usar um certificado [sn]" answer

    if [[ "${answer}" == "s" ]];then
        // create_cert
        flag_cert="y"
        authby=rsa
        leftcert=certname
    else
        set_left_subnet
        authby=secret
        set_key_psk
    fi

    if [[ ${flag_cert} == "s" ]];then
        righ=any
    else
        set_right
        set_right_subnet
        authby=secret
    fi
    set_ike
    set_esp
    set_auto
    set_keyexchange
    write_to_file_config

    ask_user "Deseja gerar uma configuração para o cliente [sn]" answer

    if [[ "${answer}" == "s" ]];then
        write_other_side_config
    fi
}

set_defaults_ipsec(){
    conn=test
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyingtries=3
    left=
    flag_cert="n"
    leftcert=test.pem
    leftid=
    leftsubnet=
    right=
    rightsubnet=
    ike=aes128-sha256-modp1024
    esp=aes128-sha256-modp1024
    auto=start
    authby=secret
    keyexchange=ike
    key_psk=" "
    instance_dir="/etc/ipsec.d/instances"
    secrets_file="/etc/ipsec.secrets"
    conn_file="${instance_dir}"/"${conn}".conf
    conn_client_file=
    conn_client_secrets=
}

set_conn(){
    ask_user "Informe o nome da conn [${conn}]" conn
    conn_file="${instance_dir}"/"${conn}".conf
}

set_key_time_features(){
    ask_user "Informe ikelifetime [${ikelifetime}]" ikelifetime
    ask_user "Informe keylife [${keylife}]" ikelifetime
    ask_user "Informe rekeymargin [${rekeymargin}]" rekeymargin
    ask_user "Informe keyingtries [${keyingtries}]" keyingtries
}

set_left(){
    ask_user "Informe o endereço IP do seu servidor [${left}]" left
}

set_left_subnet(){
    ask_user "Informe o endereço da rede a ser negociada do seu lado [ex. 192.168.1.0/24]" leftsubnet
}

set_key_psk(){
    ask_user "Informe a chave PSK [${key_psk}]" key_psk
}

set_right(){
    ask_user "Informe o endereço do outro lado [${right}]" right
}

set_right_subnet(){
    ask_user "Informe o enderço da rede negociada [ex. 192.168.2.0/24]" rightsubnet
}

set_ike(){
    ask_user "Informe o algorítimo de criptografia ike [${ike}]" ike
}

set_esp(){
    ask_user "Informe o algorítimo de criptografia esp [${esp}]" esp
}

set_auto(){
    ask_user "Informe o valor de auto [${auto}]" auto
}

set_keyexchange(){
    ask_user "Informe keyexchange [${keyexchange}]" keyexchange
}

write_to_file_config(){
    echo "conn ${conn}" >> "${conn_file}"
    echo "  ikelifetime = ${ikelifetime}" >> "${conn_file}"
    echo "  keylife = ${keylife}" >> "${conn_file}"
    echo "  rekeymargin = ${rekeymargin}" >> "${conn_file}"
    echo "  keyingtries = ${keyingtries}" >> "${conn_file}"
    echo "  left = ${left}" >> "${conn_file}"

    if [[ ${flag_cert} == "s" ]];then
        echo "  ${leftcert}" >> "${conn_file}"
    else
        echo "  leftsubnet = ${leftsubnet}" >> "${conn_file}"
        echo "  authby = ${authby}" >> "${conn_file}"
    fi

    if [[ "${right}" != "any" ]];then
        echo "  right = ${right}" >> "${conn_file}"
        echo "  rightsubnet = ${rightsubnet}" >> "${conn_file}"
    fi

    echo "  ike=${ike}" >> "${conn_file}"
    echo "  esp=${esp}" >> "${conn_file}"

    echo "  auto=${auto}" >> "${conn_file}"

    echo "  keyexchange = ${keyexchange}" >> "${conn_file}"

    echo "${left} ${right} : PSK \"${key_psk}\"" >> "${secrets_file}"
}

write_other_side_config(){
    conn_client="${conn}_client"
    conn_client_file="${instance_dir}"/clients_config/"${conn_client}".conf
    conn_client_secrets="${instance_dir}"/clients_config/"${conn_client}".secrets

    echo "conn ${conn_client}" >> "${conn_client_file}"
    echo "  ikelifetime = ${ikelifetime}" >> "${conn_client_file}"
    echo "  keylife = ${keylife}" >> "${conn_client_file}"
    echo "  rekeymargin = ${rekeymargin}" >> "${conn_client_file}"
    echo "  keyingtries = ${keyingtries}" >> "${conn_client_file}"
    echo "  left = ${right}" >> "${conn_client_file}"
    echo "  leftsubnet = ${rightsubnet}" >> "${conn_client_file}"
    echo "  authby = ${authby}" >> "${conn_client_file}"
    echo "  right = ${left}" >> "${conn_client_file}"
    echo "  rightsubnet = ${leftsubnet}" >> "${conn_client_file}"
    echo "  auto = ${auto}" >> "${conn_client_file}"
    echo "  keyexchange = ${keyexchange}" >> "${conn_client_file}"
    echo "${right} ${left} : PSK \"${key_psk}\"" >> "${conn_client_secrets}"
}