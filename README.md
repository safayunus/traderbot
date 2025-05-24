# 🤖 Advanced Trading Bot

Gelişmiş Telegram tabanlı kripto para trading botu. Binance API entegrasyonu ile otomatik alım-satım, backtest, strateji optimizasyonu ve risk yönetimi özellikleri.

## 🚀 Özellikler

### 📊 Trading Stratejileri
- **EMA (Exponential Moving Average)** - Hızlı tepki, trend takibi
- **SMA (Simple Moving Average)** - Kararlı, düzgün sinyaller
- **RSI (Relative Strength Index)** - Aşırı alım/satım tespiti
- **MACD** - Trend ve momentum analizi
- **Konservatif Mod** - Düşük riskli, güvenli trading

### 🛡️ Risk Yönetimi
- Dinamik Stop Loss (ATR bazlı)
- Take Profit hedefleri
- Trailing Stop
- Günlük işlem limitleri
- Pozisyon büyüklüğü kontrolü
- Volatilite bazlı güvenlik kontrolleri

### 🧪 Analiz Araçları
- **Backtest** - Geçmiş veri ile strateji testi
- **Strateji Karşılaştırması** - Farklı stratejilerin performans analizi
- **Parametre Optimizasyonu** - En iyi ayarları bulma
- **Performans İstatistikleri** - Detaylı kar/zarar analizi

### 📱 Telegram Entegrasyonu
- Gerçek zamanlı bildirimler
- Uzaktan kontrol komutları
- Canlı durum takibi
- Ayar değişiklikleri

## 🔧 Kurulum

### Gereksinimler
- Python 3.9+
- Binance hesabı ve API anahtarları
- Telegram bot token

### 1. Projeyi İndirin
```bash
git clone <repository-url>
cd trading-bot
```

### 2. Sanal Ortam Oluşturun
```bash
python -m venv venv
source venv/bin/activate  # Linux/Mac
# veya
venv\Scripts\activate     # Windows
```

### 3. Bağımlılıkları Yükleyin
```bash
pip install -r requirements.txt
```

### 4. Çevre Değişkenlerini Ayarlayın
`.env` dosyasını oluşturun ve aşağıdaki bilgileri doldurun:

```env
# Binance API
BINANCE_API_KEY=your_binance_api_key
BINANCE_API_SECRET=your_binance_api_secret
BINANCE_TESTNET=False

# Telegram Bot
TELEGRAM_TOKEN=your_telegram_bot_token
TELEGRAM_USER_ID=your_telegram_user_id

# Trading Ayarları
DEFAULT_SYMBOL=BTCUSDT
DEFAULT_USDT_AMOUNT=10.0
DEFAULT_STRATEGY=EMA
DEFAULT_INTERVAL=1h

# Risk Yönetimi
PROFIT_THRESHOLD=1.5
STOP_LOSS=1.0
MAX_DAILY_TRADES=10
```

### 5. Botu Başlatın
```bash
python main.py
```

## 📱 Telegram Komutları

### 🎛️ Kontrol Komutları
- `/start` - Bot bilgileri ve durum
- `/status` - Detaylı durum raporu
- `/start_bot` - Trading'i başlat
- `/stop_bot` - Trading'i durdur
- `/debug` - Sistem testi

### ⚙️ Ayar Komutları
- `/set_stoploss [%]` - Stop loss oranını ayarla
- `/set_profit [%]` - Kar hedefini ayarla

### 🧪 Analiz Komutları
- `/backtest [gün]` - Backtest çalıştır (varsayılan: 30 gün)
- `/compare [gün]` - Stratejileri karşılaştır
- `/optimize` - Parametre optimizasyonu
- `/stats` - Performans istatistikleri

### 💡 Örnek Kullanım
```
/set_stoploss 1.5
/set_profit 2.0
/backtest 30
/compare 15
/optimize
```

## 🐳 Docker ile Çalıştırma

### Docker Build
```bash
docker build -t trading-bot .
```

### Docker Run
```bash
docker run -d --name trading-bot \
  --env-file .env \
  --restart unless-stopped \
  trading-bot
```

### Docker Compose
```yaml
version: '3.8'
services:
  trading-bot:
    build: .
    env_file: .env
    restart: unless-stopped
    volumes:
      - ./logs:/app/logs
```

## 📊 Strateji Açıklamaları

### EMA (Exponential Moving Average)
- **Avantajlar**: Hızlı tepki, trend değişimlerini erken yakalar
- **Dezavantajlar**: Daha fazla gürültü, yanlış sinyaller
- **Kullanım**: Hızlı piyasalarda, kısa vadeli trading

### SMA (Simple Moving Average)
- **Avantajlar**: Kararlı, düzgün sinyaller
- **Dezavantajlar**: Geç tepki, trend değişimlerini kaçırabilir
- **Kullanım**: Kararlı piyasalarda, uzun vadeli trading

### RSI (Relative Strength Index)
- **Avantajlar**: Aşırı alım/satım seviyelerini tespit eder
- **Dezavantajlar**: Trend piyasalarda yanıltıcı olabilir
- **Kullanım**: Yan trend piyasalarda, geri dönüş noktaları

### MACD
- **Avantajlar**: Hem trend hem momentum göstergesi
- **Dezavantajlar**: Gecikmeli sinyal
- **Kullanım**: Trend onayı, momentum analizi

## 🛡️ Güvenlik

### API Anahtarları
- API anahtarlarınızı asla kod içinde saklamayın
- `.env` dosyasını git'e eklemeyin
- Binance'de IP kısıtlaması kullanın
- Sadece gerekli izinleri verin (spot trading)

### Risk Yönetimi
- Küçük miktarlarla başlayın
- Stop loss kullanmayı unutmayın
- Günlük işlem limitlerini ayarlayın
- Testnet'te önce test edin

## 📈 Performans Optimizasyonu

### Backtest Kullanımı
```python
from trading.backtesting import BacktestEngine

engine = BacktestEngine(initial_balance=1000.0)
result = engine.run_backtest('BTCUSDT', 'EMA', '1h', 30)
```

### Strateji Karşılaştırması
```python
from trading.backtesting import run_strategy_comparison

results = run_strategy_comparison('BTCUSDT', days=30)
print(f"En iyi strateji: {results['best_strategy']}")
```

### Parametre Optimizasyonu
```python
from trading.backtesting import optimize_parameters

optimization = optimize_parameters('BTCUSDT', 'EMA')
best_params = optimization['best_params']
```

## 🔧 Geliştirme

### Yeni Strateji Ekleme
1. `trading/strategies.py` dosyasına yeni fonksiyon ekleyin
2. `generate_signals` fonksiyonuna entegre edin
3. Backtest ile test edin

### Yeni Gösterge Ekleme
1. `trading/indicators.py` dosyasına hesaplama fonksiyonu ekleyin
2. `calculate_indicators` fonksiyonuna entegre edin

### Telegram Komutu Ekleme
1. `api/telegram_api.py` dosyasına yeni fonksiyon ekleyin
2. `setup_telegram_bot` fonksiyonuna handler ekleyin

## 📝 Loglar

Bot detaylı loglar tutar:
- `trading_bot.log` - Genel bot aktiviteleri
- `errors.log` - Hata logları
- Console çıktısı - Gerçek zamanlı durum

## ⚠️ Uyarılar

- **Finansal Risk**: Kripto para trading risklidir
- **Test Edin**: Gerçek para ile başlamadan önce testnet kullanın
- **Küçük Başlayın**: İlk başta küçük miktarlarla test edin
- **Takip Edin**: Bot'u sürekli takip edin
- **Güncelleme**: Düzenli olarak güncellemeleri kontrol edin

## 📞 Destek

Sorunlar için:
1. Logları kontrol edin
2. GitHub Issues kullanın
3. Telegram'dan `/debug` komutu çalıştırın

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 🙏 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun
3. Değişikliklerinizi commit edin
4. Pull request gönderin

---

**⚠️ Sorumluluk Reddi**: Bu bot eğitim amaçlıdır. Finansal kayıplardan sorumlu değiliz. Kendi riskinizle kullanın.
