#!/usr/bin/env bash

list_instances_openvpn (){
    load_conf

    index="${base_openvpn}"/index_instances.txt

    printf "%20b\t\t\t%20b\t\t\t%20b\n" "Instância VPN" "Data de Criação" "Status"
    list_data_about_instances_or_certificates "${index}"
}

list_certificates_openvpn (){
    load_conf

    while true;do
        ask_user "Informe o nome da instância" instance_ca

        if test_if_instance_exists;then
            break;
        else
            echo "Essa instância não existe"
        fi
    done

    base_instance_ca="${base_openvpn}"/server/"${instance_ca}"
    index="${base_instance_ca}"/index_certificates.txt

    printf "%20b\t\t\t%20b\t\t\t%20b\n" "Nome do certificado" "Data de Criação" "Status"
    list_data_about_instances_or_certificates "${index}"
}

list_data_about_instances_or_certificates(){
   grep -Evs ^"#" "${1}"|tr : " " | while read -a value;do
        data=$(date +'%d/%m/%Y-%H:%M' --date="@${value[1]}"| tr -d '\n')
        printf "%20b\t\t\t%20b\t\t\t%20b\n" ${value[0]} ${data} ${value[2]}
    done
}

list_revogated_openvpn (){
    load_conf

    while true;do
        ask_user "Informe o nome da instância" instance_ca

        if test_if_instance_exists;then
            break;
        else
            echo "Essa instância não existe"
        fi
    done

    base_instance_ca=${base_openvpn}/server/${instance_ca}
    folder_certificates="${base_instance_ca}"/certificates
    index="${folder_certificates}"/index_revogated.txt

    printf "%20b\t\t\t%20b\t\t\t%20b\n" "Nome do certificado" "Data de Criação" "Status"

    list_data_about_instances_or_certificates "${index}"
}