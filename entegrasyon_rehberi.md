# 🤖 AI Model Entegrasyon Rehberi

Bu rehber, pre-trained AI modellerini trading botunuza nasıl entegre edeceğinizi adım adım açıklar.

## 📋 Entegrasyon Adımları

### 1. Ana Trading Executor'ı Güncelle

`trading/executor.py` dosyasında şu değişikliği yapın:

**MEVCUT KOD (Satır ~45):**
```python
# Sinyalleri üret
signals = generate_signals(
    df, 
    strategy=bot_status["strategy"],
    last_action=bot_status["last_action"]
)
```

**YENİ KOD:**
```python
# AI Enhanced sinyalleri üret
try:
    from trading.ai_integration import get_ai_enhanced_signals
    signals = get_ai_enhanced_signals(
        df, 
        strategy=bot_status["strategy"],
        last_action=bot_status["last_action"]
    )
except ImportError:
    # Fallback: Klasik sinyaller
    from trading.strategies import generate_signals
    signals = generate_signals(
        df, 
        strategy=bot_status["strategy"],
        last_action=bot_status["last_action"]
    )
```

### 2. Telegram API'ye AI Komutlarını Ekle

`api/telegram_api.py` dosyasında şu değişiklikleri yapın:

**A) Import ekleyin (dosyanın başına):**
```python
# Mevcut importların altına ekleyin
from api.ai_telegram_commands import (
    ai_enable_command, ai_disable_command, ai_status_command,
    ai_test_command, ai_analysis_command, ai_setup_command,
    ai_weights_command, ai_recommend_command
)
```

**B) setup_telegram_bot() fonksiyonunda komutları ekleyin:**

`application.add_handler(CommandHandler("stats", stats_command))` satırının altına ekleyin:

```python
# AI komutları
application.add_handler(CommandHandler("ai_enable", ai_enable_command))
application.add_handler(CommandHandler("ai_disable", ai_disable_command))
application.add_handler(CommandHandler("ai_status", ai_status_command))
application.add_handler(CommandHandler("ai_test", ai_test_command))
application.add_handler(CommandHandler("ai_analysis", ai_analysis_command))
application.add_handler(CommandHandler("ai_setup", ai_setup_command))
application.add_handler(CommandHandler("ai_weights", ai_weights_command))
application.add_handler(CommandHandler("ai_recommend", ai_recommend_command))
```

**C) Help komutunu güncelleyin:**

`help_command` fonksiyonundaki help_text'e ekleyin:

```python
help_text = """📚 KOMUTLAR:

🎛️ Kontrol:
- /start - Bot bilgileri
- /status - Detaylı durum
- /start_bot - Trading başlat
- /stop_bot - Trading durdur
- /debug - Sistem testi

⚙️ Ayarlar:
- /set_stoploss [%] - Stop loss ayarla
- /set_profit [%] - Kar hedefi ayarla

🧪 Analiz:
- /backtest [gün] - Backtest çalıştır
- /compare [gün] - Stratejileri karşılaştır
- /optimize - Parametre optimizasyonu
- /stats - İstatistikler

🤖 AI Komutları:
- /ai_setup [mod] - AI kurulumu
- /ai_enable - AI'ı aktif et
- /ai_status - AI durumu
- /ai_analysis - Piyasa analizi
- /ai_test - AI test

💡 Örnekler:
/ai_setup balanced
/ai_analysis"""
```

### 3. Requirements.txt Güncelle

`requirements.txt` dosyasına şu kütüphaneleri ekleyin:

```
requests>=2.28.0
numpy>=1.21.0
scikit-learn>=1.0.0
joblib>=1.1.0
```

### 4. .env Dosyasına Opsiyonel API Anahtarları Ekle

`.env` dosyasına isteğe bağlı olarak ekleyebilirsiniz:

```env
# Opsiyonel AI API Anahtarları
LUNARCRUSH_API_KEY=your_lunarcrush_key_here
```

## 🚀 Kullanım

### Hızlı Başlangıç

1. **AI'ı aktif edin:**
   ```
   /ai_setup balanced
   ```

2. **Test edin:**
   ```
   /ai_test
   ```

3. **Analiz yapın:**
   ```
   /ai_analysis
   ```

4. **Trading'i başlatın:**
   ```
   /start_bot
   ```

### AI Modları

- **Conservative**: `/ai_setup conservative` - Güvenli
- **Balanced**: `/ai_setup balanced` - Dengeli (önerilen)
- **Aggressive**: `/ai_setup aggressive` - Agresif

### Manuel Ağırlık Ayarı

```
/ai_weights 0.3 0.5 0.2
```
(Klasik 30%, AI 50%, Konservatif 20%)

## 🔧 Sorun Giderme

### Hata: "Module not found"
```bash
pip install requests numpy scikit-learn joblib
```

### Hata: "API connection failed"
- İnternet bağlantınızı kontrol edin
- `/ai_test` komutu ile servisleri test edin

### AI sinyalleri gelmiyor
1. `/ai_status` ile durumu kontrol edin
2. `/ai_enable` ile aktif edin
3. `/ai_test` ile servisleri test edin

## 📊 AI Nasıl Çalışır?

### 1. Veri Toplama
- TradingView'dan teknik analiz
- Alternative.me'den Fear & Greed Index
- CoinGlass'tan funding rates
- CryptoCompare'den social sentiment

### 2. Ensemble Karar
```
Final Signal = 
  Klasik Strateji × Ağırlık1 +
  Pre-trained AI × Ağırlık2 +
  Konservatif × Ağırlık3
```

### 3. Güven Kontrolü
- Sadece %60+ güven seviyesindeki sinyaller işlenir
- Çoklu kaynak onayı gerekli

## 🎯 Beklenen Sonuçlar

- **Daha az yanlış sinyal**
- **Piyasa sentiment'ine duyarlılık**
- **Çoklu kaynak doğrulaması**
- **Otomatik risk yönetimi**

## ⚠️ Önemli Notlar

1. **İnternet gerekli**: AI modelleri canlı API'ler kullanır
2. **Rate limiting**: Çok sık sorgu yapmayın
3. **Fallback**: AI başarısız olursa klasik stratejiler devreye girer
4. **Test edin**: Gerçek para ile başlamadan önce test edin

## 📞 Destek

Sorun yaşarsanız:
1. `/debug` komutu çalıştırın
2. `/ai_test` ile AI servislerini test edin
3. Log dosyalarını kontrol edin
