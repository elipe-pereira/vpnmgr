#!/bin/bash

# shellcheck disable=SC2153
vpnmgr_basepath="${VPNMGR_BASEPATH}"
base_openvpn="${vpnmgr_basepath}"
user="root"
debug="n"
instance_ca="default"
base_instance_ca="${base_openvpn}/system/${user}/server/${instance_ca}"
instance_vars_conf_dir="${vpnmgr_basepath}/app/conf/${user}/instances"
EASY_RSA="${vpnmgr_basepath}/app/lib/easy-rsa"
KEY_DIR="${base_instance_ca}/keys"
KEY_SIZE="4096"
CA_EXPIRE="7300"
KEY_EXPIRE="7300"
KEY_COUNTRY="BR"
KEY_PROVINCE="SC"
KEY_CITY="ANY"
KEY_ORG="ANY"
KEY_EMAIL="ANY@ANY"
KEY_OU="ENTERPRISE"
KEY_NAME="servidor"
answer=""
instance_file_vars_configuration="${instance_vars_conf_dir}/vars-${instance_ca}"
ip_addr=$(ip addr| grep eth0 | grep inet | cut -d ' ' -f 6)
proto=udp
port=1194
interface_vpn="tun-${instance_ca}"
ca="${KEY_DIR}/ca.crt"
cert="${KEY_DIR}/${KEY_NAME}.crt"
key="${KEY_DIR}/${KEY_NAME}.key"
dh="${KEY_DIR}/dh${KEY_SIZE}.pem"
crl_verify="${KEY_DIR}/crl.pem"
topology="subnet"
range_server="192.168.224.0 255.255.252.0"
pool_persist="${instance_ca}/ipp-${instance_ca}.txt"
client_config_dir="${base_instance_ca}/ccd-${instance_ca}"
keepalive="keepalive 10 120"
tls_auth="${base_instance_ca}/ta/ta.key 0"
compress="comp-lzo"
persist_key="persist-key"
persist_tun="persist-tun"
status="/var/log/openvpn/openvpn-status-${instance_ca}.log"
log_append="/var/log/openvpn/openvpn-${instance_ca}.log"
verb="verb 3"
notify="explicit-exit-notify 1"
routes_clients=()
routes_server=()
counter=0
dns_server=("208.67.222.222" "208.67.220.220")
instance_ca_conf="${base_openvpn}/server/${instance_ca}.conf"
systemd_file_openvpn_service="/lib/systemd/system/openvpn@${instance_ca}.service"
client_name="cliente_0"
dst_cert_compact="${base_instance_ca}"/certificates
openvpn=$(command -v openvpn)

function debug (){
    if [[ "${debug}" == "y" ]];then
        echo
        echo "Variável: ${1}"
        echo "Valor Informado: ${!1}"
        echo
    fi
}

function ask_user (){
    echo -n  "${1}: "
    read -r  answer

    if [[ -n "${answer}" ]]; then
        eval "${2}"=\""${answer}"\"
        debug "${2}"
    fi
}

function set_base_instance_ca(){
    base_instance_ca="${base_openvpn}/system/${user}/server/${instance_ca}"
}

function test_if_instance_exists(){
    debug base_instance_ca

    if [[ -d "${base_instance_ca}" ]];then
        return 0
    else
        return 1
    fi
}

function create_instance_vars_conf_dir(){
    test -d "${instance_vars_conf_dir}" || mkdir -p "${instance_vars_conf_dir}"
}

function create_base_instance_dir(){
    test -d "${base_instance_ca}" || mkdir -p "${base_instance_ca}"
}

function set_key_expire(){
    KEY_EXPIRE=${CA_EXPIRE}
    debug KEY_EXPIRE
}

function set_key_dir(){
    KEY_DIR="${base_instance_ca}/keys"
    debug KEY_DIR
}

function setting_ca_variables(){
    while true;do
        ask_user "Informe o nome da instância VPN [${instance_ca}]" instance_ca

        set_base_instance_ca
        if test_if_instance_exists; then
            echo "Instância VPN já existe"
            continue
        fi
        break
    done

    create_instance_vars_conf_dir
    create_base_instance_dir

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

function set_instance_file_vars_configuration(){
    instance_file_vars_configuration="${instance_vars_conf_dir}/vars-${instance_ca}"
    debug instance_file_vars_configuration
}

function create_vars_instance_config(){
    echo > "${instance_file_vars_configuration}"
    {
        echo "export EASY_RSA=${EASY_RSA}";
        echo "export OPENSSL=openssl";
        echo "export PKCS11TOOL=pkcs11-tool";
        echo "export GREP=grep";
        echo "export KEY_CONFIG=\`${EASY_RSA}/whichopensslcnf ${EASY_RSA}\`";
        echo "export KEY_DIR=${KEY_DIR}";
        echo "export PKCS11_MODULE_PATH=dummy";
        echo "export PKCS11_PIN=dummy";
        echo "export KEY_SIZE=${KEY_SIZE}";
        echo "export CA_EXPIRE=${CA_EXPIRE}";
        echo "export KEY_EXPIRE=${KEY_EXPIRE}";
        echo "export KEY_COUNTRY=${KEY_COUNTRY}";
        echo "export KEY_PROVINCE=${KEY_PROVINCE}";
        echo "export KEY_CITY=${KEY_CITY}";
        echo "export KEY_ORG=${KEY_ORG}";
        echo "export KEY_EMAIL=${KEY_EMAIL}";
        echo "export KEY_OU=${KEY_OU}";
        echo "export KEY_NAME=${KEY_NAME}";
    } >> "${instance_file_vars_configuration}"
}

function load_instance_file_vars_configuration(){
  # shellcheck disable=SC1090
  source "${instance_file_vars_configuration}" || return 1
}

function create_ca(){
    "${EASY_RSA}"/clean-all
    "${EASY_RSA}"/build-ca
}

function create_key_server(){
    "${EASY_RSA}"/build-key-server "${KEY_NAME}"
}

function create_key_client(){
    "${EASY_RSA}"/build-key "${1}"
}

function create_dh_key(){
    "${EASY_RSA}"/build-dh
}

function create_folder_ta_key(){
    test -d "${base_instance_ca}/ta" || mkdir -p "${base_instance_ca}/ta"
}

function create_ta_key(){
  test -f "${base_instance_ca}/ta/ta.key" || ${openvpn} --genkey --secret "${base_instance_ca}/ta/ta.key"
}

function test_port(){
   if netstat -lntup | grep -q "${port}" ;then
    return 1
   else
    return 0
   fi
}

function set_server_config_instance(){
  ask_user "Informe o Endereço IP do servidor [${ip_addr}]" ip_addr

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

    instance_ca_conf="${base_instance_ca}/${instance_ca}.conf"
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

    "${EASY_RSA}"/revoke-full "${client_name}"

    {
        echo "#OpenVPN ${instance_ca}";
        echo "# Multi-client server";
        echo "# Endereco de escuta do servidor";
        echo "local ${ip_addr}";
        echo "proto ${proto}";
        echo "port ${port}";
        echo "dev ${interface_vpn}";
        echo "ca ${ca}";
        echo "cert ${cert}";
        echo "key ${key}";
        echo "dh ${dh}";
        echo "crl-verify ${crl_verify}";
        echo "topology ${topology}";
        echo "server ${range_server}";
        echo "ifconfig-pool-persist ${pool_persist}";
     } >> "${instance_ca_conf}"

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

    # shellcheck disable=SC2129
    {
        echo "${keepalive}";
        echo "tls-auth ${tls_auth} 0";
        echo "${compress}";
        echo "${persist_key}";
        echo "${persist_tun}";
        echo "status ${status}";
        echo "log-append ${log_append}";
        echo "${verb}";
        echo "${notify}";
     } >> "${instance_ca_conf}"
}

function create_file_service_systemd(){
    systemd_file_openvpn_service="/lib/systemd/system/openvpn@${instance_ca}.service"

    echo > "${systemd_file_openvpn_service}"

    # shellcheck disable=SC2129
    {
        echo "[Unit]";
        echo "Description=OpenVPN connection to %i";
        echo "PartOf=openvpn.service";
        echo "ReloadPropagatedFrom=openvpn.service";
        echo "Before=systemd-user-sessions.service";
        echo "[Service]";
        echo "PrivateTmp=true";
        echo "KillMode=mixed";
        echo "Type=forking";
        echo "ExecStart=/usr/sbin/openvpn --daemon server-%i \
        --status /run/openvpn/%i.status 10 --cd /etc/openvpn \
        --config /etc/openvpn/server/%i.conf \
        --writepid /run/openvpn/%i.pid";
        echo "PIDFile=/run/openvpn/%i.pid";
        echo "ExecReload=/bin/kill -HUP $MAINPID";
        echo "WorkingDirectory=/etc/openvpn";
        echo "ProtectSystem=yes";
        echo "CapabilityBoundingSet=caP_IPC_LOCK caP_NET_ADMIN \
        caP_NET_BIND_SERVICE caP_NET_RAW caP_SETGID caP_SETUID \
        caP_SYS_CHROOT caP_DAC_READ_SEARCH caP_AUDIT_WRITE";
        echo "LimitNPROC=10";
        echo "DeviceAllow=/dev/null rw";
        echo "DeviceAllow=/dev/net/tun rw";
        echo "[Install]";
        echo "WantedBy=multi-user.target";
     } >> "${systemd_file_openvpn_service}"
}

function create_log_files_instance_vpn(){
    touch "${status}"
    touch "${log_append}"
}

function enable_and_start_instance_vpn_service(){
    systemctl enable openvpn@"${instance_ca}".service
    systemctl start openvpn@"${instance_ca}".service
}

function index_instances_ca(){
    date_creation_ca=$(date +'%s')
    status="ativo"
    {
        echo "${instance_ca}":"${date_creation_ca}":"${status}";
    } >> "${base_openvpn}"/index_instances.txt
}


function set_route_clients(){
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

function set_route_servers(){
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

function set_dns_servers(){
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

function create_server_openvpn(){
    setting_ca_variables
    set_instance_file_vars_configuration
    create_vars_instance_config
    load_instance_file_vars_configuration
    create_ca
    create_key_server
    create_key_client "${client_name}"
    create_dh_key
    create_folder_ta_key
    create_ta_key
    set_server_config_instance
    create_file_service_systemd
    create_log_files_instance_vpn
    enable_and_start_instance_vpn_service
    index_instances_ca
}

function compact_cert (){
    base_instance_ca="${base_openvpn}"/system/"${user}"/server/"${instance_ca}"
    dst_cert_compact="${base_instance_ca}"/certificates
    tmp=/tmp/"${client_name}"
    external_ip=$(curl ifconfig.co 2> /dev/null)
    ta="${base_instance_ca}/ta/ta.key"
    instance_ca_conf="${base_instance_ca}"/${instance_ca}.conf
    port=$(grep -i port "${instance_ca_conf}" | cut -d " " -f 2 |tr -d '\n')
    muttrc_local_file="${base_openvpn}/app/conf/muttrc.local"
    body_mail_message="${base_openvpn}/app/conf/vpnmgr/openvpn/mail_body_message.txt"

    test -d "${dst_cert_compact}" || mkdir "${dst_cert_compact}"
    test -d "${tmp}" || mkdir "${tmp}"

    {
        echo "client";
        echo "dev tun";
        echo "proto udp";
        echo "remote ${external_ip} ${port}";
        echo "resolv-retry infinite";
        echo "nobind";
        echo "persist-key";
        echo "persist-tun";
        echo "ca ca.crt";
        echo "cert ${client_name}.crt";
        echo "key ${client_name}.key";
        echo "remote-cert-tls server";
        echo "tls-auth ta.key 1";
        echo "verb 3";
        echo "comp-lzo";
    } >> "${tmp}/vpn.ovpn"

    cp -av "${ta}" "${tmp}"
    cp -av "${base_instance_ca}/keys/ca.crt" "${tmp}"
    cd "${tmp}" || exit 1

    if [[ ${debug} == "y" ]];then
        echo "Acessado ${tmp}"
    fi

    if [[ ! $(zip -h) ]];then
        echo
        echo "zip não está instalado!"
        echo
        exit 1
    fi

    # shellcheck disable=SC2010
    files=$(ls "${base_instance_ca}"/keys | grep "${client_name}" | grep -v csr)

    for file in ${files}; do
        cp -av "${base_instance_ca}"/keys/"${file}" "${tmp}"
    done

    # shellcheck disable=SC2012
    ls |zip -@ "${client_name}"

    cp -av "${client_name}".zip "${dst_cert_compact}"

    echo -n "Deseja enviar o certificado por e-mail ? [sn]"
    read -r answer

    if [[ ${answer} == "s" ]];then
        echo -n "Confirme seu E-mail: "
        read -r answer

        if [[ -n ${answer} ]];then
            KEY_MAIL=${answer}
        fi
        # shellcheck disable=SC2002
        cat "${body_mail_message}" \
        | mutt -s "Certificado VPN" \
            -F "${muttrc_local_file}" \
            -a "${dst_cert_compact}/${client_name}".zip -- "${KEY_MAIL}"
    fi
}

function client_openvpn(){
    while true;do
        ask_user "Informe o nome da instância VPN" instance_ca
        debug base_instance_ca

        set_instance_file_vars_configuration
        if load_instance_file_vars_configuration; then
            break
        else
            echo "Instância VPN não existe"
        fi
    done

    ask_user "Informe o nome do certificado" client_name

    base_instance_ca="${base_openvpn}"/server/"${instance_ca}"
    data=$(date +'%s' | tr -d '\n')

    create_key_client "${client_name}"

    echo "${client_name}":"${data}":ativo >> "${base_instance_ca}"/index_certificates.txt
    compact_cert
}

function list_instances_openvpn (){
    index="${base_openvpn}"/index_instances.txt

    printf "%20b\t\t\t%20b\t\t\t%20b\n" "Instância VPN" "Data de Criação" "Status"
    list_data_about_instances_or_certificates "${index}"
}

function list_data_about_instances_or_certificates(){
   grep -Evs ^"#" "${1}"|tr : " " | while read -ra value;do
        data=$(date +'%d/%m/%Y-%H:%M' --date="@${value[1]}"| tr -d '\n')
        printf "%20b\t\t\t%20b\t\t\t%20b\n" "${value[0]}" "${data}" "${value[2]}"
    done
}

function list_certificates_openvpn (){
    while true;do
        ask_user "Informe o nome da instância" instance_ca

        if test_if_instance_exists;then
            break;
        else
            echo "Essa instância não existe"
        fi
    done

    base_instance_ca="${base_openvpn}"/system/"${user}"/server/"${instance_ca}"
    index="${base_instance_ca}"/index_certificates.txt

    printf "%20b\t\t\t%20b\t\t\t%20b\n" "Nome do certificado" "Data de Criação" "Status"
    list_data_about_instances_or_certificates "${index}"
}

function list_revogated_openvpn (){
    load_conf

    while true;do
        ask_user "Informe o nome da instância" instance_ca

        if test_if_instance_exists;then
            break;
        else
            echo "Essa instância não existe"
        fi
    done

    base_instance_ca=${base_openvpn}/system/"${user}"/server/${instance_ca}
    folder_certificates="${base_instance_ca}"/certificates
    index="${folder_certificates}"/index_revogated.txt

    printf "%20b\t\t\t%20b\t\t\t%20b\n" "Nome do certificado" "Data de Criação" "Status"

    list_data_about_instances_or_certificates "${index}"
}

function move_cert_client_to_revogated(){
    base_instance_ca="${base_openvpn}/system/${user}/server/${instance_ca}"
    folder_certificates="${base_instance_ca}/certificates"
    folder_revogated="${folder_certificates}/revogated"
    data_index_certificate=$(grep -w "${client_name}" "${base_instance_ca}"/index_certificates.txt)
    # shellcheck disable=SC2001
    data_cert_information=$(echo "${data_index_certificate}" | sed s/ativo/revogado/)

    echo "${data_cert_information}" >> "${folder_certificates}"/index_revogated.txt

    test -d "${folder_revogated}" || mkdir "${folder_revogated}"

    mv "${folder_certificates}"/"${client_name}".zip "${folder_revogated}"

    sed -i s/"${data_index_certificate}"/"${data_cert_information}"/g "${base_instance_ca}"/index_certificates.txt
}

function revoke_client_openvpn(){
    while true;do

        ask_user "Informe o nome da instância" instance_ca

        if test_if_instance_exists;then
            break;
        else
            echo "Essa instância não existe"
        fi
    done
    ask_user "Informe o nome do certificado" client_name
    set_instance_file_vars_configuration
    load_instance_file_vars_configuration

    "${EASY_RSA}"/revoke-full "${client_name}" > /dev/null

    move_cert_client_to_revogated
}

function mail_client_openvpn(){
    ask_user "Informe o nome da instância VPN" instance_ca
    ask_user "informe o nome do certificado VPN" client_name
    ask_user "informe o endereço de e-mail" KEY_MAIL

    set_base_instance_ca
    dst_cert_compact="${base_instance_ca}"/certificates
    body_mail_message="${base_openvpn}/app/conf/vpnmgr/openvpn/mail_body_message.txt"
    muttrc_local_file="${base_openvpn}/app/conf/Muttrc.local"

    # shellcheck disable=SC2002
    cat "${body_mail_message}" \
        | mutt -s "Certificado VPN" \
        -F "${muttrc_local_file}" \
        -a "${dst_cert_compact}/${client_name}".zip -- "${KEY_MAIL}"
}

function help (){
    echo
    echo "--help - Ajuda"
    echo "--server-openvpn - Cria um certificado raiz"
    echo "--client-openvpn - Cria um certificado de um cliente"
    echo "--revoke-client-openvpn - Revoga um certificado cliente"
    echo "--list-instances-openvpn - Lista instâncias VPN"
    echo "--list-revogated-openvpn - Lista certificados revogados"
    echo "--list-certificates-openvpn - Lista certificados clientes"
    echo "--mail-client-openvpn - Enviado o certificado do cliente por e-mail"
    echo
}
