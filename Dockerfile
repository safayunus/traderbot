# Python 3.9 slim image kullan
FROM python:3.9-slim

# Çalışma dizinini ayarla
WORKDIR /app

# Sistem paketlerini güncelle ve gerekli araçları yükle
RUN apt-get update && apt-get install -y \
    gcc \
    g++ \
    && rm -rf /var/lib/apt/lists/*

# Python requirements'ı kopyala ve yükle
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Uygulama dosyalarını kopyala
COPY . .

# __init__.py dosyalarını oluştur
RUN touch api/__init__.py
RUN touch trading/__init__.py
RUN touch data/__init__.py
RUN touch utils/__init__.py

# Port tanımla (gerekirse)
EXPOSE 8080

# Sağlık kontrolü
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8080/health')" || exit 1

# Uygulamayı başlat
CMD ["python", "-u", "main.py"]
