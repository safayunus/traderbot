# 🐳 Docker'da AI Entegrasyonu Rehberi

Bu rehber, Ubuntu Docker container'ında çalışan trading botunuza AI modellerini nasıl entegre edeceğinizi açıklar.

## 🔍 Mevcut Durum Kontrolü

### 1. Container Durumunu Kontrol Edin
```bash
docker ps -a | grep trading
```

### 2. Container'a Bağlanın
```bash
docker exec -it [CONTAINER_NAME] /bin/bash
```

## 🛑 Docker Container'ı Güvenli Durdurma

### Yöntem 1: Telegram Üzerinden (Önerilen)
Container içindeyken:
```
/stop_bot
```

### Yöntem 2: Container'ı Durdurma
```bash
# Container'ı durdur
docker stop [CONTAINER_NAME]

# Container'ı kaldır (opsiyonel)
docker rm [CONTAINER_NAME]
```

## 💾 Veri Yedekleme (Docker Volume)

### 1. Volume'ları Kontrol Edin
```bash
docker volume ls
docker inspect [CONTAINER_NAME]
```

### 2. Verileri Yedekleyin
```bash
# Container'dan host'a kopyala
docker cp [CONTAINER_NAME]:/app/trading_bot.log ./backup/
docker cp [CONTAINER_NAME]:/app/.env ./backup/
docker cp [CONTAINER_NAME]:/app/config.ini ./backup/
```

## 🔄 AI Entegrasyonu ile Yeniden Build

### 1. Dockerfile'ı Güncelleyin

Mevcut `Dockerfile`'ınıza AI paketlerini ekleyin:

```dockerfile
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

# Port tanımla (gerekirse)
EXPOSE 8080

# Sağlık kontrolü
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "from trading.pretrained_models import test_pretrained_models; test_pretrained_models()" || exit 1

# Uygulamayı başlat
CMD ["python", "-u", "main.py"]
```

### 2. Requirements.txt'i Güncelleyin

```txt
# Mevcut paketleriniz...
python-telegram-bot>=20.0
binance-python>=1.0.15
pandas>=1.3.0
numpy>=1.21.0
requests>=2.28.0

# AI paketleri
scikit-learn>=1.0.0
joblib>=1.1.0
```

### 3. Docker Image'ı Yeniden Build Edin

```bash
# Eski image'ı kaldır (opsiyonel)
docker rmi trading-bot:latest

# Yeni image'ı build et
docker build -t trading-bot:ai .
```

## 🚀 AI Entegrasyonlu Container'ı Başlatma

### 1. Basit Başlatma
```bash
docker run -d \
  --name trading-bot-ai \
  --env-file .env \
  --restart unless-stopped \
  trading-bot:ai
```

### 2. Volume ile Başlatma (Veri Kalıcılığı)
```bash
docker run -d \
  --name trading-bot-ai \
  --env-file .env \
  --restart unless-stopped \
  -v $(pwd)/logs:/app/logs \
  -v $(pwd)/data:/app/data \
  trading-bot:ai
```

### 3. Docker Compose ile Başlatma

`docker-compose.yml` dosyası oluşturun:

```yaml
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
    healthcheck:
      test: ["CMD", "python", "-c", "from trading.pretrained_models import test_pretrained_models; test_pretrained_models()"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

Başlatma:
```bash
docker-compose up -d
```

## 🧪 AI Entegrasyonu Test

### 1. Container'a Bağlanın
```bash
docker exec -it trading-bot-ai /bin/bash
```

### 2. AI Dosyalarını Kontrol Edin
```bash
ls -la trading/pretrained_models.py
ls -la trading/ai_integration.py
ls -la api/ai_telegram_commands.py
```

### 3. AI Paketlerini Test Edin
```bash
python -c "import requests, numpy, sklearn, joblib; print('AI packages OK')"
```

### 4. Telegram'dan Test Edin
```
/ai_test
```

## 🔧 Container İçinde Manuel AI Kurulumu

Eğer otomatik kurulum başarısız olursa:

### 1. Container'a Bağlanın
```bash
docker exec -it trading-bot-ai /bin/bash
```

### 2. AI Paketlerini Yükleyin
```bash
pip install requests numpy scikit-learn joblib
```

### 3. AI Setup'ını Çalıştırın
```bash
python setup_ai.py
```

### 4. Container'ı Yeniden Başlatın
```bash
exit
docker restart trading-bot-ai
```

## 📊 Container Monitoring

### 1. Logları İzleyin
```bash
docker logs -f trading-bot-ai
```

### 2. Container Kaynaklarını İzleyin
```bash
docker stats trading-bot-ai
```

### 3. Container İçindeki Process'leri İzleyin
```bash
docker exec trading-bot-ai ps aux
```

## 🔄 Güncelleme Süreci

### 1. Yeni Kod Değişiklikleri İçin
```bash
# Container'ı durdur
docker stop trading-bot-ai

# Image'ı yeniden build et
docker build -t trading-bot:ai .

# Container'ı yeniden başlat
docker run -d --name trading-bot-ai --env-file .env trading-bot:ai
```

### 2. Docker Compose ile Güncelleme
```bash
docker-compose down
docker-compose build
docker-compose up -d
```

## 🐳 Docker Compose Tam Konfigürasyon

```yaml
version: '3.8'

services:
  trading-bot:
    build: 
      context: .
      dockerfile: Dockerfile
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
```

## 🔧 Sorun Giderme

### Container Başlamıyor
```bash
# Logları kontrol et
docker logs trading-bot-ai

# Container'ı interaktif başlat
docker run -it --env-file .env trading-bot:ai /bin/bash
```

### AI Modelleri Çalışmıyor
```bash
# Container içinde test et
docker exec -it trading-bot-ai python -c "from trading.pretrained_models import test_pretrained_models; print(test_pretrained_models())"
```

### Network Sorunları
```bash
# Container'dan internet erişimini test et
docker exec -it trading-bot-ai curl -I https://api.alternative.me/fng/
```

### Memory/CPU Sorunları
```bash
# Container kaynak limitlerini ayarla
docker run -d \
  --name trading-bot-ai \
  --memory="512m" \
  --cpus="1.0" \
  --env-file .env \
  trading-bot:ai
```

## 📱 Telegram Komutları (Docker)

Container çalıştıktan sonra:

```
/ai_test          # AI modellerini test et
/ai_setup balanced # AI'ı aktif et
/ai_status        # AI durumunu kontrol et
/ai_analysis      # Piyasa analizi
/start_bot        # Trading'i başlat
```

## ⚠️ Docker Özel Uyarılar

1. **Network**: Container'ın internet erişimi olduğundan emin olun
2. **Volumes**: Önemli verileri volume'larda saklayın
3. **Environment**: .env dosyasının doğru mount edildiğini kontrol edin
4. **Resources**: AI modelleri için yeterli RAM (en az 512MB) ayırın
5. **Timezone**: Doğru timezone ayarını yapın

## 🎯 Başarılı Kurulum Kontrol Listesi

- [ ] Eski container durduruldu
- [ ] Veriler yedeklendi
- [ ] Dockerfile AI paketleri ile güncellendi
- [ ] Image yeniden build edildi
- [ ] Container AI entegrasyonu ile başlatıldı
- [ ] `/ai_test` başarılı
- [ ] `/ai_setup balanced` çalıştırıldı
- [ ] `/start_bot` ile trading başlatıldı

Bu rehberi takip ederek Docker container'ınızda AI entegrasyonunu başarıyla tamamlayabilirsiniz! 🐳🤖
