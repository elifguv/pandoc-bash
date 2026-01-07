#!/bin/bash

# Paket yüklemelerini otomotaik olarak gerçekleştiren dosya

# Renkli çıktılar için tanımlamalar
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}--- Pandoc Dönüştürücü Kurulumu Başlatılıyor ---${NC}"

# Root yetkisi kontrolü
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}HATA: Lütfen bu scripti yönetici olarak çalıştırın!${NC}"
  echo "Komut: sudo ./install.sh"
  exit
fi

# Sistem güncelleme
echo "-> Sistem paket listesi güncelleniyor..."
apt-get update -y > /dev/null 2>&1

# Paketlerin Kurulumu
echo "-> Gerekli paketler kontrol ediliyor..."

PACKAGES="pandoc yad whiptail texlive-latex-base texlive-fonts-recommended texlive-extra-utils texlive-latex-extra git"

# Programlar yüklü değilse yükle
for pkg in $PACKAGES; do
    if dpkg -l | grep -q "^ii  $pkg"; then
        echo -e "[OK] $pkg zaten yüklü."
    else
        echo -e "${GREEN}[KURULUYOR] $pkg yükleniyor...${NC}"
        apt-get install -y $pkg
    fi
done

# İzinlerin Ayarlanması
echo "-> Dosya izinleri ayarlanıyor..."
chmod +x main.sh
chmod +x lib/functions.sh

echo -e "${GREEN}--- Kurulum Başarıyla Tamamlandı! ---${NC}"
echo "Programı başlatmak için: ./main.sh"
