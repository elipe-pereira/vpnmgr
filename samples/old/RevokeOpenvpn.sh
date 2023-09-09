#!/usr/bin/env bash

revoke_client_openvpn(){
    load_conf
    set_default_variables

    while true;do

        ask_user "Informe o nome da instância" instance_ca

        if test_if_instance_exists;then
            break;
        else
            echo "Essa instância não existe"
        fi
    done
    ask_user "Informe o nome do certificado" client_name
    set_instance_file_vars_configurations
    load_instance_file_vars_configurations

    ${EASY_RSA}/revoke-full "${client_name}" > /dev/null

    move_cert_client_to_revogated
}

move_cert_client_to_revogated(){
    base_instance_ca="${base_openvpn}"/server/"${instance_ca}"
    folder_certificates="${base_instance_ca}"/certificates
    folder_revogated="${folder_certificates}"/revogated
    data_index_certificate=$(grep -w "${client_name}" "${base_instance_ca}"/index_certificates.txt)
    data_cert_information=$(echo "${data_index_certificate}" | sed s/ativo/revogado/)

    echo "${data_cert_information}" >> "${folder_certificates}"/index_revogated.txt

    test -d ${folder_revogated} || mkdir "${folder_revogated}"

    mv "${folder_certificates}"/"${client_name}".zip "${folder_revogated}"

    sed -i s/${data_index_certificate}/${data_cert_information}/g ${base_instance_ca}/index_certificates.txt
}

