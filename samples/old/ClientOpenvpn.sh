#!/usr/bin/env bash

client_openvpn(){
    load_conf
    set_default_variables

    while true;do
        ask_user "Informe o nome da instância VPN" instance_ca
        debug base_instance_ca
        if load_vars_on_create_cert_client;then
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

load_vars_on_create_cert_client(){
    if test_if_instance_exists;then
        source "${EASY_RSA}/${instance_ca}/vars-${instance_ca}"
        return 0
    else
        return 1
    fi
}

compact_cert (){
    base_instance_ca="${base_openvpn}"/server/"${instance_ca}"
    dst_cert_compact="${base_instance_ca}"/certificates
    tmp=/tmp/${client_name}
    external_ip=$(curl ifconfig.co 2> /dev/null)
    ta="${base_instance_ca}/ta/ta.key"
    instance_ca_conf=${base_openvpn}/server/${instance_ca}.conf
    port=$(grep -i port "${instance_ca_conf}" | cut -d " " -f 2 |tr -d '\n')

    test -d "${dst_cert_compact}" || mkdir "${dst_cert_compact}"
    test -d "${tmp}" || mkdir "${tmp}"

    echo "client" >> "${tmp}/vpn.ovpn"
    echo "dev tun" >> "${tmp}/vpn.ovpn"
    echo "proto udp" >> "${tmp}/vpn.ovpn"
    echo "remote ${external_ip} ${port}" >> "${tmp}/vpn.ovpn"
    echo "resolv-retry infinite" >> "${tmp}/vpn.ovpn"
    echo "nobind" >> "${tmp}/vpn.ovpn"
    echo "persist-key" >> "${tmp}/vpn.ovpn"
    echo "persist-tun" >> "${tmp}/vpn.ovpn"
    echo "ca ca.crt" >> "${tmp}/vpn.ovpn"
    echo "cert ${client_name}.crt" >> "${tmp}/vpn.ovpn"
    echo "key ${client_name}.key" >> "${tmp}/vpn.ovpn"
    echo "remote-cert-tls server" >> "${tmp}/vpn.ovpn"
    echo "tls-auth ta.key 1" >> "${tmp}/vpn.ovpn"
    echo "verb 3" >> "${tmp}/vpn.ovpn"
    echo "comp-lzo" >> "${tmp}/vpn.ovpn"
    cp -av "${ta}" "${tmp}"
    cp -av "${base_instance_ca}/keys/ca.crt" "${tmp}"
    cd "${tmp}"

    if [[ ${debug} == "y" ]];then
        echo "Acessado ${tmp}"
    fi

    if [[ ! $(zip -h) ]];then
        echo
        echo "zip não está instalado!"
        echo
        exit 1
    fi

    files=$(ls "${base_instance_ca}"/keys | grep "${client_name}" | grep -v csr)

    for file in ${files}; do
        cp -av "${base_instance_ca}"/keys/"${file}" "${tmp}"
    done

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

        body_mail_message="/etc/vpnmgr/openvpn/mail_body_message.txt"

        cat "${body_mail_message}" | mutt -s "Certificado VPN" -a "${dst_cert_compact}/${client_name}".zip -- "${KEY_MAIL}"
    fi

}
