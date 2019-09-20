#!/bin/bash
echo "请输入虚拟机ip,列50,51 ....最多输入八个!"
echo "注意:已配置过的虚拟机切勿输入.一切后果由班长承担!"
echo "本人承诺,一切脚本皆在真机操作.如有意外,当我没说!"
echo "版本2.0(2019.09.03 最新版)"
echo "可接定制版,下课找班长"
sleep 2 
echo "的后桌" 
for i in $1 $2 $3 $4 $5 $6 $7 $8
do
ssh root@192.168.4.$i  >/dev/null  2>&1 <<eeooff
grep 'temporary password' /var/log/mysqld.log |awk -F: '{print  \$4}' |sed 's/^ *//' >aa.txt
sed -i 's/validate_password_policy=0//' /etc/my.cnf
sed -i 's/validate_password_length=6//' /etc/my.cnf
sed -i '4a validate_password_policy=0' /etc/my.cnf
sed -i '5a validate_password_length=6' /etc/my.cnf
systemctl restart mysqld
mysqladmin -uroot -p\$(cat aa.txt) password "123456" 
systemctl restart mysqld
systemctl enable mysqld 
exit
eeooff
done
