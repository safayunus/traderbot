#!/bin/bash

# DigitalOcean Otomatik Kurulum Scripti
# Ubuntu 22.04 için AI entegrasyonlu trading bot kurulumu

set -e  # Hata durumunda çık

echo "🌊 DigitalOcean Trading Bot Kurulum Scripti"
echo "=============================================="

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
    
    # Minimum sistem gereksinimlerini kontrol et
    RAM_GB=$(free -g | awk '/^Mem:/ {print $2}')
    if [ "$RAM_GB" -lt 2 ]; then
        print_warning "RAM 2GB'dan az! AI modelleri için en az 2GB RAM önerilir."
        read -p "Devam etmek istiyor musunuz? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    print_success "Sistem kontrol edildi"
}

# Sistem güncellemesi
update_system() {
    print_header "Sistem Güncelleniyor..."
    
    apt update
    apt upgrade -y
    
    # Temel araçları yükle
    apt install -y curl wget git nano htop unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release
    
    print_success "Sistem güncellendi"
}

# Docker kurulumu
install_docker() {
    print_header "Docker Kuruluyor..."
    
    # Eski Docker sürümlerini kaldır
    apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # Docker repository ekle
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Docker'ı yükle
    apt update
    apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Docker'ı başlat
    systemctl start docker
    systemctl enable docker
    
    # Docker Compose'u yükle
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    
    # Test et
    docker --version
    docker-compose --version
    
    print_success "Docker kuruldu"
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

# Requirements.txt oluştur
create_requirements() {
    print_info "requirements.txt oluşturuluyor..."
    
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
    
    print_success "requirements.txt oluşturuldu"
}

# Dockerfile oluştur
create_dockerfile() {
    print_info "Dockerfile oluşturuluyor..."
    
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
    
    print_success "Dockerfile oluşturuldu"
}

# Docker Compose oluştur
create_docker_compose() {
    print_info "docker-compose.yml oluşturuluyor..."
    
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
    
    print_success "docker-compose.yml oluşturuldu"
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
MAX_DAILY_TRADES=10

# Opsiyonel AI API Anahtarları
LUNARCRUSH_API_KEY=your_lunarcrush_key_here
EOF
    
    # .env dosyasını kopyala
    cp .env.template .env
    
    print_success ".env template oluşturuldu"
}

# Firewall ayarları
setup_firewall() {
    print_header "Firewall Ayarlanıyor..."
    
    # UFW'yi yükle ve aktif et
    apt install -y ufw
    
    # Varsayılan kuralları ayarla
    ufw --force reset
    ufw default deny incoming
    ufw default allow outgoing
    
    # SSH portunu aç
    ufw allow ssh
    
    # HTTP/HTTPS portlarını aç (gerekirse)
    ufw allow 80
    ufw allow 443
    
    # UFW'yi aktif et
    ufw --force enable
    
    print_success "Firewall ayarlandı"
}

# Swap alanı oluştur
create_swap() {
    print_header "Swap Alanı Oluşturuluyor..."
    
    # Mevcut swap'ı kontrol et
    if swapon --show | grep -q "/swapfile"; then
        print_warning "Swap alanı zaten mevcut"
        return
    fi
    
    # 2GB swap oluştur
    fallocate -l 2G /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    
    # Kalıcı hale getir
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
    
    print_success "2GB swap alanı oluşturuldu"
}

# Otomatik başlatma ayarları
setup_autostart() {
    print_header "Otomatik Başlatma Ayarlanıyor..."
    
    # Docker'ın otomatik başlamasını sağla
    systemctl enable docker
    
    # Bot'un otomatik başlaması için crontab ekle
    (crontab -l 2>/dev/null; echo "@reboot cd /opt/trading-bot && docker-compose up -d") | crontab -
    
    print_success "Otomatik başlatma ayarlandı"
}

# Log rotasyonu ayarla
setup_log_rotation() {
    print_info "Log rotasyonu ayarlanıyor..."
    
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
    
    print_success "Log rotasyonu ayarlandı"
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
    print_header "DigitalOcean Trading Bot Kurulumu Başlıyor..."
    
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
    setup_firewall
    create_swap
    setup_autostart
    setup_log_rotation
    
    # Kullanıcı bilgilerini al
    get_user_input
    
    # Bot dosyalarını kontrol et
    check_bot_files
    
    echo
    print_header "Kurulum Tamamlandı!"
    echo
    print_success "✅ Docker kuruldu ve yapılandırıldı"
    print_success "✅ Bot klasörü oluşturuldu: /opt/trading-bot"
    print_success "✅ Firewall ayarlandı"
    print_success "✅ Swap alanı oluşturuldu"
    print_success "✅ Otomatik başlatma ayarlandı"
    
    echo
    print_info "📋 Sonraki Adımlar:"
    echo "1. Bot kodlarınızı /opt/trading-bot/ klasörüne kopyalayın"
    echo "2. .env dosyasını kontrol edin: nano /opt/trading-bot/.env"
    echo "3. Bot'u başlatın: cd /opt/trading-bot && docker-compose up -d"
    echo "4. Logları kontrol edin: docker-compose logs -f"
    echo "5. Telegram'dan test edin: /start"
    
    echo
    print_info "🔧 Yararlı Komutlar:"
    echo "• Bot durumu: docker-compose ps"
    echo "• Bot logları: docker-compose logs -f"
    echo "• Bot'u durdur: docker-compose down"
    echo "• Bot'u başlat: docker-compose up -d"
    echo "• Sistem kaynakları: htop"
    echo "• Disk kullanımı: df -h"
    
    echo
    print_info "📚 Detaylı rehber: digitalocean_kurulum.md"
    
    echo
    print_warning "⚠️ Önemli: .env dosyasındaki API anahtarlarınızı güvenli tutun!"
    
    # Server IP'sini göster
    SERVER_IP=$(curl -s ifconfig.me)
    echo
    print_info "🌐 Server IP: $SERVER_IP"
    print_info "🔑 SSH Bağlantı: ssh root@$SERVER_IP"
}

# Script'i çalıştır
main "$@"
