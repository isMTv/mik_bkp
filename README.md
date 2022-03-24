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
├── core
│   ├── 2022
│   │   └── 03
│   │       └── 10
│   │           ├── 172.16.1.1@CRS309-1G-8S+-(arm)-v7.2rc3.backup
│   │           ├── 172.16.2.1@hEX-(mmips)-v7.1.3.backup
│   │           ├── 172.16.3.1@cAP-(arm)-v7.1.3.backup
│   │           ├── 172.17.4.1@hEX-(mmips)-v7.1.3.backup
│   │           └── 172.17.5.1@hAP-(smips)-v7.1.3.backup
│   └── core.log
└── mik_bkp.sh
```

### Create key mik_rsa:
```
# cd ~/.ssh/
# ssh-keygen -t rsa -b 2048
- /root/.ssh/mik_rsa
id_rsa [mik_rsa] - secret key (for the host from which we are connecting)
id_rsa.pub [mik_rsa.pub] - public key (for the host to which we are connecting)
```

### We specify a lot of hosts through a space:
```
# nano ~/.ssh/config
Host 172.16.1.1 172.16.2.1 172.16.3.1 172.17.4.1 172.17.5.1
IdentityFile ~/.ssh/mik_rsa
# chmod 600 ~/.ssh/config
# service sshd restart
```

### Secure MikroTik SSH:
```
/ip ssh set strong-crypto=yes
/ip ssh set always-allow-password-login=no
```
