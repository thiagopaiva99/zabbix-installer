#!/bin/bash

# verifica se foi executado com sudo ou nao
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

php_package=$(dpkg --get-selections | grep "php" )
mysql_package=$(dpkg --get-selections | grep "mysql" )

# verifica se o pacote php esta instalado
if [ ! -n "$php_package" ] ; then
  echo "[ X ] O pacote \"php\" precisa estar instalado"

  exit 1
fi

# verifica se o pacote mysql esta instalado
if [ ! -n "$mysql_package" ] ; then
  echo "[ X ] O pacote \"php\" precisa estar instalado"

  exit 1
fi

# pega os parametros que foram passados ao script
while getopts 'p:' opt ; do
  case $opt in
    p) PASSWORD=$OPTARG ;;
  esac
done

# atualiza os repositorios do sistema
apt-get update

# instala dependencias do PHP que o zabbix precisa
apt-get install php7.0-xml php7.0-bcmath php7.0-mbstring

# entra dentro da pasta /tmp
cd /tmp

# faz o download da release do zabbix
wget http://repo.zabbix.com/zabbix/3.2/ubuntu/pool/main/z/zabbix-release/zabbix-release_3.2-1+xenial_all.deb

# faz o dpkg do pacote que foi baixado
dpkg -i zabbix-release_3.2-1+xenial_all.deb

# atualiza novamente os repositorios
apt-get update

# instala o servidor mysql para o zabbix e o cliente frontend para o zabbix
apt-get install zabbix-server-mysql zabbix-frontend-php

# instala o agente di zabbix
apt-get install zabbix-agent

# cria o banco de dados do zabbix
mysql -uroot -p$PASSWORD -e "create database zabbix character set utf8 collate utf8_bin;"

# altera os privilegios do banco de dados para o usuario zabbix
mysql -uroot -p$PASSWORD -e "grant all privileges on zabbix.* to zabbix@localhost identified by '$PASSWORD';"

# atualiza os privilegios
mysql -uroot -p$PASSWORD -e "flush privileges;";

# executa acriacao de toda estrutura do banco de dados | PODE DEMORAR MUITO TEMPO
zcat /usr/share/doc/zabbix-server-mysql/create.sql.gz | mysql -uzabbix -p$PASSWORD zabbix

# coloca a senha do banco de dados do zabbix no arquivo de configuraçao
echo "DBPassword=$PASSWORD" >> /etc/zabbix/zabbix_server.conf

# reinicia o servico do apache
systemctl restart apache2

# inici o servio do zabbix
systemctl start zabbix-server

# habilita o servico do zabbix para iniciar com o sistema
systemctl enable zabbix-server

# limpa a tela
clear

# faz um agradecimento :)
echo "Obrigado por instalar o Zabbix conosco!"

# finaliza o programa
exit 1
