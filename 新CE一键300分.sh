#!/bin/bash
rht-vmctl reset classroom
rht-vmctl reset server
rht-vmctl reset desktop
echo '警告:CE考试考不过可别怪我!'
echo '其他需求可联系作者1906班谢尚泛'
echo '版本号3.2(完美无注释版)  修复了虚拟机重启,nfs挂载缓慢问题!'
echo '说明:实施过程大概五分钟,请耐心等待!'
echo '温馨提醒,由于虚拟机Bug,每次重启不能保证100%,强迫症的可以多试几次.'
sleep 25
echo '正在实施,请稍等...'
######
ssh root@172.25.0.11 > /dev/null 2>&1 << eeooff   #####server0
######
echo server0.example.com > /etc/hostname
sed -i '1,1a DenyUsers *@*.my133t.org *@172.34.0.*' /etc/ssh/ssh_config
systemctl restart sshd
systemctl enable sshd
######
sed -i '1,1a alias qstat="/bin/ps -Ao pid,tt,user,fname,rsz"' /etc/bashrc
source /etc/bashrc
######
firewall-cmd --set-default-zone=trusted
firewall-cmd --permanent --add-source=172.34.0.0/24 --zone=block
firewall-cmd --permanent --add-forward-port=port=5423:proto=tcp:toport=80
firewall-cmd --reload
######
nmcli connection add type team con-name team0 ifname team0 config '{"runner":{"name":"activebackup"}}'
nmcli connection add type team-slave con-name team0-1 ifname eth1 master team0
nmcli connection add type team-slave con-name team0-2 ifname eth2 master team0
nmcli connection modify team0 ipv4.method manual ipv4.addresses "172.16.3.20/24" connection.autoconnect yes
nmcli connection up team0
nmcli connection up team0-1
nmcli connection up team0-2
######
nmcli connection modify "System eth0" ipv6.method manual ipv6.addresses "2003:ac18::305/64" connection.autoconnect yes
nmcli connection up "System eth0"
######################
echo '#!/bin/bash
if [ "\$1" = redhat ];then
echo fedora
elif [ "\$1" = fedora ];then
echo redhat
else
echo "/root/foo.sh redhat | fedora"
fi
' > /root/foo.sh
chmod +x /root/foo.sh
wget -O /root/userlist http://classroom.example.com/pub/materials/userlist
echo '#!/bin/bash
if [ \$# -eq 0 ];then
echo "Usage: /root/batchusers <userfile>"
exit 1
fi
if [ ! -f \$1 ];then
echo "Input file not found"
exit 2
fi
for name in \$(cat \$1)
do
useradd -s /bin/false \$name >/dev/null
done
' > /root/batchusers
chmod +x /root/batchusers
######samba
yum -y install expect
yum -y install samba
mkdir /common
mkdir /devops
useradd harry
useradd kenji
useradd chihiro
pdbedit -a kenji <<EOF
atenorth
atenorth
EOF
pdbedit -a chihiro <<EOF
atenorth
atenorth
EOF
pdbedit -a harry <<EOF
migwhisk
migwhisk
EOF
setfacl -m u:chihiro:rwx /devops/
sed -i 's(workgroup = MYGROUP(workgroup = STAFF(' /etc/samba/smb.conf
setsebool -P samba_export_all_ro=on
setsebool -P samba_export_all_rw=on
echo '[common]
        Path = /common
        Hosts allow = 172.25.0.0/24

[devops]
        Path = /devops
        Hosts allow = 172.25.0.0/24
        Write list = chihiro
' >> /etc/samba/smb.conf
systemctl restart smb
systemctl enable smb
exit
eeooff
ssh root@172.25.0.10 2>&1 <<eeooff
yum -y install samba-client.x86_64 cifs-utils.x86_64
mkdir /mnt/dev
echo //server0.example.com/devops /mnt/dev cifs username=kenji,password=atenorth,multiuser,sec=ntlmssp,_netdev 0 0 >> /etc/fstab
mount -a
exit
eeooff

ssh root@172.25.0.10 > /dev/null 2>&1 << eeooff      #####desktop0
#########
echo desktop0.example.com > /etc/hostname
sed -i '1,1a DenyUsers *@*.my133t.org *@172.34.0.*' /etc/ssh/ssh_config
systemctl restart sshd
systemctl enable sshd
#########
sed -i '1,1a alias qstat="/bin/ps -Ao pid,tt,user,fname,rsz"' /etc/bashrc
source /etc/bashrc
#########
firewall-cmd --set-default-zone=trusted
firewall-cmd --permanent --add-source=172.34.0.0/24 --zone=block
firewall-cmd --reload
#########
nmcli connection add type team con-name team0 ifname team0 config '{"runner":{"name":"activebackup"}}'
nmcli connection add type team-slave con-name team0-1 ifname eth1 master team0
nmcli connection add type team-slave con-name team0-2 ifname eth2 master team0
nmcli connection modify team0 ipv4.method manual ipv4.addresses "172.16.3.25/24" connection.autoconnect yes
nmcli connection up team0
nmcli connection up team0-1
nmcli connection up team0-2
#########
nmcli connection modify "System eth0" ipv6.method manual ipv6.addresses "2003:ac18::306/64" connection.autoconnect yes
nmcli connection up "System eth0"
#########
lab smtp-nullclient setup
yum -y install expect
exit
eeooff
###############邮件
ssh root@172.25.0.11 2>&1 <<eeooff
sed -i 's/#myorigin = \$myhostname/myorigin = desktop0.example.com/' /etc/postfix/main.cf
sed -i 's/inet_interfaces = localhost/inet_interfaces = loopback-only/' /etc/postfix/main.cf
sed  -i '164s/mydestination = \$myhostname, localhost.\$mydomain, localhost/mydestination =/' /etc/postfix/main.cf
sed -i 's)#mynetworks = 168.100.189.0/28, 127.0.0.0/8)mynetworks = 127.0.0.0/8 [::1]/128)' /etc/postfix/main.cf
sed -i '313s/#relayhost = \$mydomain/relayhost = [smtp0.example.com]/' /etc/postfix/main.cf
sed -i '318,318a local_transport = error:local delivery disabled' /etc/postfix/main.cf
systemctl restart postfix
systemctl enable postfix
exit
eeooff
#########nfs共享
ssh root@172.25.0.11 2>&1 <<eeooff      ###server0
lab nfskrb5 setup
mkdir -p /public /protected/project
chown ldapuser0 /protected/project
echo '/public 172.25.0.0/24(ro)
/protected 172.25.0.0/24(rw,sec=krb5p)
' >> /etc/exports
wget -O /etc/krb5.keytab http://classroom.example.com/pub/keytabs/server0.keytab
systemctl restart nfs-secure-server nfs-server
systemctl enable nfs-secure-server nfs-server
exit
eeooff

ssh root@172.25.0.10 > /dev/null 2>&1 << eeooff      #####desktop0
lab nfskrb5 setup
mkdir /mnt/nfssecure /mnt/nfsmount
wget -O /etc/krb5.keytab http://classroom.example.com/pub/keytabs/desktop0.keytab
systemctl restart nfs-secure
systemctl enable nfs-secure
echo 'server0.example.com:/public /mnt/nfsmount nfs _netdev 0 0
server0.example.com:/protected /mnt/nfssecure nfs sec=krb5p,_netdev 0 0
' >> /etc/fstab
echo ' mount server0.example.com:/public    /mnt/nfsmount
mount server0.example.com:/protected   /mnt/nfssecure
' >> /etc/rc.local
chmod +x /etc/rc.local
mount -a
exit
eeooff
########http
ssh root@172.25.0.11 > /dev/null 2>&1 << eeooff
yum -y install httpd
yum -y install mod_ssl
yum -y install mod_wsgi
wget http://classroom.example.com/pub/materials/station.html -O /var/www/html/index.html
echo '<VirtualHost *:80>
ServerName server0.example.com
DocumentRoot /var/www/html
</VirtualHost>
<VirtualHost *:80>
ServerName www0.example.com
DocumentRoot /var/www/virtual
</VirtualHost>
Listen 8909
<VirtualHost *:8909>
ServerName webapp0.example.com
DocumentRoot /var/www/webapp0
WSGIScriptAlias / /var/www/webapp0/webinfo.wsgi
</VirtualHost>
' > /etc/httpd/conf.d/nsd01.conf
echo '<Directory /var/www/html/private>
Require ip 127.0.0.1 ::1 172.25.0.11 
</Directory>' > /etc/httpd/conf.d/nsd02.conf
mkdir /var/www/virtual
mkdir /var/www/html/private
mkdir /var/www/webapp0
wget http://classroom.example.com/pub/materials/private.html -O /var/www/html/private/index.html
wget http://classroom.example.com/pub/materials/www.html -O /var/www/virtual/index.html
useradd fleyd
setfacl -m u:fleyd:rwx /var/www/virtual/
cd /etc/pki/tls/certs
wget http://classroom.example.com/pub/tls/certs/server0.crt
wget http://classroom.example.com/pub/example-ca.crt
cd ..
cd private
wget http://classroom.example.com/pub/tls/private/server0.key
sed -i '100s/localhost/server0/' /etc/httpd/conf.d/ssl.conf
sed -i '107s/localhost/server0/' /etc/httpd/conf.d/ssl.conf
sed -i '122s/#//' /etc/httpd/conf.d/ssl.conf
sed -i '122s/ca-bundle/example-ca/' /etc/httpd/conf.d/ssl.conf
cd /var/www/webapp0
wget http://classroom.example.com/pub/materials/webinfo.wsgi
semanage port -a -t http_port_t -p tcp 8909
systemctl restart httpd
systemctl enable httpd
exit
eeooff

ssh root@172.25.0.11 > /dev/null 2>&1 << eeooff   #####server0
yum -y install mariadb-server mariadb
sed -i '1,1a skip-networking' /etc/my.cnf
systemctl restart mariadb
systemctl enable mariadb
mysqladmin -u root password 'atenorth'
mysql -u root -patenorth <<EOF
create database Contacts;
grant select on Contacts.* to Raikon@localhost identified by 'atenorth';
delete from mysql.user where password='';
quit
EOF
wget http://classroom.example.com/pub/materials/users.sql
mysql -u root -patenorth Contacts < users.sql
eeooff


ssh root@172.25.0.11 > /dev/null 2>&1 << eeooff   #####server0
yum -y install targetcli
yum -y install expect
fdisk /dev/vdb <<EOF
n
p


+3G
w
EOF
partprobe /dev/vdb
systemctl enable target
expect << EOF
spawn targetcli
expect "/> " {send "backstores/block create iscsi_store /dev/vdb1\r"}
expect "/>" {send "iscsi/ create iqn.2016-02.com.example:server0\r"}
expect "/>" {send "iscsi/iqn.2016-02.com.example:server0/tpg1/acls create iqn.2016-02.com.example:desktop0\r"}
expect "/>" {send "iscsi/iqn.2016-02.com.example:server0/tpg1/luns create /backstores/block/iscsi_store\r"}
expect "/>" {send "iscsi/iqn.2016-02.com.example:server0/tpg1/portals create 172.25.0.11 3260\r"}
expect ">" {send "saveconfig\r"}
expect “/>” {send “saveconfig\r”}
expect “/>” {send “exit\r”}
EOF
systemctl restart target
systemctl enable target
exit
eeooff

ssh root@172.25.0.10 > /dev/null 2>&1 << eeooff      #####desktop0
yum -y install iscsi-initiator-utils
echo InitiatorName=iqn.2016-02.com.example:desktop0 > /etc/iscsi/initiatorname.iscsi 
systemctl restart iscsid
systemctl enable iscsid
iscsiadm -m discovery -t st -p 172.25.0.11 3260 
systemctl restart iscsi
systemctl enable iscsi
sed -i '50s/manual/automatic/' /var/lib/iscsi/nodes/iqn.2016-02.com.example\:server0/172.25.0.11\,3260\,1/default
systemctl restart iscsi
systemctl enable iscsi
fdisk /dev/sda <<EOF
n
p


+2100M
w
EOF
partprobe
mkfs.ext4 /dev/sda1
mkdir /mnt/data
echo \$(blkid /dev/sda1) /mnt/data ext4 _netdev 0 0 > sed.txt
sed -i 's#/dev/sda1:##;s#TYPE="ext4"##' sed.txt
sed -i 's#"##g' sed.txt
cat sed.txt >> /etc/fstab
mount -a
# && reboot
exit
eeooff
echo '实施成功,谢谢使用!'
