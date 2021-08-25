#!/bin/bash
echo 'Installer Configuration setup...'


echo "Enter Host name (Oona Host IP Address unless there is a valid domain name)"
read hostName
echo "Your Host name set to $hostName"


rootFolder='oonaV1'

github_gitlab='http://192.168.0.73/Maina/jitsi-server.git'
#github_gitlab='https://github.com/8-teq/oona-v1.git'



echo 'Server update and upgrade ....'
sudo apt update -y
sudo apt upgrade -y 

echo 'Dependencies others install ....'

packages=(
'gnupg2'
'apt-transport-https'
'gnupg2'
'openssl'
'certbot'
'git'
'make'
)


for package in "${packages[@]}"
do
    sudo apt install -y "${package}"

done



# update all package sources

sudo curl -fsSL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo apt-add-repository universe
sudo apt update -y


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

#echo 'generation cert'
#sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/C=KE/ST=London/L=Nairobi/O=8teq/OU=Cloud /CN=8teq"



echo 'Installing jitsi meet ...'

sudo curl https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | sudo tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null
sudo apt update -y
echo "jitsi-videobridge jitsi-videobridge/jvb-hostname string $hostName" | debconf-set-selections
echo "jitsi-meet-web-config jitsi-meet/cert-choice select 'Generate a new self-signed certificate (You will later get a chance to obtain a Let's encrypt certificate)'" | debconf-set-selections
sudo apt-get --option=Dpkg::Options::=--force-confold --option=Dpkg::options::=--force-unsafe-io --assume-yes --quiet install jitsi-meet


echo 'Cloning project ...'
sudo git clone $github_gitlab /usr/share/$rootFolder
cd /usr/share/$rootFolder
sudo npm install
sudo make


cd ~



echo 'Transfering configurations...'
sudo mv /etc/nginx/sites-available/$hostName.conf /etc/nginx/sites-available/old-$hostName.conf


echo "Creating nginx config "
cat > /etc/nginx/sites-available/$hostName.conf << EOF


server_names_hash_bucket_size 64;

types {
# nginx's default mime.types doesn't include a mapping for wasm
    application/wasm     wasm;
}
server {
    listen 80;
    listen [::]:80;
    server_name $hostName;

    location ^~ /.well-known/acme-challenge/ {
        default_type "text/plain";
        root         /usr/share/$rootFolder;
    }
    location = /.well-known/acme-challenge/ {
        return 404;
    }
    location / {
        return 301 https://\$host\$request_uri;
    }
}
server {
    listen 443 ssl;
    listen [::]:443 ssl;
    server_name $hostName;

    # Mozilla Guideline v5.4, nginx 1.17.7, OpenSSL 1.1.1d, intermediate configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL:10m;  # about 40000 sessions
    ssl_session_tickets off;

    add_header Strict-Transport-Security "max-age=63072000" always;
    set \$prefix "";

    ssl_certificate /etc/jitsi/meet/$hostName.crt;
    ssl_certificate_key /etc/jitsi/meet/$hostName.key;

    root /usr/share/$rootFolder;

    # ssi on with javascript for multidomain variables in config.js
    ssi on;
    ssi_types application/x-javascript application/javascript;

    index index.html index.htm;
    error_page 404 /static/404.html;

    gzip on;
    gzip_types text/plain text/css application/javascript application/json image/x-icon application/octet-stream application/wasm;
    gzip_vary on;
    gzip_proxied no-cache no-store private expired auth;
    gzip_min_length 512;

    location = /config.js {
        alias /etc/jitsi/meet/$hostName-config.js;
    }

    location = /external_api.js {
        alias /usr/share/$rootFolder/libs/external_api.min.js;
    }

    # ensure all static content can always be found first
    location ~ ^/(libs|css|static|images|fonts|lang|sounds|connection_optimization|.well-known)/(.*)$
    {
        add_header 'Access-Control-Allow-Origin' '*';
        alias /usr/share/$rootFolder/\$1/\$2;

        # cache all versioned files
        if (\$arg_v) {
            expires 1y;
        }
    }

    # BOSH
    location = /http-bind {
        proxy_pass http://127.0.0.1:5280/http-bind?prefix=\$prefix&\$args;
        proxy_set_header X-Forwarded-For \$remote_addr;
        proxy_set_header Host \$http_host;
    }

    # xmpp websockets
    location = /xmpp-websocket {
        proxy_pass http://127.0.0.1:5280/xmpp-websocket?prefix=\$prefix&\$args;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
        tcp_nodelay on;
    }

    # colibri (JVB) websockets for jvb1
    location ~ ^/colibri-ws/default-id/(.*) {
        proxy_pass http://127.0.0.1:9090/colibri-ws/default-id/\$1\$is_args\$args;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        tcp_nodelay on;
    }

    # load test minimal client, uncomment when used
    #location ~ ^/_load-test/([^/?&:'"]+)$ {
    #    rewrite ^/_load-test/(.*)$ /load-test/index.html break;
    #}
    #location ~ ^/_load-test/libs/(.*)$ {
    #    add_header 'Access-Control-Allow-Origin' '*';
    #    alias /usr/share/$rootFolder/load-test/libs/\$1;
    #}

    location ~ ^/([^/?&:'"]+)$ {
        try_files \$uri @root_path;
    }

    location @root_path {
        rewrite ^/(.*)$ / break;
    }

    location ~ ^/([^/?&:'"]+)/config.js$
    {
        set \$subdomain "\$1.";
        set \$subdir "\$1/";

        alias /etc/jitsi/meet/$hostName-config.js;
    }

    # BOSH for subdomains
    location ~ ^/([^/?&:'"]+)/http-bind {
        set \$subdomain "\$1.";
        set \$subdir "\$1/";
        set \$prefix "\$1";

        rewrite ^/(.*)$ /http-bind;
    }

    # websockets for subdomains
    location ~ ^/([^/?&:'"]+)/xmpp-websocket {
        set \$subdomain "\$1.";
        set \$subdir "\$1/";
        set \$prefix "\$1";

        rewrite ^/(.*)$ /xmpp-websocket;
    }

    # Anything that didn't match above, and isn't a real file, assume it's a room name and redirect to /
    location ~ ^/([^/?&:'"]+)/(.*)$ {
        set \$subdomain "\$1.";
        set \$subdir "\$1/";
        rewrite ^/([^/?&:'"]+)/(.*)$ /\$2;
    }
}
EOF

echo 'permission change ...'
sudo chmod 644 /etc/nginx/sites-available/$hostName.conf




echo 'checking nginx...'
sudo nginx -t

echo 'Restarting nginx...'
sudo systemctl restart nginx.service



