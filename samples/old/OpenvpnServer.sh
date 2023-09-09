#!/usr/bin/env bash

create_server_openvpn(){
    set_default_variables
    questions_to_create_ca_and_set_some_variables_about_ca
    set_instance_file_vars_configurations
    create_vars_instance_config
    load_instance_file_vars_configurations
    create_ca
    create_key_server
    create_key_client "${client_name}"
    create_dh_key
    test_if_exists_and_create_folder_ta
    test_if_exists_and_create_ta_key
    set_server_config_instance
    create_file_service_systemd
    create_log_files_instance_vpn
    enable_and_start_instance_vpn_service
    index_instances_ca
}

set_default_variables(){
    load_conf
    load_defaults_variables

    openvpn=$(command -v openvpn)

}

questions_to_create_ca_and_set_some_variables_about_ca(){
    # As informações solicitadas  nesta função
    # irão sobrescrever as variáveis default

    while true;do
        ask_user "Informe o nome da instância VPN [${instance_ca}]" instance_ca

        if test_if_instance_exists;then
            echo "Instância VPN já existe"
        else
            set_base_instance_ca
            break
        fi
    done

    create_folder_vars_instance_ca
    create_folder_base_instance_ca

    ask_user "Informe o tamanho da chave [${KEY_SIZE}]" KEY_SIZE
    ask_user "Informe a duração da ca em dias [${CA_EXPIRE}]" CA_EXPIRE

    set_key_expire

    ask_user "Informe a sigla do pais [${KEY_COUNTRY}]" KEY_COUNTRY
    ask_user "Informe a sigla do estado [${KEY_PROVINCE}]" KEY_PROVINCE
    ask_user "informe o nme da cidade [${KEY_CITY}]" KEY_CITY
    ask_user "Informe o nome da organização [${KEY_ORG}]" KEY_ORG
    ask_user "Informe o e-mail [${KEY_EMAIL}]" KEY_EMAIL
    ask_user "Informe  a unidade organizacional [${KEY_OU}]" KEY_OU
    ask_user "Informe o nome do servidor [${KEY_NAME}]" KEY_NAME
    ask_user "Certificado cliente para fins de teste [${client_name}]" client_name

    set_key_dir
}

set_instance_file_vars_configurations(){
    instance_file_vars_configurations="${EASY_RSA}/${instance_ca}/vars-${instance_ca}"
    debug instance_file_vars_configurations
}

create_vars_instance_config(){
    echo > "${instance_file_vars_configurations}"
    echo "export EASY_RSA=${EASY_RSA}
        export OPENSSL=openssl
        export PKCS11TOOL=pkcs11-tool
        export GREP=grep
        export KEY_CONFIG=\`${EASY_RSA}/whichopensslcnf ${EASY_RSA}\`
        export KEY_DIR=${KEY_DIR}
        export PKCS11_MODULE_PATH=dummy
        export PKCS11_PIN=dummy
        export KEY_SIZE=${KEY_SIZE}
        export CA_EXPIRE=${CA_EXPIRE}
        export KEY_EXPIRE=${KEY_EXPIRE}
        export KEY_COUNTRY=${KEY_COUNTRY}
        export KEY_PROVINCE=${KEY_PROVINCE}
        export KEY_CITY=${KEY_CITY}
        export KEY_ORG=${KEY_ORG}
        export KEY_EMAIL=${KEY_EMAIL}
        export KEY_OU=${KEY_OU}
        export KEY_NAME=${KEY_NAME}" >> "${instance_file_vars_configurations}"
}

load_instance_file_vars_configurations(){
    source "${instance_file_vars_configurations}" || exit 1
}

create_ca(){
    ${EASY_RSA}/clean-all
    ${EASY_RSA}/build-ca
}

create_key_server(){
    ${EASY_RSA}/build-key-server "${KEY_NAME}"
}

create_key_client(){
    ${EASY_RSA}/build-key "${1}"
}

create_dh_key(){
    ${EASY_RSA}/build-dh
}

test_if_exists_and_create_folder_ta(){
    test -d "${base_instance_ca}/ta" || mkdir -p "${base_instance_ca}/ta"
}

test_if_exists_and_create_ta_key(){
    test -f "${base_instance_ca}/ta/ta.key" || ${openvpn} --genkey --secret "${base_instance_ca}/ta/ta.key"
}

set_server_config_instance(){
    ask_user "Informe o Endereço IP do servidor [${ip_add}]" ip_addr

	while true;do
	    ask_user "Informe a porta do servidor: [${port}]" port
	    if test_port;then
	        break;
	    else
	        echo "Porta já está em uso"
	    fi
	done

	ask_user "Informe o protocolo [${proto}]" proto
    interface_vpn="tun-${instance_ca}"
	ask_user "Informe o nome da interface de rede [${interface_vpn}]" interface_vpn
	ask_user "Informe o nome da topologia [${topology}]" topology
    ask_user "Informe o range de IPs [${range_server}]" range_server

    echo -n "Deseja publicar alguma rota para os clientes ? [sn] "
    read -r answer

    if [[ ${answer} == "y" || ${answer} == "s" ]];then
        set_route_clients
    fi

    echo -n "Deseja criar alguma rota somente do servidor ? [sn]"
    read -r answer

    if [[ ${answer} == "y" || ${answer} == "s" ]];then
        set_route_servers
    fi

    echo -n "Deseja  publicar um servidor DNS diferente do padrao ? [sn] "
    read -r answer

    if [[ ${answer} == "y" || ${answer} == "s" ]];then
        set_dns_servers
    fi

    instance_ca_conf="${base_openvpn}/server/${instance_ca}.conf"
    ca="${KEY_DIR}/ca.crt"
    cert="${KEY_DIR}/${KEY_NAME}.crt"
    key="${KEY_DIR}/${KEY_NAME}.key"
    crl_verify="${KEY_DIR}/crl.pem"
    dh=${KEY_DIR}/dh${KEY_SIZE}.pem
    pool_persist="${instance_ca}/ipp-${instance_ca}.txt"
    tls_auth="${base_instance_ca}/ta/ta.key"
    status="/var/log/openvpn/openvpn-status-${instance_ca}.log"
    log_append="/var/log/openvpn/openvpn-${instance_ca}.log"

    touch "${base_instance_ca}/ipp-${instance_ca}.txt"

    ${EASY_RSA}/revoke-full "${client_name}"

    echo "#OpenVPN ${instance_ca}" >> "${instance_ca_conf}"
    echo "# Multi-client server" >> "${instance_ca_conf}"
    echo "# Endereco de escuta do servidor" >> "${instance_ca_conf}"
    echo "local ${ip_addr}" >> "${instance_ca_conf}"
    echo "proto ${proto}" >> "${instance_ca_conf}"
    echo "port ${port}" >> "${instance_ca_conf}"
    echo "dev ${interface_vpn}" >> "${instance_ca_conf}"
    echo "ca ${ca}" >> "${instance_ca_conf}"
    echo "cert ${cert}" >> "${instance_ca_conf}"
    echo "key ${key}" >> "${instance_ca_conf}"
    echo "dh ${dh}" >> "${instance_ca_conf}"
    echo "crl-verify ${crl_verify}" >> "${instance_ca_conf}"
    echo "topology ${topology}" >> "${instance_ca_conf}"
    echo "server ${range_server}" >> "${instance_ca_conf}"
    echo "ifconfig-pool-persist ${pool_persist}" >> "${instance_ca_conf}"

    counter=0
    while [[ ${counter} -lt ${#routes_clients[@]} ]];do
        echo   "push \" route ${routes_clients[${counter}]}\"" >> "${instance_ca_conf}"
        counter=$((counter + 1))
    done

    client_config_dir="${base_instance_ca}/ccd-${instance_ca}"
    mkdir -p "${client_config_dir}"
    echo "client-config-dir ${client_config_dir}" >> "${instance_ca_conf}"

    counter=0
    while [[ ${counter} -lt ${#routes_server[@]} ]];do
        echo "route ${routes_server[${counter}]}" >> "${instance_ca_conf}"
        counter=$((counter + 1))
    done

    counter=0
    while [[ ${counter} -lt ${#dns_server[@]} ]];do
        echo "push \"dhcp-option DNS ${dns_server[${counter}]}\"" >> "${instance_ca_conf}"
        counter=$((counter + 1))
    done

    echo "${keepalive}" >> "${instance_ca_conf}"
    echo "tls-auth ${tls_auth} 0" >> "${instance_ca_conf}"
    echo "${compress}" >> "${instance_ca_conf}"
    echo "${persist_key}" >> "${instance_ca_conf}"
    echo "${persist_tun}" >> "${instance_ca_conf}"
    echo "status ${status}" >> "${instance_ca_conf}"
    echo "log-append ${log_append}" >> "${instance_ca_conf}"
    echo "${verb}" >> "${instance_ca_conf}"
    echo "${notify}" >> "${instance_ca_conf}"
}

create_file_service_systemd(){
    systemd_file_openvpn_service="/lib/systemd/system/openvpn@${instance_ca}.service"

    echo > ${systemd_file_openvpn_service}

    echo "[Unit]" >> ${systemd_file_openvpn_service}
    echo "Description=OpenVPN connection to %i" >> ${systemd_file_openvpn_service}
    echo "PartOf=openvpn.service" >> ${systemd_file_openvpn_service}
    echo "ReloadPropagatedFrom=openvpn.service" >> ${systemd_file_openvpn_service}
    echo "Before=systemd-user-sessions.service" >> ${systemd_file_openvpn_service}
    echo "Documentation=man:openvpn(8)" >> ${systemd_file_openvpn_service}
    echo "Documentation=https://community.openvpn.net/openvpn/wiki/Openvpn23ManPage" >> ${systemd_file_openvpn_service}
    echo "Documentation=https://community.openvpn.net/openvpn/wiki/HOWTO" >> ${systemd_file_openvpn_service}
    echo "[Service]" >> ${systemd_file_openvpn_service}
    echo "PrivateTmp=true" >> ${systemd_file_openvpn_service}
    echo "KillMode=mixed" >> ${systemd_file_openvpn_service}
    echo "Type=forking"   >> ${systemd_file_openvpn_service}
    echo "ExecStart=/usr/sbin/openvpn --daemon server-%i --status /run/openvpn/%i.status 10 --cd /etc/openvpn --config /etc/openvpn/server/%i.conf --writepid /run/openvpn/%i.pid" >> ${systemd_file_openvpn_service}
    echo "PIDFile=/run/openvpn/%i.pid" >> ${systemd_file_openvpn_service}
    echo "ExecReload=/bin/kill -HUP $MAINPID" >> ${systemd_file_openvpn_service}
    echo "WorkingDirectory=/etc/openvpn" >> ${systemd_file_openvpn_service}
    echo "ProtectSystem=yes" >> ${systemd_file_openvpn_service}
    echo "CapabilityBoundingSet=caP_IPC_LOCK caP_NET_ADMIN caP_NET_BIND_SERVICE caP_NET_RAW caP_SETGID caP_SETUID caP_SYS_CHROOT caP_DAC_READ_SEARCH caP_AUDIT_WRITE" >> ${systemd_file_openvpn_service}
    echo "LimitNPROC=10" >> ${systemd_file_openvpn_service}
    echo "DeviceAllow=/dev/null rw" >> ${systemd_file_openvpn_service}
    echo "DeviceAllow=/dev/net/tun rw" >> ${systemd_file_openvpn_service}
    echo "[Install]" >> ${systemd_file_openvpn_service}
    echo "WantedBy=multi-user.target" >> ${systemd_file_openvpn_service}
}

create_log_files_instance_vpn(){
    touch "${status}"
    touch "${log_append}"
}

enable_and_start_instance_vpn_service(){
    systemctl enable openvpn@"${instance_ca}".service
    systemctl start openvpn@"${instance_ca}".service
}

index_instances_ca(){
    date_creation_ca=$(date +'%s')
    status="ativo"
    echo "${instance_ca}":${date_creation_ca}:"${status}" >> "${base_openvpn}"/index_instances.txt
}

load_defaults_variables(){
    source "/etc/vpnmgr/openvpn/defaults"
}

create_folder_vars_instance_ca(){
    test -d "${EASY_RSA}/${instance_ca}" || mkdir -p "${EASY_RSA}/${instance_ca}"
}

create_folder_base_instance_ca(){
    test -d "${base_instance_ca}" || mkdir -p "${base_instance_ca}"
}

set_key_expire(){
    KEY_EXPIRE=${CA_EXPIRE}
    debug KEY_EXPIRE
}

set_key_dir(){
    KEY_DIR="${base_instance_ca}/keys"
    debug KEY_DIR
}

test_port(){
   if netstat -lntup | grep -q "${port}" ;then
    return 1
   else
    return 0
   fi
}

set_route_clients(){
    counter=0
    while true;do
        echo -n "Informe o endereço de rede e mascara: ex. [192.168.1.0 255.255.255.0] "
        read -r answer
        if [[ ${answer} == "sair" ]];then
            break
        elif [[ -n ${answer} ]];then
            routes_clients[${counter}]=${answer}
        else
            echo "Insira um valor válido!!!"
            continue
        fi
        counter=$((counter + 1))
    done
}

set_route_servers(){
    counter=0
    while true;do
        echo -n "Informe o endereço de rede e mascara: ex. [192.168.1.0 255.255.255.0] "
        read -r answer
        if [[ ${answer} == "sair" ]];then
            break
        elif [[ -n ${answer} ]];then
            routes_server[${counter}]=${answer}
        else
            echo "Valor inválido!!"
            continue
        fi
        counter=$((counter + 1))
    done
}

set_dns_servers(){
    counter=0
    while true;do
        echo -n "Informe o endereço do servidor DNS: "
        read -r answer
        if [[ ${answer} == "sair" ]];then
            break
        elif [[ -n ${answer} ]];then
            dns_server[${counter}]=${answer}
        else
            echo "Valor inválido !!"
            continue
        fi
        counter=$((counter + 1))
    done
}
