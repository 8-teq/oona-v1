echo 'Installer Configuration setup'

echo Hello, who am I talking to?
read varname
echo It\'s nice to meet you $varname






echo 'Server update and upgrade ....'
sudo apt update -y
sudo apt upgrade -y 

echo 'Dependencies others install ....'

packages=(
'gnupg2'
'apt-transport-https'
'gnupg2'
'openssl'
)

#sudo apt install -y gnupg2
#sudo apt install -y nginx-full
#sudo apt install -y apt-transport-https

for package in "${packages[@]}"
do
    sudo apt install -y "${package}"

done
#sudo apt install -y gnupg2
#sudo apt install -y nginx-full
#sudo apt install -y apt-transport-https

for package in $packages
do
    sudo apt install package

done


sudo apt-add-repository universe

sudo apt update -y

curl https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | sudo tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null

# update all package sources
sudo apt update


echo 'ufw configurations'
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 10000/udp
sudo ufw allow 22/tcp
sudo ufw allow 3478/udp
sudo ufw allow 5349/tcp
sudo ufw enable

echo 'ufw status'
sudo ufw status verbose

echo 'generation cert'



sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/C=KE/ST=London/L=Nairobi/O=8teq/OU=Cloud /CN=8teq"



echo 'Installing jitsi meet ...'
sudo apt install -y jitsi-meet

echo 'Transfering configurations...'



echo 'checking nginx...'
sudo nginx -t

echo 'Restarting nginx...'
sudo systemctl restart nginx.service


