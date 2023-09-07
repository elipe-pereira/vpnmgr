#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import sys
import os


class VPNManager:
    def __init__(self):
        self.base_dir = None
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
        self.base_dir = base_path

    def exec(self):
        try:
            for parameter in self.parameters:
                if sys.argv[1] == parameter:
                    os.system("/usr/share/vpnmgr/manager.sh {0}".format(parameter))
        except ChildProcessError:
            os.system('/usr/share/vpnmgr/manager.sh --help')
