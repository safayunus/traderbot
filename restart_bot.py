#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Bot Yeniden Başlatma Scripti
Botu güvenli şekilde durdurur ve AI entegrasyonu ile yeniden başlatır
"""

import os
import sys
import time
import signal
import subprocess
import psutil
from datetime import datetime

def find_bot_processes():
    """Bot process'lerini bul"""
    bot_processes = []
    
    for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
        try:
            cmdline = ' '.join(proc.info['cmdline']) if proc.info['cmdline'] else ''
            if 'main.py' in cmdline or 'trading' in cmdline.lower():
                bot_processes.append(proc)
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue
    
    return bot_processes

def stop_bot_processes():
    """Bot process'lerini durdur"""
    print("🛑 Bot process'leri durduruluyor...")
    
    processes = find_bot_processes()
    
    if not processes:
        print("✅ Çalışan bot process'i bulunamadı")
        return True
    
    for proc in processes:
        try:
            print(f"🔄 Process durduruluyor: PID {proc.pid}")
            proc.terminate()
            
            # 5 saniye bekle
            proc.wait(timeout=5)
            print(f"✅ Process durduruldu: PID {proc.pid}")
            
        except psutil.TimeoutExpired:
            print(f"⚠️ Process zorla kapatılıyor: PID {proc.pid}")
            proc.kill()
        except Exception as e:
            print(f"❌ Process durdurma hatası: {e}")
    
    # Son kontrol
    time.sleep(2)
    remaining = find_bot_processes()
    
    if remaining:
        print(f"⚠️ {len(remaining)} process hala çalışıyor")
        return False
    else:
        print("✅ Tüm bot process'leri durduruldu")
        return True

def backup_data():
    """Önemli verileri yedekle"""
    print("💾 Veriler yedekleniyor...")
    
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup_dir = f"backup_{timestamp}"
    
    try:
        os.makedirs(backup_dir, exist_ok=True)
        
        # Yedeklenecek dosyalar
        files_to_backup = [
            "trading_bot.log",
            "bot_state.json", 
            ".env",
            "config.ini"
        ]
        
        for file_path in files_to_backup:
            if os.path.exists(file_path):
                import shutil
                shutil.copy2(file_path, backup_dir)
                print(f"✅ Yedeklendi: {file_path}")
        
        print(f"✅ Yedekleme tamamlandı: {backup_dir}")
        return backup_dir
        
    except Exception as e:
        print(f"❌ Yedekleme hatası: {e}")
        return None

def check_ai_files():
    """AI dosyalarının varlığını kontrol et"""
    print("🔍 AI dosyaları kontrol ediliyor...")
    
    required_files = [
        "trading/pretrained_models.py",
        "trading/ai_integration.py",
        "api/ai_telegram_commands.py",
        "setup_ai.py"
    ]
    
    missing_files = []
    
    for file_path in required_files:
        if os.path.exists(file_path):
            print(f"✅ {file_path}")
        else:
            print(f"❌ {file_path}")
            missing_files.append(file_path)
    
    if missing_files:
        print(f"\n❌ {len(missing_files)} AI dosyası eksik!")
        print("AI entegrasyonu yapılamayacak.")
        return False
    
    print("✅ Tüm AI dosyaları mevcut!")
    return True

def install_requirements():
    """Gerekli paketleri yükle"""
    print("📦 Gerekli paketler kontrol ediliyor...")
    
    required_packages = [
        "requests", "numpy", "scikit-learn", "joblib",
        "python-telegram-bot", "binance-python", "pandas"
    ]
    
    missing_packages = []
    
    for package in required_packages:
        try:
            __import__(package.replace('-', '_'))
            print(f"✅ {package}")
        except ImportError:
            print(f"❌ {package}")
            missing_packages.append(package)
    
    if missing_packages:
        print(f"\n📦 {len(missing_packages)} paket yükleniyor...")
        
        for package in missing_packages:
            try:
                subprocess.check_call([
                    sys.executable, "-m", "pip", "install", package
                ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                print(f"✅ {package} yüklendi")
            except subprocess.CalledProcessError:
                print(f"❌ {package} yüklenemedi")
                return False
    
    print("✅ Tüm paketler hazır!")
    return True

def run_ai_setup():
    """AI setup'ını çalıştır"""
    print("🤖 AI entegrasyonu yapılıyor...")
    
    if not os.path.exists("setup_ai.py"):
        print("❌ setup_ai.py bulunamadı!")
        return False
    
    try:
        result = subprocess.run([
            sys.executable, "setup_ai.py"
        ], capture_output=True, text=True, timeout=60)
        
        if result.returncode == 0:
            print("✅ AI entegrasyonu tamamlandı!")
            return True
        else:
            print(f"❌ AI entegrasyonu hatası: {result.stderr}")
            return False
            
    except subprocess.TimeoutExpired:
        print("❌ AI entegrasyonu zaman aşımı!")
        return False
    except Exception as e:
        print(f"❌ AI entegrasyonu hatası: {e}")
        return False

def start_bot():
    """Botu başlat"""
    print("🚀 Bot başlatılıyor...")
    
    if not os.path.exists("main.py"):
        print("❌ main.py bulunamadı!")
        return False
    
    try:
        # Bot'u arka planda başlat
        if os.name == 'nt':  # Windows
            subprocess.Popen([
                sys.executable, "main.py"
            ], creationflags=subprocess.CREATE_NEW_CONSOLE)
        else:  # Linux/Mac
            subprocess.Popen([
                sys.executable, "main.py"
            ], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        
        print("✅ Bot başlatıldı!")
        print("📱 Telegram'dan /ai_test komutu ile test edin")
        return True
        
    except Exception as e:
        print(f"❌ Bot başlatma hatası: {e}")
        return False

def main():
    """Ana fonksiyon"""
    print("🔄 BOT YENİDEN BAŞLATMA SİSTEMİ")
    print("=" * 50)
    
    # Adım 1: Bot'u durdur
    if not stop_bot_processes():
        print("❌ Bot durdurulamadı! Manuel olarak durdurun.")
        return
    
    # Adım 2: Veri yedekle
    backup_dir = backup_data()
    
    # Adım 3: AI dosyalarını kontrol et
    if not check_ai_files():
        print("\n❌ AI dosyaları eksik! Önce AI dosyalarını ekleyin.")
        return
    
    # Adım 4: Paketleri yükle
    if not install_requirements():
        print("\n❌ Paket yükleme başarısız!")
        return
    
    # Adım 5: AI entegrasyonu
    if not run_ai_setup():
        print("\n⚠️ AI entegrasyonu başarısız! Manuel kurulum gerekebilir.")
        print("📚 Detaylar için: entegrasyon_rehberi.md")
    
    # Adım 6: Bot'u başlat
    if start_bot():
        print("\n🎉 YENİDEN BAŞLATMA TAMAMLANDI!")
        print("\n📱 Sonraki adımlar:")
        print("1. /ai_test - AI modellerini test edin")
        print("2. /ai_setup balanced - AI'ı aktif edin")
        print("3. /start_bot - Trading'i başlatın")
        
        if backup_dir:
            print(f"\n💾 Yedek klasörü: {backup_dir}")
    else:
        print("\n❌ Bot başlatılamadı!")
        print("📚 Sorun giderme için: bot_yeniden_kurulum.md")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⏹️ İşlem kullanıcı tarafından durduruldu")
    except Exception as e:
        print(f"\n❌ Beklenmeyen hata: {e}")
