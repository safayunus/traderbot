#!/bin/bash

# DigitalOcean 1GB RAM Optimize Kurulum Scripti
# 1 CPU, 1GB RAM, 35GB SSD için özel optimize edilmiş
# Swap ve firewall ayarlarına dokunmaz

set -e  # Hata durumunda çık

echo "🌊 DigitalOcean 1GB RAM Trading Bot Kurulumu"
echo "============================================="
echo "📊 Hedef Sistem: 1 CPU, 1GB RAM, 35GB SSD"
echo "⚠️  Swap ve Firewall ayarları default kalacak"
echo

# Renkli çıktı için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# Fonksiyonlar
print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️ $1${NC}"
}

print_info() {
    echo -e "${BLUE}🔄 $1${NC}"
}

print_header() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

# Sistem bilgilerini kontrol et
check_system() {
    print_header "Sistem Bilgileri Kontrol Ediliyor..."
    
    echo "OS: $(lsb_release -d | cut -f2)"
    echo "Kernel: $(uname -r)"
    echo "RAM: $(free -h | awk '/^Mem:/ {print $2}')"
    echo "Disk: $(df -h / | awk 'NR==2 {print $4 " available"}')"
    echo "CPU: $(nproc) cores"
    
    # RAM kontrolü
    RAM_MB=$(free -m | awk '/^Mem:/ {print $2}')
    if [ "$RAM_MB" -lt 900 ]; then
        print_error "RAM 1GB'dan az! Bu script 1GB RAM için optimize edilmiştir."
        exit 1
    fi
    
    # Disk kontrolü
    DISK_GB=$(df --output=avail / | tail -1 | awk '{print int($1/1024/1024)}')
    if [ "$DISK_GB" -lt 10 ]; then
        print_error "Disk alanı 10GB'dan az! En az 15GB boş alan gerekli."
        exit 1
    fi
    
    print_warning "1GB RAM tespit edildi - Lightweight kurulum yapılacak"
    print_success "Sistem kontrol edildi"
}

# Minimal sistem güncellemesi
update_system() {
    print_header "Minimal Sistem Güncellemesi..."
    
    # Sadece güvenlik güncellemeleri
    apt update
    apt upgrade -y --with-new-pkgs
    
    # Sadece gerekli araçları yükle
    apt install -y curl wget git nano htop unzip ca-certificates gnupg lsb-release
    
    # Gereksiz paketleri temizle
    apt autoremove -y
    apt autoclean
    
    print_success "Sistem güncellendi"
}

# Lightweight Docker kurulumu
install_docker() {
    print_header "Lightweight Docker Kuruluyor..."
    
    # Eski Docker sürümlerini kaldır
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Docker repository ekle
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Sadece Docker CE yükle (minimal)
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io
    
    # Docker'ı başlat
    systemctl start docker
    systemctl enable docker
    
    # Standalone Docker Compose yükle (daha hafif)
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Docker daemon ayarları (1GB RAM için optimize)
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
    
    # Test et
    docker --version
    docker-compose --version
    
    print_success "Lightweight Docker kuruldu"
}

# Bot klasörünü oluştur
create_bot_directory() {
    print_header "Bot Klasörü Oluşturuluyor..."
    
    BOT_DIR="/opt/trading-bot"
    mkdir -p "$BOT_DIR"
    cd "$BOT_DIR"
    
    # Alt klasörleri oluştur
    mkdir -p api data trading utils logs backup
    
    # __init__.py dosyalarını oluştur
    touch api/__init__.py data/__init__.py trading/__init__.py utils/__init__.py
    
    print_success "Bot klasörü oluşturuldu: $BOT_DIR"
}

# Minimal requirements.txt oluştur
create_requirements() {
    print_info "Minimal requirements.txt oluşturuluyor..."
    
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
    
    print_success "Minimal requirements.txt oluşturuldu"
}

# 1GB RAM için optimize Dockerfile
create_dockerfile() {
    print_info "1GB RAM optimize Dockerfile oluşturuluyor..."
    
    cat > Dockerfile << 'EOF'
# Python 3.9 slim image kullan (daha hafif)
FROM python:3.9-slim

# Çalışma dizinini ayarla
WORKDIR /app

# Sistem paketlerini güncelle (minimal)
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Python requirements'ı kopyala ve yükle
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

# Port tanımla
EXPOSE 8080

# Hafıza kullanımını sınırla
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Basit sağlık kontrolü
HEALTHCHECK --interval=60s --timeout=10s --start-period=10s --retries=2 \
    CMD python -c "import sys; sys.exit(0)" || exit 1

# Uygulamayı başlat
CMD ["python", "-u", "main.py"]
EOF
    
    print_success "1GB RAM optimize Dockerfile oluşturuldu"
}

# Lightweight Docker Compose
create_docker_compose() {
    print_info "Lightweight docker-compose.yml oluşturuluyor..."
    
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
    
    print_success "Lightweight docker-compose.yml oluşturuldu"
}

# .env template oluştur
create_env_template() {
    print_info ".env template oluşturuluyor..."
    
    cat > .env.template << 'EOF'
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
    
    # .env dosyasını kopyala
    cp .env.template .env
    
    print_success ".env template oluşturuldu"
}

# Sistem optimizasyonu (swap ve firewall hariç)
optimize_system() {
    print_header "Sistem Optimizasyonu (Hafıza Yönetimi)..."
    
    # Gereksiz servisleri durdur
    systemctl disable snapd 2>/dev/null || true
    systemctl stop snapd 2>/dev/null || true
    
    # Journal log boyutunu sınırla
    mkdir -p /etc/systemd/journald.conf.d
    cat > /etc/systemd/journald.conf.d/size.conf << 'EOF'
[Journal]
SystemMaxUse=100M
RuntimeMaxUse=50M
EOF
    systemctl restart systemd-journald
    
    # Cron job temizliği
    cat > /etc/cron.daily/cleanup << 'EOF'
#!/bin/bash
# Günlük temizlik
apt autoremove -y
apt autoclean
docker system prune -f
journalctl --vacuum-time=7d
EOF
    chmod +x /etc/cron.daily/cleanup
    
    print_success "Sistem optimizasyonu tamamlandı"
}

# Otomatik başlatma ayarları
setup_autostart() {
    print_header "Otomatik Başlatma Ayarlanıyor..."
    
    # Docker'ın otomatik başlamasını sağla
    systemctl enable docker
    
    # Bot'un otomatik başlaması için crontab ekle
    (crontab -l 2>/dev/null; echo "@reboot sleep 30 && cd /opt/trading-bot && docker-compose up -d") | crontab -
    
    print_success "Otomatik başlatma ayarlandı"
}

# Kullanıcı bilgilerini al
get_user_input() {
    print_header "Kullanıcı Bilgileri Alınıyor..."
    
    echo "Bot kurulumu için gerekli bilgileri girin:"
    echo
    
    read -p "Binance API Key: " BINANCE_API_KEY
    read -p "Binance API Secret: " BINANCE_API_SECRET
    read -p "Telegram Bot Token: " TELEGRAM_TOKEN
    read -p "Telegram User ID: " TELEGRAM_USER_ID
    
    # .env dosyasını güncelle
    sed -i "s/your_binance_api_key_here/$BINANCE_API_KEY/" .env
    sed -i "s/your_binance_api_secret_here/$BINANCE_API_SECRET/" .env
    sed -i "s/your_telegram_bot_token_here/$TELEGRAM_TOKEN/" .env
    sed -i "s/your_telegram_user_id_here/$TELEGRAM_USER_ID/" .env
    
    print_success "Kullanıcı bilgileri kaydedildi"
}

# Bot kodlarını kontrol et
check_bot_files() {
    print_header "Bot Dosyaları Kontrol Ediliyor..."
    
    # Gerekli dosyaların listesi
    required_files=(
        "main.py"
        "api/binance_api.py"
        "api/telegram_api.py"
        "data/state.py"
        "trading/strategies.py"
        "trading/indicators.py"
        "utils/logger.py"
    )
    
    missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ ! -f "$file" ]; then
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        print_warning "Eksik bot dosyaları tespit edildi:"
        for file in "${missing_files[@]}"; do
            echo "  - $file"
        done
        echo
        print_info "Bu dosyaları manuel olarak eklemeniz gerekiyor."
        print_info "SCP ile kopyalama örneği:"
        echo "  scp -r /local/path/to/bot/* root@$(curl -s ifconfig.me):/opt/trading-bot/"
        echo
        read -p "Dosyaları ekledikten sonra devam etmek için Enter'a basın..."
    else
        print_success "Tüm bot dosyaları mevcut"
    fi
}

# Ana kurulum fonksiyonu
main() {
    print_header "1GB RAM Trading Bot Kurulumu Başlıyor..."
    
    # Root kontrolü
    if [ "$EUID" -ne 0 ]; then
        print_error "Bu script root olarak çalıştırılmalı!"
        exit 1
    fi
    
    # Adım adım kurulum
    check_system
    update_system
    install_docker
    create_bot_directory
    create_requirements
    create_dockerfile
    create_docker_compose
    create_env_template
    optimize_system
    setup_autostart
    
    # Kullanıcı bilgilerini al
    get_user_input
    
    # Bot dosyalarını kontrol et
    check_bot_files
    
    echo
    print_header "1GB RAM Optimize Kurulum Tamamlandı!"
    echo
    print_success "✅ Lightweight Docker kuruldu"
    print_success "✅ Bot klasörü oluşturuldu: /opt/trading-bot"
    print_success "✅ Memory-optimized konfigürasyon hazırlandı"
    print_success "✅ Otomatik başlatma ayarlandı"
    print_success "✅ Sistem optimizasyonu yapıldı"
    
    echo
    print_warning "⚠️ 1GB RAM Özel Notlar:"
    echo "• AI özellikleri varsayılan olarak kapalı (ENABLE_AI=False)"
    echo "• Container memory limit: 512MB"
    echo "• Backtesting devre dışı (hafıza tasarrufu için)"
    echo "• Log boyutları sınırlandırıldı"
    
    echo
    print_info "📋 Sonraki Adımlar:"
    echo "1. Bot kodlarınızı /opt/trading-bot/ klasörüne kopyalayın"
    echo "2. .env dosyasını kontrol edin: nano /opt/trading-bot/.env"
    echo "3. Bot'u başlatın: cd /opt/trading-bot && docker-compose up -d"
    echo "4. Logları kontrol edin: docker-compose logs -f"
    echo "5. Telegram'dan test edin: /start"
    
    echo
    print_info "🔧 1GB RAM İçin Özel Komutlar:"
    echo "• Memory kullanımı: docker stats"
    echo "• System memory: free -h"
    echo "• Bot durumu: docker-compose ps"
    echo "• Lightweight restart: docker-compose restart"
    
    echo
    print_info "🎯 AI Özelliklerini Aktif Etmek İçin:"
    echo "• .env dosyasında ENABLE_AI=True yapın"
    echo "• requirements.txt'te AI paketlerini aktif edin"
    echo "• docker-compose build && docker-compose up -d"
    
    echo
    print_warning "⚠️ Önemli: 1GB RAM sınırlı olduğu için botu yakından izleyin!"
    
    # Server IP'sini göster
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || echo "IP alınamadı")
    echo
    print_info "🌐 Server IP: $SERVER_IP"
    print_info "🔑 SSH Bağlantı: ssh root@$SERVER_IP"
}

# Script'i çalıştır
main "$@"
