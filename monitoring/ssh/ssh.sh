#!/bin/bash

function main()
{
    hostname
    printf '\tDate\t\tAddress\t\tState\n'

    journalctl _SYSTEMD_UNIT=sshd.service > log_ssh.txt
    awk -f ssh.awk log_ssh.txt

}

# Pass arguments as-is
main "$@"






