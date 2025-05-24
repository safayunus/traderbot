# 🔄 Bot Durdurma ve Yeniden Kurulum Rehberi

Bu rehber, trading botunuzu güvenli şekilde durdurup AI entegrasyonu ile yeniden nasıl kuracağınızı açıklar.

## 🛑 1. Botu Güvenli Şekilde Durdurma

### A) Telegram Üzerinden Durdurma (Önerilen)
```
/stop_bot
```
Bu komut trading döngüsünü güvenli şekilde durdurur.

### B) Manuel Durdurma
1. **Terminal/CMD'de bot çalışıyorsa:**
   - `Ctrl + C` tuşlarına basın
   - Bot güvenli şekilde kapanacak

2. **Arka planda çalışıyorsa:**
   ```bash
   # Windows
   tasklist | findstr python
   taskkill /PID [PID_NUMARASI] /F
   
   # Linux/Mac
   ps aux | grep python
   kill [PID_NUMARASI]
   ```

### C) Docker ile Çalışıyorsa
```bash
docker stop trading-bot
docker rm trading-bot
```

## 💾 2. Veri Yedekleme (Önemli!)

### A) Trading Verilerini Yedekle
```bash
# Bot klasöründe
mkdir backup_$(date +%Y%m%d_%H%M%S)
cp *.log backup_*/
cp bot_state.json backup_*/ 2>/dev/null || echo "State dosyası yok"
cp .env backup_*/
```

### B) Önemli Dosyaları Yedekle
```bash
cp config.ini backup_*/
cp -r data/ backup_*/ 2>/dev/null || echo "Data klasörü yok"
```

## 🔄 3. AI Entegrasyonu ile Yeniden Kurulum

### Yöntem 1: Otomatik Setup (Önerilen)

**1. AI dosyalarının varlığını kontrol edin:**
```bash
ls trading/pretrained_models.py
ls trading/ai_integration.py  
ls api/ai_telegram_commands.py
ls setup_ai.py
```

**2. Otomatik setup çalıştırın:**
```bash
python setup_ai.py
```

**3. Gerekli paketleri yükleyin:**
```bash
pip install -r requirements.txt
```

**4. Botu başlatın:**
```bash
python main.py
```

### Yöntem 2: Manuel Kurulum

**1. Gerekli paketleri yükleyin:**
```bash
pip install requests numpy scikit-learn joblib
```

**2. trading/executor.py dosyasını düzenleyin:**

Satır ~45'te şu değişikliği yapın:

**ESKI:**
```python
# Sinyalleri üret
signals = generate_signals(
    df, 
    strategy=bot_status["strategy"],
    last_action=bot_status["last_action"]
)
```

**YENİ:**
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

**3. api/telegram_api.py dosyasını düzenleyin:**

**Import ekleyin (dosyanın başına):**
```python
from api.ai_telegram_commands import (
    ai_enable_command, ai_disable_command, ai_status_command,
    ai_test_command, ai_analysis_command, ai_setup_command,
    ai_weights_command, ai_recommend_command
)
```

**Komut handlers ekleyin (setup_telegram_bot fonksiyonuna):**
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

**4. Botu başlatın:**
```bash
python main.py
```

## 🧪 4. AI Entegrasyonu Test

**1. Bot başladıktan sonra Telegram'da:**
```
/ai_test
```

**2. AI modellerini aktif edin:**
```
/ai_setup balanced
```

**3. Piyasa analizi test edin:**
```
/ai_analysis
```

**4. AI durumunu kontrol edin:**
```
/ai_status
```

## 🚀 5. Trading'i Yeniden Başlatma

**1. Bot ayarlarını kontrol edin:**
```
/status
```

**2. AI'ın aktif olduğunu doğrulayın:**
```
/ai_status
```

**3. Trading'i başlatın:**
```
/start_bot
```

## 🔧 6. Sorun Giderme

### Hata: "Module not found"
```bash
pip install requests numpy scikit-learn joblib python-telegram-bot binance-python
```

### Hata: "AI commands not found"
1. `api/ai_telegram_commands.py` dosyasının varlığını kontrol edin
2. `api/telegram_api.py`'a import'ları ekleyin
3. Botu yeniden başlatın

### Hata: "AI test failed"
1. İnternet bağlantınızı kontrol edin
2. Firewall ayarlarını kontrol edin
3. `/debug` komutu çalıştırın

### Bot başlamıyor
1. `.env` dosyasındaki API anahtarlarını kontrol edin
2. `config.ini` dosyasını kontrol edin
3. Log dosyalarını kontrol edin: `tail -f trading_bot.log`

## 📋 7. Kurulum Kontrol Listesi

- [ ] Bot güvenli şekilde durduruldu
- [ ] Veriler yedeklendi
- [ ] AI dosyaları mevcut
- [ ] Gerekli paketler yüklendi
- [ ] `trading/executor.py` güncellendi
- [ ] `api/telegram_api.py` güncellendi
- [ ] Bot başarıyla başlatıldı
- [ ] `/ai_test` başarılı
- [ ] `/ai_setup balanced` çalıştırıldı
- [ ] `/start_bot` ile trading başlatıldı

## 🎯 8. Yeni AI Özellikleri

### Kullanılabilir AI Komutları:
```
/ai_setup [mod]     # AI kurulumu (conservative/balanced/aggressive)
/ai_enable          # AI'ı aktif et
/ai_disable         # AI'ı deaktif et
/ai_status          # AI durumu
/ai_test            # AI modellerini test et
/ai_analysis        # Detaylı piyasa analizi
/ai_recommend       # Hızlı AI önerisi
/ai_weights x y z   # Manuel ağırlık ayarı
```

### AI Modları:
- **Conservative**: Güvenli, düşük risk
- **Balanced**: Dengeli risk/getiri (önerilen)
- **Aggressive**: Yüksek getiri odaklı

## ⚠️ Önemli Uyarılar

1. **Veri Yedekleme**: Mutlaka trading verilerinizi yedekleyin
2. **Test Edin**: Gerçek para ile başlamadan önce test edin
3. **İnternet**: AI modelleri internet bağlantısı gerektirir
4. **Fallback**: AI başarısız olursa klasik stratejiler devreye girer
5. **Monitoring**: İlk günlerde botu yakından takip edin

## 📞 Acil Durum

**Bot kontrolden çıkarsa:**
1. `/stop_bot` komutu gönderin
2. Terminal'de `Ctrl + C` yapın
3. Gerekirse process'i kill edin
4. Log dosyalarını kontrol edin

**AI sinyalleri çalışmıyorsa:**
1. `/ai_disable` ile AI'ı kapatın
2. Klasik mod ile devam edin
3. Sorun giderildikten sonra `/ai_enable` yapın

Bu rehberi takip ederek botunuzu güvenli şekilde AI entegrasyonu ile yeniden kurabilirsiniz! 🚀
