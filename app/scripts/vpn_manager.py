#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
import os


class VPNManager:
    def __init__(self):
        self.base_path = None
        self.parameters = [
            "--help",
            "--server-openvpn",
            "--client-openvpn",
            "--list-instances-openvpn",
            "--list-certificates-openvpn",
            "--list-revogated-openvpn",
            "--revoke-client-openvpn"
        ]

    def set_base_path(self, base_path):
        self.base_path = base_path
        os.environ['VPNMGR_BASEPATH'] = self.base_path

    def exec(self):
        try:
            if sys.argv[1] in self.parameters:
                os.system("{0}/app/scripts/manager.sh {1}".format(
                    self.base_path, sys.argv[1]
                ))
        except IndexError:
            os.system('{0}/app/scripts/manager.sh --help'.format(self.base_path))
