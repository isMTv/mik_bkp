# mik_bkp
Simple bash script backup for mikrotik to linux server.
* Simultaneous backup multiple hosts (Parameter - EXEC_PARALLEL_HOSTS);
* Ability to create both a full backup and using .rsc files (Arguments for script - full_bkp or rsc_bkp);
* The ability to specify the number of backups to store (Parameter - BACKUP_COUNT);
* Authorization to devices using private keys;
* Errors and successful actions are logged;

### How-to:
```
# ./mik_bkp.sh full_bkp or rsc_bkp

Backup example:
.
├── int.lan
│   ├── 2024
│   │   └── 02
│   │       └── 18
│   │           ├── 172.16.5.1@CRS309-1G-8S+-arm-v7.12.1.backup
│   │           ├── 172.16.5.1@CRS309-1G-8S+-arm-v7.12.1.rsc
│   │           ├── 172.16.5.3@CCR2004-16G-2S+-arm64-v7.12.1.backup
│   │           ├── 172.16.5.3@CCR2004-16G-2S+-arm64-v7.12.1.rsc
│   │           ├── 172.16.5.4@hAP-arm64-v7.13.4.backup
│   │           ├── 172.16.5.4@hAP-arm64-v7.13.4.rsc
│   │           ├── 172.17.5.1@hAP-arm64-v7.13.1.backup
│   │           └── 172.17.5.1@hAP-arm64-v7.13.1.rsc
│   └── int.lan.log
└── mik_bkp.sh
```

### Create key ed25519 or rsa:
```
# cd ~/.ssh/
# ssh-keygen -t ed25519 -f ssh-man_ed25519 -C ssh-management
# ssh-keygen -t rsa -b 2048 -f ssh-man_rsa -C ssh-management
- /root/.ssh/ssh-man_ed25519
[ssh-man_ed25519] - secret key (for the host from which we are connecting)
[ssh-man_ed25519.pub] - public key (for the host to which we are connecting)
```

### We specify a lot of hosts through a space:
```
# nano ~/.ssh/config
Host 172.16.5.1 172.16.5.3 172.16.5.4 172.17.5.1
IdentityFile ~/.ssh/ssh-man_ed25519
# chmod 600 ~/.ssh/config
# service sshd restart
```

### Secure MikroTik SSH:
```
/ip ssh set strong-crypto=yes
/ip ssh set always-allow-password-login=no
```
