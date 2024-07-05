#!/bin/bash
colorized_echo() {
    local color=$1
    local text=$2
    
    case $color in
        "red")
        printf "\e[91m${text}\e[0m\n";;
        "green")
        printf "\e[92m${text}\e[0m\n";;
        "yellow")
        printf "\e[93m${text}\e[0m\n";;
        "blue")
        printf "\e[94m${text}\e[0m\n";;
        "magenta")
        printf "\e[95m${text}\e[0m\n";;
        "cyan")
        printf "\e[96m${text}\e[0m\n";;
        *)
            echo "${text}"
        ;;
    esac
}

# Check if the script is run as root
if [ "$(id -u)" != "0" ]; then
    colorized_echo red "Error: Skrip ini harus dijalankan sebagai root."
    exit 1
fi

# Check supported operating system
supported_os=false

if [ -f /etc/os-release ]; then
    os_name=$(grep -E '^ID=' /etc/os-release | cut -d= -f2)
    os_version=$(grep -E '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')

    if [ "$os_name" == "debian" ] && [ "$os_version" == "11" ]; then
        supported_os=true
    elif [ "$os_name" == "ubuntu" ] && [ "$os_version" == "20.04" ]; then
        supported_os=true
    fi
fi
apt install sudo curl -y
if [ "$supported_os" != true ]; then
    colorized_echo red "Error: Skrip ini hanya support di Debian 11 dan Ubuntu 20.04. Mohon gunakan OS yang di support."
    exit 1
fi

# Fungsi untuk menambahkan repo Debian 11
addDebian11Repo() {
    echo "#mirror_kambing-sysadmind deb11
deb http://kartolo.sby.datautama.net.id/debian bullseye main contrib non-free
deb http://kartolo.sby.datautama.net.id/debian bullseye-updates main contrib non-free
deb http://kartolo.sby.datautama.net.id/debian-security bullseye-security main contrib non-free" | sudo tee /etc/apt/sources.list > /dev/null
}

# Fungsi untuk menambahkan repo Ubuntu 20.04
addUbuntu2004Repo() {
    echo "#mirror buaya klas 20.04
deb https://buaya.klas.or.id/ubuntu/ focal main restricted universe multiverse
deb https://buaya.klas.or.id/ubuntu/ focal-updates main restricted universe multiverse
deb https://buaya.klas.or.id/ubuntu/ focal-security main restricted universe multiverse
deb https://buaya.klas.or.id/ubuntu/ focal-backports main restricted universe multiverse
deb https://buaya.klas.or.id/ubuntu/ focal-proposed main restricted universe multiverse" | sudo tee /etc/apt/sources.list > /dev/null
}

# Mendapatkan informasi kode negara dan OS
COUNTRY_CODE=$(curl -s https://ipinfo.io/country)
OS=$(lsb_release -si)

# Pemeriksaan IP Indonesia
if [[ "$COUNTRY_CODE" == "ID" ]]; then
    colorized_echo green "IP Indonesia terdeteksi, menggunakan repositories lokal Indonesia"

    # Menanyakan kepada pengguna apakah ingin menggunakan repo lokal atau repo default
    read -p "Apakah Anda ingin menggunakan repo lokal Indonesia? (y/n): " use_local_repo

    if [[ "$use_local_repo" == "y" || "$use_local_repo" == "Y" ]]; then
        # Pemeriksaan OS untuk menambahkan repo yang sesuai
        case "$OS" in
            Debian)
                VERSION=$(lsb_release -sr)
                if [ "$VERSION" == "11" ]; then
                    addDebian11Repo
                else
                    colorized_echo red "Versi Debian ini tidak didukung."
                fi
                ;;
            Ubuntu)
                VERSION=$(lsb_release -sr)
                if [ "$VERSION" == "20.04" ]; then
                    addUbuntu2004Repo
                else
                    colorized_echo red "Versi Ubuntu ini tidak didukung."
                fi
                ;;
            *)
                colorized_echo red "Sistem Operasi ini tidak didukung."
                ;;
        esac
    else
        colorized_echo yellow "Menggunakan repo bawaan VM."
        # Tidak melakukan apa-apa, sehingga repo bawaan VM tetap digunakan
    fi
else
    colorized_echo yellow "IP di luar Indonesia."
    # Lanjutkan dengan repo bawaan OS
fi
mkdir -p /etc/data

#domain
read -rp "Masukkan Domain: " domain
echo "$domain" > /etc/data/domain
domain=$(cat /etc/data/domain)

#Preparation
clear
cd;
apt-get update;

#Remove unused Module
apt-get -y --purge remove samba*;
apt-get -y --purge remove apache2*;
apt-get -y --purge remove sendmail*;
apt-get -y --purge remove bind9*;

#install bbr
echo 'fs.file-max = 500000
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.core.netdev_max_backlog = 250000
net.core.somaxconn = 4096
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_keepalive_time = 1200
net.ipv4.ip_local_port_range = 10000 65000
net.ipv4.tcp_max_syn_backlog = 8192
net.ipv4.tcp_max_tw_buckets = 5000
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_mem = 25600 51200 102400
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.core.rmem_max = 4000000
net.ipv4.tcp_mtu_probing = 1
net.ipv4.ip_forward = 1
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1' >> /etc/sysctl.conf
sysctl -p;

#install toolkit
apt-get install libio-socket-inet6-perl libsocket6-perl libcrypt-ssleay-perl libnet-libidn-perl perl libio-socket-ssl-perl libwww-perl libpcre3 libpcre3-dev zlib1g-dev dbus iftop zip unzip wget net-tools curl nano sed screen gnupg gnupg1 bc apt-transport-https build-essential dirmngr dnsutils sudo at htop iptables bsdmainutils cron lsof lnav -y

#Set Timezone GMT+7
timedatectl set-timezone Asia/Jakarta;

#Install Marzban
sudo bash -c "$(curl -sL https://github.com/GawrAme/Marzban-scripts/raw/master/marzban.sh)" @ install

#Install Subs
wget -N -P /var/lib/marzban/templates/subscription/  https://raw.githubusercontent.com/claudialubowitz26/mar-lum/main/index.html

#install env
cat > "/opt/marzban/.env" << EOF
UVICORN_HOST = "0.0.0.0"
UVICORN_PORT = 7879

## the following variables which is somehow hard codded infrmation.
# SUDO_USERNAME = "admin"
# SUDO_PASSWORD = "admin"

# UVICORN_UDS: "/run/marzban.socket"
# UVICORN_SSL_CERTFILE = "/var/lib/marzban/xray.crt"
# UVICORN_SSL_KEYFILE = "/var/lib/marzban/xray.key"


XRAY_JSON = "/var/lib/marzban/xray_config.json"
XRAY_EXECUTABLE_PATH = "/var/lib/marzban/core/xray"
# XRAY_SUBSCRIPTION_URL_PREFIX = "https://example.com"
# XRAY_EXECUTABLE_PATH = "/var/lib/marzban/core/xray"
XRAY_ASSETS_PATH = "/var/lib/marzban/assets"
# XRAY_FALLBACKS_INBOUND_TAG = "INBOUND_X"


# TELEGRAM_API_TOKEN = 123456789:AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
# TELEGRAM_ADMIN_ID = 987654321
# TELEGRAM_PROXY_URL = "http://localhost:8080"


# CLASH_SUBSCRIPTION_TEMPLATE="clash/my-custom-template.yml"
SUBSCRIPTION_PAGE_TEMPLATE="subscription/index.html"
CUSTOM_TEMPLATES_DIRECTORY="/var/lib/marzban/templates/"
HOME_PAGE_TEMPLATE="home/index.html"
# SUBSCRIPTION_PAGE_LANG="en"

SQLALCHEMY_DATABASE_URL = "sqlite:////var/lib/marzban/db.sqlite3"

### for developers
# DOCS=true
# DEBUG=true
# WEBHOOK_ADDRESS = "http://127.0.0.1:9000/"
# WEBHOOK_SECRET = "something-very-very-secret"
# VITE_BASE_API="https://example.com/api/"
# JWT_ACCESS_TOKEN_EXPIRE_MINUTES = 1440
EOF

#install core Xray & Assets folder
mkdir -p /var/lib/marzban/assets
mkdir -p /var/lib/marzban/core
wget -O /var/lib/marzban/core/xray.zip "https://github.com/XTLS/Xray-core/releases/download/v1.8.16/Xray-linux-64.zip"  
cd /var/lib/marzban/core && unzip xray.zip && chmod +x xray
cd

#profile
echo -e 'profile' >> /root/.profile
cat > "/usr/bin/profile" << EOF
#!/bin/bash
clear
neofetch
echo -e " Selamat datang di layanan AutoInstaller LumineVPN x Marzban"
echo -e " Ketik \e[1;32mmarzban\e[0m untuk menampilkan daftar perintah"
echo -e ""
cekservice
EOF
chmod +x /usr/bin/profile

#cekservice
apt install neofetch -y
wget -O /usr/bin/cekservice "https://raw.githubusercontent.com/claudialubowitz26/mar-lum/main/cekservice.sh"
chmod +x /usr/bin/cekservice

#install compose
cat > "/opt/marzban/docker-compose.yml" << EOF
services:
  marzban:
    image: gozargah/marzban:latest
    restart: always
    env_file: .env
    network_mode: host
    volumes:
    - /etc/timezone:/etc/timezone:ro
    - /etc/localtime:/etc/localtime:ro
    - /var/lib/marzban:/var/lib/marzban

  nginx:
    image: nginx
    restart: always
    network_mode: host
    volumes:
    - /var/lib/marzban:/var/lib/marzban
    - /var/www/html:/var/www/html
    - /etc/timezone:/etc/timezone:ro
    - /etc/localtime:/etc/localtime:ro
    - /var/log/nginx/access.log:/var/log/nginx/access.log
    - /var/log/nginx/error.log:/var/log/nginx/error.log
    - ./nginx.conf:/etc/nginx/nginx.conf
EOF

#Install VNSTAT
apt -y install vnstat
/etc/init.d/vnstat restart
apt -y install libsqlite3-dev
wget https://github.com/claudialubowitz26/mar-lum/raw/main/vnstat-2.6.tar.gz
tar zxvf vnstat-2.6.tar.gz
cd vnstat-2.6
./configure --prefix=/usr --sysconfdir=/etc && make && make install 
cd
chown vnstat:vnstat /var/lib/vnstat -R
systemctl enable vnstat
/etc/init.d/vnstat restart
rm -f /root/vnstat-2.6.tar.gz 
rm -rf /root/vnstat-2.6

#Install Speedtest
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install speedtest -y

#install nginx
mkdir -p /var/log/nginx
touch /var/log/nginx/access.log
touch /var/log/nginx/error.log

cat > "/opt/marzban/nginx.conf" << EOF
#user nobody nogroup;
worker_processes auto;

error_log /var/log/nginx/error.log;

pid /run/nginx.pid;

events
{
    worker_connections 1024;
}

http
{
    include mime.types;
    default_type application/octet-stream;

    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
    '\$status \$body_bytes_sent "\$http_referer" '
    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;
    sendfile on;

    sendfile       on;
    tcp_nopush     on;
    tcp_nodelay    on;
    keepalive_timeout  65;
    types_hash_max_size 2048;

    server
    {
        listen 80;
        listen [::]:80;
        listen 443 ssl http2 default_server;
        listen [::]:443 ssl http2 default_server;

        set_real_ip_from 103.21.244.0/22;
        set_real_ip_from 103.22.200.0/22;
        set_real_ip_from 103.31.4.0/22;
        set_real_ip_from 104.16.0.0/13;
        set_real_ip_from 104.24.0.0/14;
        set_real_ip_from 108.162.192.0/18;
        set_real_ip_from 131.0.72.0/22;
        set_real_ip_from 141.101.64.0/18;
        set_real_ip_from 162.158.0.0/15;
        set_real_ip_from 172.64.0.0/13;
        set_real_ip_from 173.245.48.0/20;
        set_real_ip_from 188.114.96.0/20;
        set_real_ip_from 190.93.240.0/20;
        set_real_ip_from 197.234.240.0/22;
        set_real_ip_from 198.41.128.0/17;

        set_real_ip_from 2400:cb00::/32;
        set_real_ip_from 2606:4700::/32;
        set_real_ip_from 2803:f800::/32;
        set_real_ip_from 2405:b500::/32;
        set_real_ip_from 2405:8100::/32;
        set_real_ip_from 2a06:98c0::/29;
        set_real_ip_from 2c0f:f248::/32;
        real_ip_header X-Forwarded-For;


        server_name $domain;

        ssl_certificate /var/lib/marzban/certs/$domain/fullchain.cer;
        ssl_certificate_key /var/lib/marzban/certs/$domain/privkey.key;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_prefer_server_ciphers on;
        ssl_ciphers EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5;

        location = /vlessws
        {
            if (\$http_upgrade != "websocket")
            {
                return 404;
            }
            proxy_redirect off;
            proxy_pass http://127.0.0.1:20651;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }

        location = /vmessws
        {
            if (\$http_upgrade != "websocket")
            {
                return 404;
            }
            proxy_redirect off;
            proxy_pass http://127.0.0.1:20652;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }

        location = /trojanws
        {
            if (\$http_upgrade != "websocket")
            {
                return 404;
            }
            proxy_redirect off;
            proxy_pass http://127.0.0.1:20653;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }

        location = /vlesshu
        {
            if (\$http_upgrade != "websocket")
            {
                return 404;
            }
            proxy_redirect off;
            proxy_pass http://127.0.0.1:2021;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }

        location = /vmesshu
        {
            if (\$http_upgrade != "websocket")
            {
                return 404;
            }
            proxy_redirect off;
            proxy_pass http://127.0.0.1:2022;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }

        location = /trojanhu
        {
            if (\$http_upgrade != "websocket")
            {
                return 404;
            }
            proxy_redirect off;
            proxy_pass http://127.0.0.1:2023;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$host;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }

        location /vlessgrpc
        {
            if (\$request_method != "POST")
            {
                return 404;
            }
            client_body_buffer_size 1m;
            client_body_timeout 1h;
            client_max_body_size 0;
            grpc_pass grpc://127.0.0.1:3001;
            grpc_read_timeout 1h;
            grpc_send_timeout 1h;
            grpc_set_header Host \$host;
            grpc_set_header X-Real-IP \$remote_addr;
        }

        location /vmessgrpc
        {
            if (\$request_method != "POST")
            {
                return 404;
            }
            client_body_buffer_size 1m;
            client_body_timeout 1h;
            client_max_body_size 0;
            grpc_pass grpc://127.0.0.1:3002;
            grpc_read_timeout 1h;
            grpc_send_timeout 1h;
            grpc_set_header Host \$host;
            grpc_set_header X-Real-IP \$remote_addr;
        }

        location /trojangrpc
        {
            if (\$request_method != "POST")
            {
                return 404;
            }
            client_body_buffer_size 1m;
            client_body_timeout 1h;
            client_max_body_size 0;
            grpc_pass grpc://127.0.0.1:3003;
            grpc_read_timeout 1h;
            grpc_send_timeout 1h;
            grpc_set_header Host \$host;
            grpc_set_header X-Real-IP \$remote_addr;
        }

        location ~* /(sub|dashboard|api|docs|redoc|openapi.json)
        {
            proxy_redirect off;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_pass http://0.0.0.0:8000;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        }


        location /
        {
            add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
            root /var/www/html;
            index index.html index.htm;
        }
    }
}
EOF

mkdir -p /var/www/html
echo "<pre>Hello World!</pre>" > /var/www/html/index.html

#install socat
apt install iptables -y
apt install curl socat xz-utils wget apt-transport-https gnupg gnupg2 gnupg1 dnsutils lsb-release -y 
apt install socat cron bash-completion -y

#install cert
mkdir -p /var/lib/marzban/certs/$domain
curl https://get.acme.sh | sh -s
/root/.acme.sh/acme.sh --server letsencrypt --register-account -m helpers@lumine.my.id --issue -d $domain --standalone -k ec-256 --debug
~/.acme.sh/acme.sh --installcert -d $domain --fullchainpath /var/lib/marzban/certs/$domain/fullchain.cer --keypath /var/lib/marzban/certs/$domain/privkey.key --ecc



cat > "/var/lib/marzban/xray_config.json" << EOF
{
  "log": {
    "access": "/var/lib/marzban/access.log",
    "error": "/var/lib/marzban/error.log",
    "loglevel": "warning"
  },
  "dns": {
    "servers": [
      "1.1.1.1",
      "1.0.0.1",
      "8.8.8.8",
      "8.8.4.4",
      "127.0.0.1"
    ],
    "tag": "dns-in"
  },
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "inboundTag": [
          "dns-in"
        ],
        "outboundTag": "dns-out"
      },
      {
        "type": "field",
        "protocol": [
          "bittorent"
        ],
        "outboundTag": "block"
      }
    ]
  },
  "inbounds": [
    {
      "tag": "VLESS_WS",
      "listen": "127.0.0.1",
      "port": 20651,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/vlessws"
        },
        "security": "none"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "tag": "VMESS_WS",
      "listen": "127.0.0.1",
      "port": 20652,
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "security": "none",
        "wsSettings": {
          "path": "/vmessws"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "tag": "TROJAN_WS",
      "listen": "127.0.0.1",
      "port": 20653,
      "protocol": "trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/trojanws"
        },
        "security": "none"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "tag": "VLESS_HTTP_UPGRADE",
      "listen": "127.0.0.1",
      "port": 2021,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "httpupgrade",
        "security": "none",
        "httpupgradeSettings": {
          "path": "/vlesshu"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "tag": "VMESS_HTTP_UPGRADE",
      "listen": "127.0.0.1",
      "port": 2022,
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "httpupgrade",
        "security": "none",
        "httpupgradeSettings": {
          "path": "/vmesshu"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "tag": "TROJAN_HTTP_UPGRADE",
      "listen": "127.0.0.1",
      "port": 2023,
      "protocol": "trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "httpupgrade",
        "security": "none",
        "httpupgradeSettings": {
          "path": "/trojanhu"
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls"
        ]
      }
    },
    {
      "tag": "VLESS-gRPC",
      "listen": "127.0.0.1",
      "port": 3001,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "grpc",
        "security": "none",
        "grpcSettings": {
          "serviceName": "vlessgrpc"
        }
      }
    },
    {
      "tag": "VMESS-gRPC",
      "listen": "127.0.0.1",
      "port": 3002,
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "grpc",
        "security": "none",
        "grpcSettings": {
          "serviceName": "vmessgrpc"
        }
      }
    },
    {
      "tag": "TROJAN-gRPC",
      "listen": "127.0.0.1",
      "port": 3003,
      "protocol": "trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "grpc",
        "security": "none",
        "grpcSettings": {
          "serviceName": "trojangrpc"
        }
      }
    },
    {
      "tag": "SHADOWSOCKS_OUTLINE",
      "listen": "0.0.0.0",
      "port": 4001,
      "protocol": "shadowsocks",
      "settings": {
        "clients": [],
        "network": "tcp,udp"
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom",
      "settings": {
        "domainStrategy": "UseIPv4"
      }
    },
    {
      "tag": "block",
      "protocol": "blackhole",
      "settings": {
        "response": {
          "type": "http"
        }
      }
    },
   {
      "tag": "dns-out",
      "protocol": "dns",
      "settings": {
        "nonIPQuery": "skip"
      }
    }
  ]
}
EOF


#install firewall
apt install ufw -y
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 4001/tcp
sudo ufw allow 4001/udp
yes | sudo ufw enable

#install database
wget -O /var/lib/marzban/db.sqlite3 "https://github.com/claudialubowitz26/mar-lum/raw/main/db.sqlite3"

#install WARP Proxy
wget -O /root/warp "https://raw.githubusercontent.com/hamid-gh98/x-ui-scripts/main/install_warp_proxy.sh"
sudo chmod +x /root/warp
sudo bash /root/warp -y 

#finishing
apt autoremove -y
apt clean

cd
profile
echo "Lumine VPN"
echo "-=================================-"
echo "Untuk Tambahkan Admin Panel ketik : marzban cli admin create --sudo"
echo "URL Panel : https://${domain}/dashboard"
echo "-=================================-"
echo "Terimakasih"
echo "-=================================-"
colorized_echo green "Script telah berhasil di install"


rm /root/marzban.sh

colorized_echo blue "Menghapus admin bawaan db.sqlite"
marzban cli admin delete -u admin -y


echo -e "[\e[1;31mWARNING\e[0m] Apakah Ingin Reboot [default y](y/n)? "
read answer
if [ "$answer" == "${answer#[Yy]}" ] ;then
exit 0
else
cat /dev/null > ~/.bash_history && history -c && reboot
fi
