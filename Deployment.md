# Oona v1 Deployment Guide

Follow these steps to deploy Oona v1 on a Debian-based GNU/Linux system. The following distributions are supported out-of-the-box:
-   Ubuntu 18.04 (Bionic Beaver) or newer

_Note_: Many of the installation steps require  `root`  or  `sudo`  access.

## Required packages and repository updates

You will need the following packages:

-   `gnupg2`
-   `nginx-full`
-   `sudo`  # only needed if you use sudo

Make sure your system is up-to-date and required packages are installed:

```bash
# Retrieve the latest package versions across all repositories
apt update

# Ensure support for apt repositories served via HTTPS
apt install apt-transport-https

```

On Ubuntu systems, Oona requires dependencies from Ubuntu's  `universe`  package repository. To ensure this is enabled, run this command:

```bash
sudo apt-add-repository universe

# Retrieve the latest package versions across all repositories
sudo apt update

```

## Install Oona v1
### Add the Jitsi package repository

This will add the jitsi repository to your package sources to make the Jitsi Meet packages available.

```bash
curl https://download.jitsi.org/jitsi-key.gpg.key | sudo sh -c 'gpg --dearmor > /usr/share/keyrings/jitsi-keyring.gpg'
echo 'deb [signed-by=/usr/share/keyrings/jitsi-keyring.gpg] https://download.jitsi.org stable/' | sudo tee /etc/apt/sources.list.d/jitsi-stable.list > /dev/null

# update all package sources
sudo apt update

```

### Setup and configure your firewall

The following ports need to be open in your firewall, to allow traffic to the Jitsi Meet server:

-   80 TCP - for SSL certificate verification / renewal with Let's Encrypt
-   443 TCP - for general access to Jitsi Meet
-   10000 UDP - for general network video/audio communications
-   22 TCP - if you access you server using SSH (change the port accordingly if it's not 22)
-   3478 UDP - for quering the stun server (coturn, optional, needs config.js change to enable it)
-   5349 TCP - for fallback network video/audio communications over TCP (when UDP is blocked for example), served by coturn

If you are using  `ufw`, you can use the following commands:

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 10000/udp
sudo ufw allow 22/tcp
sudo ufw allow 3478/udp
sudo ufw allow 5349/tcp
sudo ufw enable

```

Check the firewall status with:

```bash
sudo ufw status verbose

```
### TLS Certificate

In order to have encrypted communications, you need a  [TLS certificate](https://en.wikipedia.org/wiki/Transport_Layer_Security).

During installation of Jitsi Meet you can choose between different options:

1.  The recommended option is to choose  **_Generate a new self-signed certificate_**  and create a Lets-Encrypt Certificate later (this will replace the self-signed certificate).
    
2.  But if you want to use a different certificate or you want to choose a different challenge type of Let's Encrypt, you should create that certificate first and then install jitsi-meet and choose  **_I want to use my own certificate_**.
    
3.  You could also use the self-signed certificate but this is not recommended for the following reasons:
    
    -   Using a self-signed certificate will result in warnings being shown in your users browsers, because they cannot verify your server's identity.
        
    -   Jitsi Meet mobile apps  _require_  a valid certificate signed by a trusted  [Certificate Authority](https://en.wikipedia.org/wiki/Certificate_authority)  and will not be able to connect to your server if you choose a self-signed certificate.
    - In the event you still want to use a self signed certificate then check out [How To Create a Self-Signed SSL Certificate for Nginx in Ubuntu 18.04](https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-in-ubuntu-18-04) to generate the ssl_certificate and ssl_certificate_key
        

### Install Jitsi Meet

```bash
# jitsi-meet installation
sudo apt install jitsi-meet

```

**SSL/TLS certificate generation:**  You will be asked about SSL/TLS certificate generation. See above for details.

### Switching from Jitsi Meet to custom Oona v1

Upload the Oona application zip file onto the server and extract it in your preferred directory(in this case it will be /home/).

```bash
# After copying the zip file to get the oona file
unzip oona.zip

```
Move to the sites-available folder in the nginx folder and access the nginx conf for Jitsi application we set up earlier.

```bash
cd /etc/nginx/sites-available
nano oona-app.conf

```
Within the file:
- Replace all instances of **/usr/share/jitsi-meet** with **/home/oona**
- In case you selected the **_I want to use my own certificate_** option then edit the ssl_certificate and ssl_certificate_key section and add the path to both files.

After check that Nginx configurations are okay then restart the server
```bash
# Check configs
sudo nginx -t

# Restart Nginx service
systemctl restart nginx.service

```
