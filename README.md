# MarLum

Ini adalah [Marzban](https://github.com/Gozargah/Marzban) yang sudah saya tambahkan nginx untuk konfigurasi koneksi WebSocket, HTTP Upgrade dan gRPC single port. </br>
WebSocket sudah support untuk 443 TLS, 80 HTTP dan Wildcard path, contoh /enter-your-custom-path/trojan </br>
gRPC sudah support untuk 443 TLS </br>

Disclaimer: Proyek ini hanya untuk pembelajaran dan komunikasi pribadi, mohon jangan menggunakannya untuk tujuan ilegal. </br>
Credit aplikasi full to [Gozargah Marzban](https://github.com/Gozargah), saya hanya edit sedikit untuk instalasi sederhana bagi pemula . </br>

# Special Thanks to

- [Gozargah](https://github.com/Gozargah/Marzban)
- [hamid-gh98](https://github.com/hamid-gh98)
- [x0sina](https://github.com/x0sina/marzban-sub)
- [Marling](https://github.com/GawrAme/MarLing)

# List Protocol yang support

- VLess
- VMess
- Trojan

# Yang harus dipersiapkan

- VPS dengan minimal spek 1 Core 1 GB ram
- Domain yang sudah di pointing ke CloudFlare
- Pemahaman dasar perintah Linux

# Sistem VM yang dapat digunakan

- Debian 11 [**RECOMMENDED**] </br>
- Ubuntu 20.04 </br>

# Instalasi

```html
apt-get update && apt-get upgrade -y
```

Pastikan anda sudah login sebagai root sebelum menjalankan perintah dibawah

```html
wget https://raw.githubusercontent.com/claudialubowitz26/mar-lum/main/marzban.sh && chmod +x marzban.sh && ./marzban.sh
```

Buka panel Marzban dengan mengunjungi https://domainmu/dashboard <br>

Setelah instalasi berhasil, Panel login / Admin bisa ditambahkan dengan command

```html
marzban cli admin create --sudo
```

Jika ingin mengubah konfigurasi env variable

```html
nano /opt/marzban/.env
```

Perintah Restart service Marzban

```html
marzban restart
```

Perintah Cek Logs service Marzban

```html
marzban logs
```

Perintah Cek update service Marzban

```html
marzban update
```

# Cloudflare Sett

Pastikan SSL/TLS Setting pada cloudflare sudah di set menjadi full
![image](https://github.com/GawrAme/MarLing/assets/97426017/3aeedf09-308e-41b0-9640-50e4abb77aa0) </br>

Lalu pada tab **Network** pastikan gRPC dan WebSocket sudah ON
![image](https://github.com/GawrAme/MarLing/assets/97426017/65d9b413-fda4-478a-99a5-b33d8e5fec3d)

