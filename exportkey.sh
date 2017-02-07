#!/bin/bash
# exportkey.sh
# usage: exportkey.sh key_name

if [[ "$#" -eq 0 ]]; then
  echo "Key name required."
  echo "usage: exportkey.sh key_name"
  exit 1
fi

if [[ "$#" -gt 1 ]]; then
  echo "Too many arguments."
  echo "usage: exportkey.sh key_name"
  exit 1
fi

KEY=$1
DIRECTORY=ovpn
OVPNPATH=$DIRECTORY/$KEY.ovpn
KEYDIR=easy-rsa/keys
ADDRESS=ayserver.bot.nu

if [ ! -d "$DIRECTORY" ]; then
  mkdir $DIRECTORY
fi

if [ -e "$OVPNPATH" ]; then
  echo "ovpn already exists."
  read -p "Overwrite? " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Nn]$ ]]
  then
    exit 1;
  fi
fi

ISWIN=false

read -p "Windows-based client? " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  ISWIN=true
fi

cd easy-rsa
#TODO: edit location for vars and build-key
echo "sourcing vars"
source vars
echo "building key"
./build-key $1

cd ..

echo -e "client
remote ${ADDRESS} 1194
dev tun
nobind
user nobody
group nobody
persist-key
persist-tun
proto tcp
ns-cert-type server
cipher AES-128-CBC
key-direction 1

" >> $OVPNPATH

if [ "$ISWIN" = true ]; then
echo -e "route-delay 5
route-method exe
ip-win32 netsh" >> $OVPNPATH
fi

echo >> $OVPNPATH

#TODO: edit locations for files
echo "<ca>" >> $OVPNPATH
sed -n '/BEGIN/,/END/p' ca.crt >> $OVPNPATH
echo "</ca>" >> $OVPNPATH

echo "<cert>" >> $OVPNPATH
sed -n '/BEGIN/,/END/p' $KEYDIR/$KEY.crt >> $OVPNPATH
echo "</cert>" >> $OVPNPATH

echo "<key>" >> $OVPNPATH
sed -n '/BEGIN/,/END/p' $KEYDIR/$KEY.key >> $OVPNPATH
echo "</key>" >> $OVPNPATH

echo "<tls-auth>" >> $OVPNPATH
sed -n '/BEGIN/,/END/p' ta.key >> $OVPNPATH
echo "</tls-auth>" >> $OVPNPATH
