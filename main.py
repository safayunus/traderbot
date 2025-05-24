#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Trading Bot - Ana Program
"""

import asyncio
import signal
import sys
from utils.logger import setup_logger, get_logger
from api.telegram_api import setup_telegram_bot
from api.binance_api import setup_binance_client, test_binance_connection
from data.state import initialize_state
from trading.executor import start_trading

logger = None

def signal_handler(signum, frame):
    """Temiz kapatma için sinyal handler"""
    global logger
    if logger:
        logger.info("🛑 Bot kapatılıyor...")
    
    sys.exit(0)

async def main():
    """Ana program fonksiyonu"""
    global logger
    
    try:
        print("🚀 Trading Bot Başlatılıyor...")
        
        # Logger'ı kur
        logger = setup_logger()
        logger.info("=" * 60)
        logger.info("🤖 TRADING BOT BAŞLATILIYOR")
        logger.info("=" * 60)
        
        # Sinyal handler
        signal.signal(signal.SIGINT, signal_handler)
        signal.signal(signal.SIGTERM, signal_handler)
        
        # Bot durumunu başlat
        logger.info("⚙️ Bot durumu başlatılıyor...")
        if not initialize_state():
            logger.error("❌ Bot durumu başlatılamadı!")
            return False
        
        # Binance bağlantısını test et
        logger.info("🔗 Binance bağlantısı test ediliyor...")
        if not setup_binance_client():
            logger.error("❌ Binance bağlantısı kurulamadı!")
            return False
        
        if not test_binance_connection():
            logger.error("❌ Binance API erişimi başarısız!")
            return False
        
        # Telegram bot'unu başlat
        logger.info("📱 Telegram bot'u başlatılıyor...")
        application = setup_telegram_bot()
        if not application:
            logger.error("❌ Telegram bot başlatılamadı!")
            return False
        
        logger.info("✅ Bot başarıyla başlatıldı!")
        logger.info("📱 Telegram'dan /start komutu ile test edebilirsiniz")
        
        # Telegram bot'unu çalıştır
        await application.run_polling(drop_pending_updates=True)
        
    except KeyboardInterrupt:
        logger.info("⏹️ Kullanıcı tarafından durduruldu")
        return True
        
    except Exception as e:
        if logger:
            logger.error(f"💥 Kritik hata: {e}")
        else:
            print(f"❌ Logger başlatılmadan hata: {e}")
        return False
    
    finally:
        if logger:
            logger.info("🏁 Bot kapatılıyor...")
        print("👋 Bot kapatıldı!")

if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        print("⏹️ Bot durduruldu")
    sys.exit(0)