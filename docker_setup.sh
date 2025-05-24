#!/bin/bash

# Docker AI Setup Script
# Ubuntu Docker container'ında AI entegrasyonu için

set -e  # Hata durumunda çık

echo "🐳 Docker AI Entegrasyon Setup'ı Başlatılıyor..."
echo "=================================================="

# Renkli çıktı için
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

# Container adını al
get_container_name() {
    CONTAINER_NAME=$(docker ps --format "table {{.Names}}" | grep -E "(trading|bot)" | head -1)
    if [ -z "$CONTAINER_NAME" ]; then
        CONTAINER_NAME=$(docker ps -a --format "table {{.Names}}" | grep -E "(trading|bot)" | head -1)
    fi
    
    if [ -z "$CONTAINER_NAME" ]; then
        print_error "Trading bot container bulunamadı!"
        echo "Mevcut container'lar:"
        docker ps -a --format "table {{.Names}}\t{{.Status}}"
        read -p "Container adını manuel girin: " CONTAINER_NAME
    fi
    
    echo "$CONTAINER_NAME"
}

# Container durumunu kontrol et
check_container_status() {
    local container_name=$1
    
    if docker ps | grep -q "$container_name"; then
        echo "running"
    elif docker ps -a | grep -q "$container_name"; then
        echo "stopped"
    else
        echo "not_found"
    fi
}

# Veri yedekleme
backup_data() {
    local container_name=$1
    local backup_dir="backup_$(date +%Y%m%d_%H%M%S)"
    
    print_info "Veriler yedekleniyor..."
    
    mkdir -p "$backup_dir"
    
    # Container'dan dosyaları kopyala
    docker cp "$container_name:/app/trading_bot.log" "$backup_dir/" 2>/dev/null || print_warning "trading_bot.log bulunamadı"
    docker cp "$container_name:/app/.env" "$backup_dir/" 2>/dev/null || print_warning ".env bulunamadı"
    docker cp "$container_name:/app/config.ini" "$backup_dir/" 2>/dev/null || print_warning "config.ini bulunamadı"
    docker cp "$container_name:/app/bot_state.json" "$backup_dir/" 2>/dev/null || print_warning "bot_state.json bulunamadı"
    
    print_success "Yedekleme tamamlandı: $backup_dir"
    echo "$backup_dir"
}

# AI dosyalarını container'a kopyala
copy_ai_files() {
    local container_name=$1
    
    print_info "AI dosyaları container'a kopyalanıyor..."
    
    # AI dosyalarının varlığını kontrol et
    local ai_files=(
        "trading/pretrained_models.py"
        "trading/ai_integration.py"
        "api/ai_telegram_commands.py"
        "setup_ai.py"
    )
    
    for file in "${ai_files[@]}"; do
        if [ -f "$file" ]; then
            docker cp "$file" "$container_name:/app/$file"
            print_success "Kopyalandı: $file"
        else
            print_error "Dosya bulunamadı: $file"
            return 1
        fi
    done
    
    return 0
}

# Container içinde AI paketlerini yükle
install_ai_packages() {
    local container_name=$1
    
    print_info "AI paketleri yükleniyor..."
    
    docker exec "$container_name" pip install --no-cache-dir \
        requests>=2.28.0 \
        numpy>=1.21.0 \
        scikit-learn>=1.0.0 \
        joblib>=1.1.0
    
    if [ $? -eq 0 ]; then
        print_success "AI paketleri yüklendi"
        return 0
    else
        print_error "AI paket yükleme başarısız"
        return 1
    fi
}

# Container içinde AI setup çalıştır
run_ai_setup() {
    local container_name=$1
    
    print_info "AI entegrasyonu yapılıyor..."
    
    docker exec "$container_name" python setup_ai.py
    
    if [ $? -eq 0 ]; then
        print_success "AI entegrasyonu tamamlandı"
        return 0
    else
        print_warning "AI entegrasyonu başarısız (manuel kurulum gerekebilir)"
        return 1
    fi
}

# Container'ı yeniden başlat
restart_container() {
    local container_name=$1
    
    print_info "Container yeniden başlatılıyor..."
    
    docker restart "$container_name"
    
    if [ $? -eq 0 ]; then
        print_success "Container yeniden başlatıldı"
        return 0
    else
        print_error "Container yeniden başlatma başarısız"
        return 1
    fi
}

# AI test
test_ai() {
    local container_name=$1
    
    print_info "AI modelleri test ediliyor..."
    
    sleep 10  # Container'ın başlaması için bekle
    
    docker exec "$container_name" python -c "
from trading.pretrained_models import test_pretrained_models
try:
    results = test_pretrained_models()
    print('AI test başarılı!')
    for key, value in results.items():
        if value:
            print(f'✅ {key}: {value.get(\"signal\", \"OK\")}')
        else:
            print(f'❌ {key}: Failed')
except Exception as e:
    print(f'AI test hatası: {e}')
"
}

# Docker image yeniden build et
rebuild_image() {
    print_info "Docker image yeniden build ediliyor..."
    
    # Dockerfile'ı güncelle
    if [ -f "Dockerfile" ]; then
        # AI paketlerini Dockerfile'a ekle
        if ! grep -q "scikit-learn" Dockerfile; then
            print_info "Dockerfile AI paketleri ile güncelleniyor..."
            
            # AI paketleri satırını ekle
            sed -i '/RUN pip install --no-cache-dir -r requirements.txt/a\\n# AI paketlerini yükle\nRUN pip install --no-cache-dir \\\n    requests>=2.28.0 \\\n    numpy>=1.21.0 \\\n    scikit-learn>=1.0.0 \\\n    joblib>=1.1.0' Dockerfile
            
            print_success "Dockerfile güncellendi"
        fi
        
        # Image'ı build et
        docker build -t trading-bot:ai .
        
        if [ $? -eq 0 ]; then
            print_success "Docker image build edildi"
            return 0
        else
            print_error "Docker image build başarısız"
            return 1
        fi
    else
        print_error "Dockerfile bulunamadı"
        return 1
    fi
}

# Ana fonksiyon
main() {
    echo "🔍 Container durumu kontrol ediliyor..."
    
    # Container adını al
    CONTAINER_NAME=$(get_container_name)
    print_info "Container: $CONTAINER_NAME"
    
    # Container durumunu kontrol et
    STATUS=$(check_container_status "$CONTAINER_NAME")
    
    case $STATUS in
        "running")
            print_success "Container çalışıyor"
            
            # Telegram'dan bot'u durdur
            print_info "Telegram'dan /stop_bot komutu gönderin ve Enter'a basın"
            read -p "Bot durduruldu mu? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_warning "Bot durduruluyor..."
                docker exec "$CONTAINER_NAME" pkill -f "python.*main.py" || true
            fi
            
            # Veri yedekle
            BACKUP_DIR=$(backup_data "$CONTAINER_NAME")
            
            # AI dosyalarını kopyala
            if copy_ai_files "$CONTAINER_NAME"; then
                # AI paketlerini yükle
                if install_ai_packages "$CONTAINER_NAME"; then
                    # AI setup çalıştır
                    run_ai_setup "$CONTAINER_NAME"
                    
                    # Container'ı yeniden başlat
                    restart_container "$CONTAINER_NAME"
                    
                    # AI test
                    test_ai "$CONTAINER_NAME"
                else
                    print_error "AI paket yükleme başarısız"
                fi
            else
                print_error "AI dosyaları kopyalanamadı"
            fi
            ;;
            
        "stopped")
            print_warning "Container durdurulmuş"
            
            # Veri yedekle
            BACKUP_DIR=$(backup_data "$CONTAINER_NAME")
            
            # Container'ı başlat
            docker start "$CONTAINER_NAME"
            sleep 5
            
            # AI dosyalarını kopyala ve setup yap
            if copy_ai_files "$CONTAINER_NAME"; then
                install_ai_packages "$CONTAINER_NAME"
                run_ai_setup "$CONTAINER_NAME"
                restart_container "$CONTAINER_NAME"
                test_ai "$CONTAINER_NAME"
            fi
            ;;
            
        "not_found")
            print_warning "Container bulunamadı, yeni image build ediliyor..."
            
            if rebuild_image; then
                print_info "Yeni container başlatılıyor..."
                
                if [ -f ".env" ]; then
                    docker run -d \
                        --name trading-bot-ai \
                        --env-file .env \
                        --restart unless-stopped \
                        -v "$(pwd)/logs:/app/logs" \
                        -v "$(pwd)/data:/app/data" \
                        trading-bot:ai
                    
                    print_success "Container başlatıldı: trading-bot-ai"
                    
                    # Test
                    test_ai "trading-bot-ai"
                else
                    print_error ".env dosyası bulunamadı"
                fi
            fi
            ;;
    esac
    
    echo
    echo "=================================================="
    print_success "Docker AI Setup tamamlandı!"
    echo
    echo "📱 Sonraki adımlar:"
    echo "1. /ai_test - AI modellerini test edin"
    echo "2. /ai_setup balanced - AI'ı aktif edin"
    echo "3. /start_bot - Trading'i başlatın"
    echo
    if [ ! -z "$BACKUP_DIR" ]; then
        echo "💾 Yedek klasörü: $BACKUP_DIR"
    fi
    echo "📚 Detaylı rehber: docker_ai_setup.md"
}

# Script'i çalıştır
main "$@"
