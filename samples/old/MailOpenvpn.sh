#!/usr/bin/env bash

mail_client_openvpn(){
    load_conf

    ask_user "Informe o nome da instância VPN" instance_ca
    ask_user "informe o nome do certificado VPN" client_name
    ask_user "informe o endereço de e-mail" KEY_MAIL

    set_base_instance_ca
    dst_cert_compact="${base_instance_ca}"/certificates
    body_mail_message="/etc/vpnmgr/openvpn/mail_body_message.txt"

    cat "${body_mail_message}" | mutt -s "Certificado VPN" -a "${dst_cert_compact}/${client_name}".zip -- "${KEY_MAIL}"
}