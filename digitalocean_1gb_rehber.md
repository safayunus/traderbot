# 🌊 DigitalOcean 1GB RAM Optimize Kurulum Rehberi

Bu rehber, **1 CPU, 1GB RAM, 35GB SSD** özelliklerine sahip DigitalOcean droplet'ında AI entegrasyonlu trading botunuzu nasıl kuracağınızı açıklar.

## ⚠️ Önemli Notlar

- **Swap ve Firewall ayarlarına dokunulmaz** (default kalır)
- **Memory-optimized** konfigürasyon kullanılır
- **AI özellikleri varsayılan olarak kapalı** (isteğe bağlı aktif edilebilir)
- **Container memory limit: 512MB**

## 🚀 Hızlı Kurulum

### 1. DigitalOcean Droplet Oluşturma

**Droplet Ayarları:**
- **Image**: Ubuntu 22.04 (LTS) x64
- **Size**: $6/mo - 1 GB RAM, 1 vCPU, 25 GB SSD
- **Region**: Frankfurt veya Amsterdam
- **Authentication**: SSH Key (önerilen)

### 2. SSH Bağlantısı ve Otomatik Kurulum

```bash
# Droplet'a bağlan
ssh root@YOUR_DROPLET_IP

# Kurulum scriptini indir ve çalıştır
wget https://raw.githubusercontent.com/your-repo/digitalocean_1gb_setup.sh
chmod +x digitalocean_1gb_setup.sh
./digitalocean_1gb_setup.sh
```

## 📋 Manuel Kurulum Adımları

### 1. Sistem Kontrolü

```bash
# Sistem bilgilerini kontrol et
free -h    # RAM: ~1GB olmalı
df -h      # Disk: ~25GB+ olmalı
nproc      # CPU: 1 core
```

### 2. Sistem Güncellemesi (Minimal)

```bash
# Sadece güvenlik güncellemeleri
apt update
apt upgrade -y --with-new-pkgs

# Gerekli araçları yükle
apt install -y curl wget git nano htop unzip ca-certificates gnupg lsb-release

# Temizlik
apt autoremove -y
apt autoclean
```

### 3. Lightweight Docker Kurulumu

```bash
# Eski Docker'ları kaldır
apt remove -y docker docker-engine docker.io containerd runc

# Docker repository ekle
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Minimal Docker yükle
apt update
apt install -y docker-ce docker-ce-cli containerd.io

# Docker Compose yükle
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Docker'ı başlat
systemctl start docker
systemctl enable docker
```

### 4. Docker Daemon Optimizasyonu

```bash
# 1GB RAM için Docker ayarları
cat > /etc/docker/daemon.json << 'EOF'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "default-ulimits": {
        "memlock": {
            "Hard": 67108864,
            "Name": "memlock",
            "Soft": 67108864
        }
    }
}
EOF

systemctl restart docker
```

### 5. Bot Klasörü ve Dosyalar

```bash
# Bot klasörünü oluştur
mkdir -p /opt/trading-bot
cd /opt/trading-bot
mkdir -p api data trading utils logs

# __init__.py dosyalarını oluştur
touch api/__init__.py data/__init__.py trading/__init__.py utils/__init__.py
```

### 6. Minimal Requirements.txt

```bash
cat > requirements.txt << 'EOF'
python-telegram-bot>=20.0
binance-python>=1.0.15
pandas>=1.3.0
numpy>=1.21.0
requests>=2.28.0
python-dotenv>=0.19.0
psutil>=5.8.0
# AI paketleri (isteğe bağlı - RAM kullanımını artırır)
# scikit-learn>=1.0.0
# joblib>=1.1.0
EOF
```

### 7. Memory-Optimized Dockerfile

```bash
cat > Dockerfile << 'EOF'
# Python 3.9 slim image (daha hafif)
FROM python:3.9-slim

WORKDIR /app

# Minimal sistem paketleri
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Python paketlerini yükle
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt \
    && pip cache purge

# Uygulama dosyalarını kopyala
COPY . .

# __init__.py dosyalarını oluştur
RUN touch api/__init__.py \
    && touch trading/__init__.py \
    && touch data/__init__.py \
    && touch utils/__init__.py

# Hafıza optimizasyonu
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Basit sağlık kontrolü
HEALTHCHECK --interval=60s --timeout=10s --start-period=10s --retries=2 \
    CMD python -c "import sys; sys.exit(0)" || exit 1

CMD ["python", "-u", "main.py"]
EOF
```

### 8. Lightweight Docker Compose

```bash
cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  trading-bot:
    build: .
    container_name: trading-bot-lite
    env_file: .env
    restart: unless-stopped
    volumes:
      - ./logs:/app/logs
      - ./data:/app/data
    environment:
      - PYTHONUNBUFFERED=1
      - TZ=Europe/Istanbul
    # 1GB RAM için memory limit
    mem_limit: 512m
    memswap_limit: 1g
    # CPU limit
    cpus: 0.8
    networks:
      - trading-network
    healthcheck:
      test: ["CMD", "python", "-c", "print('OK')"]
      interval: 60s
      timeout: 10s
      retries: 2
      start_period: 30s
    logging:
      driver: "json-file"
      options:
        max-size: "5m"
        max-file: "2"

networks:
  trading-network:
    driver: bridge
EOF
```

### 9. 1GB RAM Optimize .env

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
MAX_DAILY_TRADES=5

# 1GB RAM için optimize ayarlar
ENABLE_AI=False
ENABLE_BACKTESTING=False
LOG_LEVEL=INFO
EOF
```

## 🔧 Sistem Optimizasyonu

### 1. Gereksiz Servisleri Durdur

```bash
# Snapd'yi durdur (RAM tasarrufu)
systemctl disable snapd
systemctl stop snapd
```

### 2. Log Boyutlarını Sınırla

```bash
# Journal log boyutunu sınırla
mkdir -p /etc/systemd/journald.conf.d
cat > /etc/systemd/journald.conf.d/size.conf << 'EOF'
[Journal]
SystemMaxUse=100M
RuntimeMaxUse=50M
EOF
systemctl restart systemd-journald
```

### 3. Otomatik Temizlik

```bash
# Günlük temizlik scripti
cat > /etc/cron.daily/cleanup << 'EOF'
#!/bin/bash
apt autoremove -y
apt autoclean
docker system prune -f
journalctl --vacuum-time=7d
EOF
chmod +x /etc/cron.daily/cleanup
```

## 🚀 Bot'u Başlatma

### 1. Bot Kodlarını Kopyala

```bash
# Local bilgisayarınızdan
scp -r /path/to/your/bot/* root@YOUR_DROPLET_IP:/opt/trading-bot/
```

### 2. .env Dosyasını Düzenle

```bash
cd /opt/trading-bot
nano .env
# API anahtarlarınızı girin
```

### 3. Bot'u Başlat

```bash
# Image'ı build et
docker-compose build

# Bot'u başlat
docker-compose up -d

# Logları kontrol et
docker-compose logs -f
```

## 📊 1GB RAM Monitoring

### Memory Kullanımını İzleme

```bash
# Sistem memory
free -h

# Docker container memory
docker stats

# Bot container'ının detaylı bilgisi
docker exec trading-bot-lite cat /proc/meminfo
```

### Performans Optimizasyonu

```bash
# Container'ı yeniden başlat (memory temizliği için)
docker-compose restart

# Docker cache temizliği
docker system prune -f

# Log temizliği
docker-compose logs --tail=100 > /tmp/recent_logs.txt
```

## 🤖 AI Özelliklerini Aktif Etme

### 1. Requirements.txt'i Güncelle

```bash
# AI paketlerini aktif et
sed -i 's/# scikit-learn/scikit-learn/' requirements.txt
sed -i 's/# joblib/joblib/' requirements.txt
```

### 2. .env'de AI'ı Aktif Et

```bash
# .env dosyasında
ENABLE_AI=True
```

### 3. Yeniden Build Et

```bash
docker-compose down
docker-compose build
docker-compose up -d
```

**⚠️ Uyarı**: AI aktif edildiğinde memory kullanımı artacaktır. Yakından izleyin!

## 📱 Telegram Komutları

```
/start          # Bot bilgileri
/status         # Bot durumu
/debug          # Sistem testi
/start_bot      # Trading'i başlat
/stop_bot       # Trading'i durdur

# AI komutları (AI aktifse)
/ai_test        # AI modellerini test et
/ai_status      # AI durumu
```

## 🔧 Sorun Giderme

### Memory Yetersizliği

```bash
# Memory kullanımını kontrol et
free -h
docker stats

# Container'ı yeniden başlat
docker-compose restart

# Gereksiz container'ları temizle
docker container prune -f
```

### Container Başlamıyor

```bash
# Logları kontrol et
docker-compose logs trading-bot

# Interaktif başlat
docker run -it --env-file .env trading-bot-lite /bin/bash
```

### Disk Alanı Yetersizliği

```bash
# Disk kullanımını kontrol et
df -h

# Docker temizliği
docker system prune -a -f

# Log temizliği
journalctl --vacuum-time=3d
```

## 💰 1GB RAM Maliyet Analizi

**DigitalOcean Droplet:**
- **1GB RAM, 1 vCPU, 25GB SSD**: $6/mo
- **Bandwidth**: 1TB (ücretsiz)
- **Toplam**: ~$6/mo

**Avantajlar:**
- ✅ Çok düşük maliyet
- ✅ Basit trading stratejileri için yeterli
- ✅ 7/24 çalışma

**Dezavantajlar:**
- ⚠️ AI özellikleri sınırlı
- ⚠️ Backtesting yapılamaz
- ⚠️ Yakın monitoring gerekli

## 📋 1GB RAM Kontrol Listesi

- [ ] Droplet oluşturuldu (1GB RAM)
- [ ] SSH bağlantısı kuruldu
- [ ] `digitalocean_1gb_setup.sh` çalıştırıldı
- [ ] Bot kodları kopyalandı
- [ ] .env dosyası düzenlendi
- [ ] `docker-compose up -d` çalıştırıldı
- [ ] Memory kullanımı kontrol edildi
- [ ] Telegram'dan bot test edildi
- [ ] Trading başlatıldı

## 🎯 1GB RAM İçin Öneriler

### Başlangıç İçin:
1. **AI'ı kapalı tutun** (ENABLE_AI=False)
2. **Basit stratejiler kullanın** (EMA, SMA)
3. **Az işlem yapın** (MAX_DAILY_TRADES=5)
4. **Memory'yi yakından izleyin**

### İleriye Dönük:
1. **Droplet'ı upgrade edin** (2GB RAM'e çıkın)
2. **AI özelliklerini aktif edin**
3. **Backtesting ekleyin**
4. **Daha karmaşık stratejiler kullanın**

Bu rehberi takip ederek 1GB RAM'de başarıyla trading botunuzu çalıştırabilirsiniz! 🌊💻
