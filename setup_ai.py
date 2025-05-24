#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
AI Entegrasyon Setup Scripti
Bu script AI modellerini otomatik olarak entegre eder
"""

import os
import sys
import shutil
from datetime import datetime

def backup_file(file_path):
    """Dosyayı yedekle"""
    if os.path.exists(file_path):
        backup_path = f"{file_path}.backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        shutil.copy2(file_path, backup_path)
        print(f"✅ Yedek oluşturuldu: {backup_path}")
        return backup_path
    return None

def update_executor():
    """trading/executor.py dosyasını güncelle"""
    file_path = "trading/executor.py"
    
    if not os.path.exists(file_path):
        print(f"❌ {file_path} bulunamadı!")
        return False
    
    # Yedek oluştur
    backup_file(file_path)
    
    # Dosyayı oku
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Değişiklik yapılacak kısmı bul
    old_code = '''            # Sinyalleri üret
            signals = generate_signals(
                df, 
                strategy=bot_status["strategy"],
                last_action=bot_status["last_action"]
            )'''
    
    new_code = '''            # AI Enhanced sinyalleri üret
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
                )'''
    
    if old_code in content:
        content = content.replace(old_code, new_code)
        
        # Dosyayı yaz
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        
        print(f"✅ {file_path} güncellendi!")
        return True
    else:
        print(f"⚠️ {file_path} zaten güncellenmiş veya kod bulunamadı")
        return False

def update_telegram_api():
    """api/telegram_api.py dosyasını güncelle"""
    file_path = "api/telegram_api.py"
    
    if not os.path.exists(file_path):
        print(f"❌ {file_path} bulunamadı!")
        return False
    
    # Yedek oluştur
    backup_file(file_path)
    
    # Dosyayı oku
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Import ekle
    import_line = "from data.state import get_state, get_config, update_state"
    new_import = """from data.state import get_state, get_config, update_state
from api.ai_telegram_commands import (
    ai_enable_command, ai_disable_command, ai_status_command,
    ai_test_command, ai_analysis_command, ai_setup_command,
    ai_weights_command, ai_recommend_command
)"""
    
    if import_line in content and "ai_enable_command" not in content:
        content = content.replace(import_line, new_import)
        print("✅ AI imports eklendi")
    
    # AI komutlarını ekle
    stats_handler = 'application.add_handler(CommandHandler("stats", stats_command))'
    ai_handlers = '''application.add_handler(CommandHandler("stats", stats_command))
        
        # AI komutları
        application.add_handler(CommandHandler("ai_enable", ai_enable_command))
        application.add_handler(CommandHandler("ai_disable", ai_disable_command))
        application.add_handler(CommandHandler("ai_status", ai_status_command))
        application.add_handler(CommandHandler("ai_test", ai_test_command))
        application.add_handler(CommandHandler("ai_analysis", ai_analysis_command))
        application.add_handler(CommandHandler("ai_setup", ai_setup_command))
        application.add_handler(CommandHandler("ai_weights", ai_weights_command))
        application.add_handler(CommandHandler("ai_recommend", ai_recommend_command))'''
    
    if stats_handler in content and "ai_enable" not in content:
        content = content.replace(stats_handler, ai_handlers)
        print("✅ AI komut handlers eklendi")
    
    # Help metnini güncelle
    old_help = '''🧪 Analiz:
- /backtest [gün] - Backtest çalıştır
- /compare [gün] - Stratejileri karşılaştır
- /optimize - Parametre optimizasyonu
- /stats - İstatistikler

💡 Örnekler:
/set_stoploss 1.5
/backtest 30
/compare 15"""'''
    
    new_help = '''🧪 Analiz:
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
/ai_analysis"""'''
    
    if old_help in content:
        content = content.replace(old_help, new_help)
        print("✅ Help metni güncellendi")
    
    # Dosyayı yaz
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ {file_path} güncellendi!")
    return True

def update_requirements():
    """requirements.txt dosyasını güncelle"""
    file_path = "requirements.txt"
    
    new_requirements = [
        "requests>=2.28.0",
        "numpy>=1.21.0", 
        "scikit-learn>=1.0.0",
        "joblib>=1.1.0"
    ]
    
    if os.path.exists(file_path):
        # Mevcut requirements'ı oku
        with open(file_path, 'r', encoding='utf-8') as f:
            existing = f.read()
        
        # Yeni requirements'ları ekle
        for req in new_requirements:
            package_name = req.split('>=')[0]
            if package_name not in existing:
                existing += f"\n{req}"
        
        # Dosyayı yaz
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(existing)
        
        print(f"✅ {file_path} güncellendi!")
    else:
        # Yeni dosya oluştur
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(new_requirements))
        
        print(f"✅ {file_path} oluşturuldu!")

def update_env_file():
    """Opsiyonel .env güncellemesi"""
    file_path = ".env"
    
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # LunarCrush API key yoksa ekle
        if "LUNARCRUSH_API_KEY" not in content:
            content += "\n\n# Opsiyonel AI API Anahtarları\nLUNARCRUSH_API_KEY=your_lunarcrush_key_here\n"
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            print(f"✅ {file_path} güncellendi (opsiyonel API key eklendi)")

def install_requirements():
    """Gerekli paketleri yükle"""
    try:
        import subprocess
        
        print("📦 Gerekli paketler yükleniyor...")
        
        packages = ["requests", "numpy", "scikit-learn", "joblib"]
        
        for package in packages:
            try:
                __import__(package)
                print(f"✅ {package} zaten yüklü")
            except ImportError:
                print(f"📦 {package} yükleniyor...")
                subprocess.check_call([sys.executable, "-m", "pip", "install", package])
                print(f"✅ {package} yüklendi")
        
        print("✅ Tüm paketler hazır!")
        
    except Exception as e:
        print(f"⚠️ Paket yükleme hatası: {e}")
        print("Manuel olarak yükleyin: pip install requests numpy scikit-learn joblib")

def verify_files():
    """Gerekli dosyaların varlığını kontrol et"""
    required_files = [
        "trading/pretrained_models.py",
        "trading/ai_integration.py", 
        "api/ai_telegram_commands.py"
    ]
    
    missing_files = []
    
    for file_path in required_files:
        if not os.path.exists(file_path):
            missing_files.append(file_path)
    
    if missing_files:
        print("❌ Eksik dosyalar:")
        for file_path in missing_files:
            print(f"   - {file_path}")
        return False
    
    print("✅ Tüm AI dosyaları mevcut!")
    return True

def main():
    """Ana setup fonksiyonu"""
    print("🤖 AI Model Entegrasyon Setup'ı Başlatılıyor...")
    print("=" * 50)
    
    # Dosya kontrolü
    if not verify_files():
        print("\n❌ Setup durduruluyor. Eksik dosyaları kontrol edin.")
        return
    
    # Entegrasyon adımları
    steps = [
        ("Trading Executor Güncelleme", update_executor),
        ("Telegram API Güncelleme", update_telegram_api),
        ("Requirements Güncelleme", update_requirements),
        ("Env Dosyası Güncelleme", update_env_file),
        ("Paket Yükleme", install_requirements)
    ]
    
    success_count = 0
    
    for step_name, step_func in steps:
        print(f"\n🔄 {step_name}...")
        try:
            if step_func():
                success_count += 1
            else:
                print(f"⚠️ {step_name} atlandı")
        except Exception as e:
            print(f"❌ {step_name} hatası: {e}")
    
    print("\n" + "=" * 50)
    print(f"🎉 Setup tamamlandı! {success_count}/{len(steps)} adım başarılı")
    
    print("\n🚀 Sonraki Adımlar:")
    print("1. Botu yeniden başlatın: python main.py")
    print("2. AI'ı test edin: /ai_test")
    print("3. AI'ı aktif edin: /ai_setup balanced")
    print("4. Trading'i başlatın: /start_bot")
    
    print("\n📚 Detaylı kullanım için: entegrasyon_rehberi.md")

if __name__ == "__main__":
    main()
