#!/bin/bash
source "${VPNMGR_BASEPATH}/app/scripts/openvpn.sh"
source "${VPNMGR_BASEPATH}/app/scripts/ipsec.sh"

case "$1" in
  --server-openvpn) create_server_openvpn "$2"
    ;;
  --client-openvpn) client_openvpn
    ;;
   --list-instances-openvpn) list_instances_openvpn
   ;;
   --list-certificates-openvpn) list_certificates_openvpn
   ;;
   --list-revogated-openvpn) list_revogated_openvpn
   ;;
   --mail-client-openvpn) mail_client_openvpn
   ;;
   --revoke-client-openvpn) revoke_client_openvpn
   ;;
   --server-ipsec) create_ipsec_server
   ;;
   --help) help
   ;;
   *) help
   ;;
esac
