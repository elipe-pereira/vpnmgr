#!/usr/bin/env bash

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