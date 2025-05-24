# 🌊 DigitalOcean Droplet Kurulum Rehberi

Bu rehber, DigitalOcean'da sıfırdan droplet oluşturup AI entegrasyonlu trading botunuzu nasıl kuracağınızı adım adım açıklar.

## 🚀 1. DigitalOcean Droplet Oluşturma

### A) DigitalOcean'a Giriş
1. [DigitalOcean](https://www.digitalocean.com) sitesine gidin
2. Hesabınıza giriş yapın veya yeni hesap oluşturun
3. Dashboard'a gidin

### B) Droplet Oluşturma
1. **"Create"** butonuna tıklayın
2. **"Droplets"** seçin

### C) Droplet Konfigürasyonu

**1. Choose an image:**
- **Ubuntu 22.04 (LTS) x64** seçin (önerilen)

**2. Choose Size:**
- **Basic Plan** seçin
- **Regular Intel** 
- **$12/mo - 2 GB RAM, 1 vCPU, 50 GB SSD** (minimum önerilen)
- **$24/mo - 4 GB RAM, 2 vCPU, 80 GB SSD** (AI için ideal)

**3. Choose a datacenter region:**
- **Frankfurt** veya **Amsterdam** (Türkiye'ye yakın)

**4. Authentication:**
- **SSH Key** (önerilen) veya **Password**
- SSH Key yoksa şimdi oluşturun

**5. Finalize and create:**
- **Hostname:** `trading-bot-server`
- **Tags:** `trading`, `bot`, `ai`
- **Create Droplet** butonuna tıklayın

## 🔑 2. SSH Bağlantısı Kurma

### A) SSH Key Oluşturma (Windows)
```bash
# PowerShell veya Git Bash'te
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"
```

### B) Droplet'a Bağlanma
```bash
# IP adresini DigitalOcean dashboard'dan alın
ssh root@YOUR_DROPLET_IP
```

### C) İlk Bağlantı
```bash
# Sistem güncellemesi
apt update && apt upgrade -y

# Temel araçları yükle
apt install -y curl wget git nano htop unzip
```

## 🐳 3. Docker Kurulumu

### A) Docker Engine Kurulumu
```bash
# Eski Docker sürümlerini kaldır
apt remove -y docker docker-engine docker.io containerd runc

# Docker repository ekle
apt update
apt install -y ca-certificates curl gnupg lsb-release

# Docker GPG key ekle
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Docker repository ekle
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Docker'ı yükle
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Docker'ı başlat ve otomatik başlatmayı aktif et
systemctl start docker
systemctl enable docker

# Docker versiyonunu kontrol et
docker --version
```

### B) Docker Compose Kurulumu
```bash
# Docker Compose'u yükle
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Çalıştırma izni ver
chmod +x /usr/local/bin/docker-compose

# Versiyonu kontrol et
docker-compose --version
```

## 📁 4. Bot Dosyalarını Sunucuya Aktarma

### A) Git ile Klonlama (Önerilen)
```bash
# Bot klasörünü oluştur
mkdir -p /opt/trading-bot
cd /opt/trading-bot

# Eğer GitHub'da repository varsa
git clone YOUR_REPOSITORY_URL .

# Veya dosyaları manuel olarak oluşturacaksanız
mkdir -p api data trading utils
```

### B) SCP ile Dosya Aktarma
```bash
# Local bilgisayarınızdan (Windows/Mac/Linux)
scp -r /path/to/your/bot/* root@YOUR_DROPLET_IP:/opt/trading-bot/
```

### C) Manuel Dosya Oluşturma
Eğer dosyalarınız yoksa, aşağıdaki komutları kullanarak oluşturun:

```bash
cd /opt/trading-bot

# Ana dosyaları oluştur
nano main.py
nano requirements.txt
nano Dockerfile
nano docker-compose.yml
nano .env
```

## 🔧 5. Bot Dosyalarını Hazırlama

### A) requirements.txt Oluşturma
```bash
cd /opt/trading-bot
cat > requirements.txt << 'EOF'
python-telegram-bot>=20.0
binance-python>=1.0.15
pandas>=1.3.0
numpy>=1.21.0
requests>=2.28.0
scikit-learn>=1.0.0
joblib>=1.1.0
python-dotenv>=0.19.0
psutil>=5.8.0
EOF
```

### B) Dockerfile Oluşturma
```bash
cat > Dockerfile << 'EOF'
# Python 3.9 slim image kullan
FROM python:3.9-slim

# Çalışma dizinini ayarla
WORKDIR /app

# Sistem paketlerini güncelle ve gerekli araçları yükle
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Python requirements'ı kopyala ve yükle
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# AI paketlerini yükle
RUN pip install --no-cache-dir \
    requests>=2.28.0 \
    numpy>=1.21.0 \
    scikit-learn>=1.0.0 \
    joblib>=1.1.0

# Uygulama dosyalarını kopyala
COPY . .

# __init__.py dosyalarını oluştur
RUN touch api/__init__.py
RUN touch trading/__init__.py
RUN touch data/__init__.py
RUN touch utils/__init__.py

# AI entegrasyonunu çalıştır
RUN python setup_ai.py || echo "AI setup failed, continuing..."

# Port tanımla
EXPOSE 8080

# Sağlık kontrolü
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "from api.binance_api import get_current_price; print('OK' if get_current_price('BTCUSDT') else 'FAIL')" || exit 1

# Uygulamayı başlat
CMD ["python", "-u", "main.py"]
EOF
```

### C) docker-compose.yml Oluşturma
```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  trading-bot:
    build: .
    container_name: trading-bot-ai
    env_file: .env
    restart: unless-stopped
    volumes:
      - ./logs:/app/logs
      - ./data:/app/data
      - ./backup:/app/backup
    environment:
      - PYTHONUNBUFFERED=1
      - TZ=Europe/Istanbul
    networks:
      - trading-network
    healthcheck:
      test: ["CMD", "python", "-c", "from api.binance_api import get_current_price; print('OK' if get_current_price('BTCUSDT') else 'FAIL')"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

networks:
  trading-network:
    driver: bridge
EOF
```

### D) .env Dosyası Oluşturma
```bash
cat > .env << 'EOF'
# Binance API
BINANCE_API_KEY=your_binance_api_key_here
BINANCE_API_SECRET=your_binance_api_secret_here
BINANCE_TESTNET=False

# Telegram Bot
TELEGRAM_TOKEN=your_telegram_bot_token_here
TELEGRAM_USER_ID=your_telegram_user_id_here

# Trading Ayarları
DEFAULT_SYMBOL=BTCUSDT
DEFAULT_USDT_AMOUNT=10.0
DEFAULT_STRATEGY=EMA
DEFAULT_INTERVAL=1h

# Risk Yönetimi
PROFIT_THRESHOLD=1.5
STOP_LOSS=1.0
MAX_DAILY_TRADES=10

# Opsiyonel AI API Anahtarları
LUNARCRUSH_API_KEY=your_lunarcrush_key_here
EOF

# .env dosyasını düzenle
nano .env
```

## 📂 6. Bot Kodlarını Ekleme

### A) Ana Dosyaları Oluşturma
```bash
# Ana klasörleri oluştur
mkdir -p api data trading utils

# __init__.py dosyalarını oluştur
touch api/__init__.py data/__init__.py trading/__init__.py utils/__init__.py
```

### B) Dosyaları Kopyalama
Eğer local bilgisayarınızda bot kodları varsa:

```bash
# Local'den server'a kopyala (local bilgisayarınızdan çalıştırın)
scp -r api/ root@YOUR_DROPLET_IP:/opt/trading-bot/
scp -r data/ root@YOUR_DROPLET_IP:/opt/trading-bot/
scp -r trading/ root@YOUR_DROPLET_IP:/opt/trading-bot/
scp -r utils/ root@YOUR_DROPLET_IP:/opt/trading-bot/
scp main.py root@YOUR_DROPLET_IP:/opt/trading-bot/
scp setup_ai.py root@YOUR_DROPLET_IP:/opt/trading-bot/
```

### C) Dosya İzinlerini Ayarlama
```bash
cd /opt/trading-bot

# Dosya sahipliğini ayarla
chown -R root:root .

# Çalıştırma izinlerini ver
chmod +x setup_ai.py
chmod +x docker_setup.sh 2>/dev/null || true

# Log klasörünü oluştur
mkdir -p logs data backup
```

## 🚀 7. Bot'u Başlatma

### A) Docker Image Build Etme
```bash
cd /opt/trading-bot

# Image'ı build et
docker-compose build

# Build durumunu kontrol et
docker images | grep trading
```

### B) Bot'u Başlatma
```bash
# Bot'u başlat
docker-compose up -d

# Container durumunu kontrol et
docker-compose ps

# Logları kontrol et
docker-compose logs -f
```

### C) AI Entegrasyonu Test
```bash
# Container'a bağlan
docker exec -it trading-bot-ai /bin/bash

# AI dosyalarını kontrol et
ls -la trading/pretrained_models.py
ls -la trading/ai_integration.py

# AI paketlerini test et
python -c "import requests, numpy, sklearn, joblib; print('AI packages OK')"

# Container'dan çık
exit
```

## 🔧 8. Sistem Yönetimi

### A) Firewall Ayarları
```bash
# UFW firewall'ı aktif et
ufw enable

# SSH portunu aç (22)
ufw allow ssh

# HTTP/HTTPS portlarını aç (gerekirse)
ufw allow 80
ufw allow 443

# Firewall durumunu kontrol et
ufw status
```

### B) Sistem Monitoring
```bash
# Sistem kaynaklarını kontrol et
htop

# Disk kullanımını kontrol et
df -h

# Docker container'ları izle
docker stats

# Bot loglarını izle
docker-compose logs -f trading-bot
```

### C) Otomatik Başlatma
```bash
# Docker'ın sistem başlangıcında çalışmasını sağla
systemctl enable docker

# Bot'un otomatik başlaması için
cd /opt/trading-bot
echo "@reboot cd /opt/trading-bot && docker-compose up -d" | crontab -
```

## 📱 9. Telegram'dan Test

Bot başladıktan sonra Telegram'dan test edin:

```
/start          # Bot bilgileri
/debug          # Sistem testi
/ai_test        # AI modellerini test et
/ai_setup balanced  # AI'ı aktif et
/status         # Bot durumu
/start_bot      # Trading'i başlat
```

## 🔄 10. Güncelleme ve Bakım

### A) Bot Güncellemesi
```bash
cd /opt/trading-bot

# Bot'u durdur
docker-compose down

# Kodu güncelle (git varsa)
git pull

# Yeniden build et ve başlat
docker-compose build
docker-compose up -d
```

### B) Sistem Güncellemesi
```bash
# Sistem paketlerini güncelle
apt update && apt upgrade -y

# Docker'ı güncelle
apt install docker-ce docker-ce-cli containerd.io

# Sistem yeniden başlatma (gerekirse)
reboot
```

### C) Backup Alma
```bash
# Bot verilerini yedekle
cd /opt/trading-bot
tar -czf backup_$(date +%Y%m%d_%H%M%S).tar.gz logs/ data/ .env

# Backup'ı güvenli yere kopyala
scp backup_*.tar.gz user@backup-server:/backups/
```

## 🔧 11. Sorun Giderme

### A) Container Başlamıyor
```bash
# Logları kontrol et
docker-compose logs trading-bot

# Container'ı interaktif başlat
docker run -it --env-file .env trading-bot:latest /bin/bash
```

### B) AI Modelleri Çalışmıyor
```bash
# Container içinde test et
docker exec -it trading-bot-ai python -c "
from trading.pretrained_models import test_pretrained_models
print(test_pretrained_models())
"
```

### C) Network Sorunları
```bash
# Internet bağlantısını test et
curl -I https://api.binance.com/api/v3/ping

# DNS'i test et
nslookup api.binance.com
```

## 📋 12. Kurulum Kontrol Listesi

- [ ] DigitalOcean droplet oluşturuldu
- [ ] SSH bağlantısı kuruldu
- [ ] Sistem güncellendi
- [ ] Docker kuruldu
- [ ] Bot dosyaları sunucuya aktarıldı
- [ ] .env dosyası düzenlendi
- [ ] Docker image build edildi
- [ ] Container başlatıldı
- [ ] AI entegrasyonu test edildi
- [ ] Telegram'dan bot test edildi
- [ ] Firewall ayarlandı
- [ ] Otomatik başlatma ayarlandı

## 🎯 13. Performans Optimizasyonu

### A) Droplet Boyutunu Artırma
```bash
# DigitalOcean dashboard'dan droplet'ı resize edin
# 4GB RAM önerilir AI modelleri için
```

### B) Swap Alanı Ekleme
```bash
# 2GB swap oluştur
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile

# Kalıcı hale getir
echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
```

### C) Log Rotasyonu
```bash
# Logrotate konfigürasyonu
cat > /etc/logrotate.d/trading-bot << 'EOF'
/opt/trading-bot/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF
```

Bu rehberi takip ederek DigitalOcean'da sıfırdan AI entegrasyonlu trading botunuzu kurabilirsiniz! 🌊🤖
