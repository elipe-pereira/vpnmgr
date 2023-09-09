#!/usr/bin/python3
# coding: utf-8
import os
import sys
from app.scripts.vpn_manager import VPNManager


class Main:
    def __init__(self):
        self.vpn_manager = None
        self.base_path = os.path.dirname(os.path.realpath(__file__))
        if self.base_path not in sys.path:
            sys.path.append(self.base_path)

    def run(self):
        self.vpn_manager = VPNManager()
        self.vpn_manager.set_base_path(self.base_path)
        self.vpn_manager.exec()


if __name__ == "__main__":
    app = Main()
    app.run()
